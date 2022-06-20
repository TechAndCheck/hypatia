class MediaSource
  include Slack

  @@logger = Logger.new(STDOUT)
  @@logger.level = Logger::DEBUG
  @@logger.datetime_format = "%Y-%m-%d %H:%M:%S"

  # Enqueue a job to scrape a URL depending on the site this is set for.
  #
  # @!scope class
  # @param url [String] the url to be scraped
  # @returns [ScrapeJob] the job fired off when this is run
  def self.scrape(url, callback_id = nil, callback_url = Figaro.env.ZENODOTUS_URL, force: false)
    # We want to fail early if the URL is wrong
    # debugger
    model = self.model_for_url(url)
    raise MediaSource::HostError.new(url) if model.nil?

    if Figaro.env.ALLOW_FORCE == "true" && force == "true"
      self.scrape!(url, callback_id, callback_url)
    else
      ScrapeJob.perform_later(url, callback_id, callback_url)
    end
  end

  # Scrape a URL depending on the site this is set for.
  #
  # @!scope class
  # @param url [String] the url to be scraped
  # @returns [Object] the scraped object returned from the respective gem.
  def self.scrape!(url, callback_id, callback_url)
    scrape = Scrape.create!({
      url: url,
      callback_url: callback_url,
      callback_id: callback_id,
    })

    model = self.model_for_url(url)
    object = model.extract(scrape)

    object
  end

  def self.create_aws_key_functions_for_posts(posts)
    posts.map do |post|
      # First, we add two functions to whatever class the result is.
      # These are implementation details, so we don't want to add them to Zorki or Forki
      # These will allow us to save the AWS keys for later
      post.instance_variable_set("@aws_image_keys", nil)
      post.instance_variable_set("@aws_video_key", nil)
      post.instance_variable_set("@aws_video_preview_key", nil)

      post.define_singleton_method(:aws_image_keys) do
        instance_variable_get("@aws_image_keys")
      end

      post.define_singleton_method(:aws_video_key) do
        instance_variable_get("@aws_video_key")
      end

      post.define_singleton_method(:aws_video_preview_key) do
        instance_variable_get("@aws_video_preview_key")
      end

      post
    end
  end

  # Check if +url+ has a host name the same as indicated by the +@@valid_host+ variable in a
  #   subclass.
  #
  # @!scope class
  # @param url [String] the url to be checked for validity
  # @return [Boolean] if the url is valid given the set @@valid_host.
  #   Raises an error if it's invalid.
  def self.check_url(url)
    return true if self.valid_host_name.include?(URI(url).host)
    raise MediaSource::HostError.new(url)
  end

  # A error to indicate the host of a given url does not pass validation
  class HostError < StandardError
    attr_reader :url

    def initialize(url)
      @url = url

      super("No valid scraper found for the url #{url}")
    end
  end

  def self.model_for_url(url)
    # Load all models so we can inspect them
    Zeitwerk::Loader.eager_load_all

    # Get all models conforming to ApplicationRecord, and then check if they implement the magic
    # function.
    models = MediaSource.descendants.select do |model|
      if model.respond_to? :can_handle_url?
        model.can_handle_url?(url)
      end
    end

    # We'll always choose the first one
    models.first
  end

  def s3_transfer_enabled?
    Figaro.env.AWS_REGION.present?
  end
end
