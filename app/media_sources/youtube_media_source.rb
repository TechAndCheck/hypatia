# typed: true
class YoutubeMediaSource < MediaSource
  include YoutubeArchiver
  attr_reader(:url)

  # A string to indicate what type of scraper this model is for
  #
  # @return [String] the canonical name for the type this scraper handles
  def self.model_type
    "youtube"
  end

  # Limit all urls to the host below
  #
  # @return [String] or [Array] of [String] of valid host names
  def self.valid_host_name
    ["www.youtube.com", "youtube.com"]
  end

  # Capture a screenshot of the given url
  #
  # @!scope class
  # @params url [String] the url of the page to be collected for archiving
  # @params save_screenshot [Boolean] whether to save the screenshot image (mostly for testing).
  #   Default: false
  # @returns [String or nil] the path of the screenshot if the screenshot was saved
  def self.extract(scrape, save_screenshot = false)
    self.validate_youtube_video_url(scrape.url)
    object = self.new(scrape.url)
    object.retrieve_youtube_video
  end

  # Validate that the url is a direct link to a post, poorly
  #
  # @note this assumes a valid url or else it'll always (usually, maybe, whatever) fail
  #
  # @!scope class
  # @!visibility private
  # @params url [String] a url to check if it's a valid Youtube post url
  # @return [Boolean] if the string validates or not
  def self.validate_youtube_video_url(url)
    return true if /youtube.com\//.match?(url)
    raise InvalidYoutubeVideoUrlError, "Youtube url #{url} does not have the standard url format"
  end

  # Initialize the object and capture the screenshot automatically.
  #
  # @params url [String] the url of the page to be collected for archiving
  # @returns [Sting or nil] the path of the screenshot if the screenshot was saved
  def initialize(url)
    # Verify that the url has the proper host for this source. (@valid_host is set at the top of
    # this class)
    YoutubeMediaSource.check_url(url)
    @url = url
  end

  def self.extract_youtube_id_from_url(url)
    # regex adapted from https://gist.github.com/rodrigoborgesdeoliveira/987683cfbfcc8d800192da1e73adc486
    youtube_id_regex = /(?:http:|https:)*?\/\/(?:www\.|)(?:youtube\.com|m\.youtube\.com|youtu\.|youtube-nocookie\.com).*(?:v=|v%3D|v\/|(?:a|p)\/(?:a|u)\/\d.*\/|watch\?|vi(?:=|\/)|\/embed\/|oembed\?|be\/|e\/|shorts\/)([^&?%#\/\n]*)/m
    raise YoutubeMediaSource::InvalidYoutubeVideoUrlError unless youtube_id_regex =~ url
    $1
  end


  # Scrape the page using the YoutubeArchiver gem and get an object
  #
  # @!visibility private
  # @params id [String] the id of the video to grab
  # @return [YoutubeArchiver::Video]
  def retrieve_youtube_video
    id = YoutubeMediaSource.extract_youtube_id_from_url(@url)
    posts = YoutubeArchiver::Video.lookup(id)

    self.class.create_aws_key_functions_for_posts(posts)

    return posts if Figaro.env.AWS_REGION.blank?

    posts.map do |post|
      Rails.logger.debug "Beginning uploading of files to S3 bucket #{Figaro.env.AWS_S3_BUCKET_NAME}"
      Rails.logger.debug "\n********************\n"

      # Let's see if it's a video or images, and upload them
      if post.video_file.blank? == false
        Rails.logger.debug "\nUploading video #{post.video_file}\n"
        object = AwsObjectUploadFileWrapper.new(post.video_file)
        object.upload_file
        post.instance_variable_set("@aws_video_key", object.object.key)
      end

      post
    end
  end

  def self.can_handle_url?(url)
    YoutubeMediaSource.send(:validate_youtube_video_url, url)
  rescue YoutubeMediaSource::InvalidYoutubeVideoUrlError
    false
  end
end

# A class to indicate that a post url passed in is invalid
class YoutubeMediaSource::InvalidYoutubeVideoUrlError < StandardError; end
class YoutubeMediaSource::ExternalServerError < StandardError; end
