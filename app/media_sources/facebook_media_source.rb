# typed: true
class FacebookMediaSource < MediaSource
  include Forki
  attr_reader(:url)

  # Limit all urls to the host below
  #
  # @return [String] or [Array] of [String] of valid host names
  def self.valid_host_name
    ["www.facebook.com"]
  end

  # Capture a screenshot of the given url
  #
  # @!scope class
  # @params url [String] the url of the page to be collected for archiving
  # @params save_screenshot [Boolean] whether to save the screenshot image (mostly for testing).
  #   Default: false
  # @returns [String or nil] the path of the screenshot if the screenshot was saved
  def self.extract(scrape, save_screenshot = false)
    self.validate_facebook_post_url(scrape.url)
    object = self.new(scrape.url)
    object.retrieve_facebook_post
  end

  # Validate that the url is a direct link to a post, poorly
  #
  # @note this assumes a valid url or else it'll always (usually, maybe, whatever) fail
  #
  # @!scope class
  # @!visibility private
  # @params url [String] a url to check if it's a valid Facebook post url
  # @return [Boolean] if the string validates or not
  def self.validate_facebook_post_url(url)
    return true if /facebook.com\//.match?(url)
    raise InvalidFacebookPostUrlError, "Facebook url #{url} does not have the standard url format"
  end

  # Initialize the object and capture the screenshot automatically.
  #
  # @params url [String] the url of the page to be collected for archiving
  # @returns [Sting or nil] the path of the screenshot if the screenshot was saved
  def initialize(url)
    # Verify that the url has the proper host for this source. (@valid_host is set at the top of
    # this class)
    FacebookMediaSource.check_url(url)
    @url = url
  end

  # Scrape the page using the Forki gem and get an object
  #
  # @!visibility private
  # @params url [String] a url to grab data for
  # @return [Forki::Post]
  def retrieve_facebook_post
    # Unlike Zorki, Forki expects a full URL
    Forki::Post.lookup(url)
  end
end

# A class to indicate that a post url passed in is invalid
class FacebookMediaSource::InvalidFacebookPostUrlError < StandardError; end
class FacebookMediaSource::ExternalServerError < StandardError; end