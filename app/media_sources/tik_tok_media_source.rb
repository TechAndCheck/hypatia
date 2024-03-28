require "capybara/dsl"
# typed: true

class TikTokMediaSource < MediaSource
  include Capybara::DSL
  include Morris
  attr_reader(:url)

  # A string to indicate what type of scraper this model is for
  #
  # @return [String] the canonical name for the type this scraper handles
  def self.model_type
    "tiktok"
  end

  # Limit all urls to the host below
  #
  # @return [String] or [Array] of [String] of valid host names
  def self.valid_host_name
    ["www.tiktok.com", "tiktok.com"]
  end

  # Capture a screenshot of the given url
  #
  # @!scope class
  # @params url [String] the url of the page to be collected for archiving
  # @params save_screenshot [Boolean] whether to save the screenshot image (mostly for testing).
  #   Default: false
  # @returns [String or nil] the path of the screenshot if the screenshot was saved
  def self.extract(scrape, save_screenshot = false)
    self.validate_tiktok_video_url(scrape.url)
    object = self.new(scrape.url)
    object.retrieve_tiktok_video
  rescue Morris::AccountNotFoundError => e
    message = "TikTok account #{scrape.url} is unavailable"
    @@logger.error message
    self.send_message_to_slack(message)
    raise e
  rescue Morris::ContentUnavailableError => e
    message = "TikTok video #{scrape.url} is unavailable"
    @@logger.error message
    self.send_message_to_slack(message)
    raise e
  end

  # Validate that the url is a direct link to a post, poorly
  #
  # @note this assumes a valid url or else it'll always (usually, maybe, whatever) fail
  #
  # @!scope class
  # @!visibility private
  # @params url [String] a url to check if it's a valid TikTok post url
  # @return [Boolean] if the string validates or not
  def self.validate_tiktok_video_url(url)
    self.valid_host_name.each do |host_name|
      return true if /#{host_name}\//.match?(url)
    end
    raise InvalidTikTokVideoUrlError, "TikTok url #{url} does not have the standard url format"
  end

  # Initialize the object and capture the screenshot automatically.
  #
  # @params url [String] the url of the page to be collected for archiving
  # @returns [Sting or nil] the path of the screenshot if the screenshot was saved
  def initialize(url)
    # Verify that the url has the proper host for this source. (@valid_host is set at the top of
    # this class)
    TikTokMediaSource.check_url(url)
    @url = url
  end

  def self.extract_tiktok_id_from_url(url)
    # regex adapted from https://gist.github.com/rodrigoborgesdeoliveira/987683cfbfcc8d800192da1e73adc486
    tiktok_id_regex = /(?:http:|https:)*?\/\/(?:www\.|)(?:tiktok\.com)\/[\W]+[\w]+\/video\/([0-9]+)/
    raise TikTokMediaSource::InvalidTikTokVideoUrlError unless tiktok_id_regex =~ url
    $1
  end


  # Scrape the page using the Morris gem and get an object
  #
  # @!visibility private
  # @params id [String] the id of the video to grab
  # @return [Morris::Video]
  def retrieve_tiktok_video
    id = TikTokMediaSource.extract_tiktok_id_from_url(@url)
    posts = Morris::Post.lookup(@url)

    self.class.create_aws_key_functions_for_posts(posts)

    return posts unless s3_transfer_enabled?

    # Upload post media to s3
    posts.map do |post|
      @@logger.debug "Beginning uploading of files to S3 bucket #{Figaro.env.AWS_S3_BUCKET_NAME}"

      # Upload channel profile picture to s3
      if post.user[:profile_image].present?
        @@logger.debug "Uploading channel image #{post.user[:profile_image]}"
        aws_upload_wrapper = AwsObjectUploadFileWrapper.new(post.user[:profile_image])
        aws_upload_wrapper.upload_file
        post.user.instance_variable_set("@aws_profile_image_key", aws_upload_wrapper.object.key)
      end

      if post.screenshot_file.present?
        @@logger.debug "Uploading post screenshot #{post.screenshot_file}"
        aws_upload_wrapper = AwsObjectUploadFileWrapper.new(post.screenshot_file)
        aws_upload_wrapper.upload_file
        post.instance_variable_set("@aws_screenshot_key", aws_upload_wrapper.object.key)
      end

      if post.video_file_name.present?
        @@logger.debug "Uploading video #{post.video_file_name}"
        aws_upload_wrapper = AwsObjectUploadFileWrapper.new(post.video_file_name)
        aws_upload_wrapper.upload_file
        post.instance_variable_set("@aws_video_key", aws_upload_wrapper.object.key)
      end

      if post.video_preview_image.present?
        @@logger.debug "Uploading video preview #{post.video_preview_image}"
        aws_upload_wrapper = AwsObjectUploadFileWrapper.new(post.video_preview_image)
        aws_upload_wrapper.upload_file
        post.instance_variable_set("@aws_video_preview_key", aws_upload_wrapper.object.key)
      end

      post
    end
  end

  def self.can_handle_url?(url)
    TikTokMediaSource.send(:validate_tiktok_video_url, url)
  rescue TikTokMediaSource::InvalidTikTokVideoUrlError
    false
  end
end

# A class to indicate that a post url passed in is invalid
class TikTokMediaSource::InvalidTikTokVideoUrlError < StandardError; end
class TikTokMediaSource::ExternalServerError < StandardError; end
