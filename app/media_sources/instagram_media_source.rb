class InstagramMediaSource < MediaSource
  attr_reader(:url)

  # A string to indicate what type of scraper this model is for
  #
  # @return [String] the canonical name for the type this scraper handles
  def self.model_type
    "instagram"
  end

  # Limit all urls to the host below
  #
  # @return [String] or [Array] of [String] of valid host names
  def self.valid_host_name
    ["www.instagram.com", "instagram.com"]
  end

  # Capture a screenshot of the given url
  #
  # @!scope class
  # @params url [String] the url of the page to be collected for archiving
  # @params save_screenshot [Boolean] whether to save the screenshot image (mostly for testing).
  #   Default: false
  # @returns [String or nil] the path of the screenshot if the screenshot was saved
  def self.extract(scrape, save_screenshot = false)
    object = self.new(scrape.url)
    object.retrieve_instagram_post
  rescue StandardError => error
    error_message = "*Zorki Error 📸:*\n`#{error.class.name}`\n> #{error.message}\n*URL Submitted:* #{scrape.url}"
    self.send_message_to_slack(error_message)
    raise
  end

  # Initialize the object and capture the screenshot automatically.
  #
  # @params url [String] the url of the page to be collected for archiving
  # @returns [Sting or nil] the path of the screenshot if the screenshot was saved
  def initialize(url)
    # Verify that the url has the proper host for this source. (@valid_host is set at the top of
    # this class)
    InstagramMediaSource.check_url(url)
    InstagramMediaSource.validate_instagram_post_url(url)

    @url = url
  end

  # Scrape the page using the Zorki gem and get an object
  #
  # @!visibility private
  # @params url [String] a url to grab data for
  # @return [Zorki::Post]
  def retrieve_instagram_post
    id = InstagramMediaSource.extract_instagram_id_from_url(@url)
    posts = Zorki::Post.lookup(id)
    self.class.create_aws_key_functions_for_posts(posts)

    return posts unless s3_transfer_enabled?

    posts.map do |post|
      @@logger.debug "Beginning uploading of files to S3 bucket #{Figaro.env.AWS_S3_BUCKET_NAME}"

      # Upload post screenshot to s3
      if post.screenshot_file.present?
        @@logger.debug "Uploading post screenshot #{post.screenshot_file}"
        aws_upload_wrapper = AwsObjectUploadFileWrapper.new(post.screenshot_file)
        aws_upload_wrapper.upload_file
        post.instance_variable_set("@aws_screenshot_key", aws_upload_wrapper.object.key)
      end

      # Let's see if it's a video or images, and upload them
      if post.image_file_names.present?
        aws_image_keys = post.image_file_names.map do |image_file_name|
          @@logger.debug "Uploading image #{image_file_name}"
          aws_upload_wrapper = AwsObjectUploadFileWrapper.new(image_file_name)
          aws_upload_wrapper.upload_file
          aws_upload_wrapper.object.key
        end
        post.instance_variable_set("@aws_image_keys", aws_image_keys)
      elsif post.video_file_name.present?
        @@logger.debug "Uploading video #{post.video_file_name}"
        aws_upload_wrapper = AwsObjectUploadFileWrapper.new(post.video_file_name)
        aws_upload_wrapper.upload_file
        post.instance_variable_set("@aws_video_key", aws_upload_wrapper.object.key)

        @@logger.debug "Uploading video preview #{post.video_preview_image}"
        aws_upload_wrapper = AwsObjectUploadFileWrapper.new(post.video_preview_image)
        aws_upload_wrapper.upload_file
        post.instance_variable_set("@aws_video_preview_key", aws_upload_wrapper.object.key)
      end

      post
    end
  end

  def self.can_handle_url?(url)
    InstagramMediaSource.send(:validate_instagram_post_url, url)
  rescue InstagramMediaSource::InvalidInstagramPostUrlError
    false
  end

private

  # Validate that the url is a direct link to a post, poorly
  #
  # @note this assumes a valid url or else it'll always (usually, maybe, whatever) fail
  #
  # @!scope class
  # @!visibility private
  # @params url [String] a url to check if it's a valid Instagram post url
  # @return [Boolean] if the string validates or not
  def self.validate_instagram_post_url(url)
    return true if /instagram.com\/((p)|(reel)|(tv))\/[\w]+/.match?(url)
    raise InvalidInstagramPostUrlError, "Instagram url #{url} does not have the standard url format"
  end

  # Grab the ID from the end of an Instagram URL
  #
  # @note this assumes a valid url or else it'll return weird stuff
  # @!scope class
  # @!visibility private
  # @params url [String] a url to extract an id from
  # @return [String] the id from the url or [Nil]
  def self.extract_instagram_id_from_url(url)
    uri = URI(url)
    splits = uri.path.split("/")
    raise InstagramMediaSource::InvalidInstagramPostUrlError if splits.empty?
    splits[2]
  end
end

# A class to indicate that a post url passed in is invalid
class InstagramMediaSource::InvalidInstagramPostUrlError < StandardError; end
