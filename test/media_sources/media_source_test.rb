require "test_helper"

class MediaSourceTest < ActiveSupport::TestCase
  def setup; end

  test "test urls return valid media sources" do
    url = "https://web.facebook.com/shalikarukshan.senadheera/posts/pfbid0287di3uHqt6s8ARUcuY7fNyyP86xEsvg7yjmn9v4eG1QLMrikwAPKvNoDy4Pynjtjl?_rdc=1&_rdr"
    assert_equal FacebookMediaSource, MediaSource.model_for_url(url)

    url = "https://www.facebook.com/camnewsday/posts/pfbid0DwJTGtqdquwx1s9jkWvn99kJFNGp6PJYeiLZnoZN7zLxGaVhJKFxSKMjSFt8efBUl"
    assert_equal FacebookMediaSource, MediaSource.model_for_url(url)

    url = "https://www.facebook.com/100080150081712/posts/209445141737154/?_rdc=2&_rdr"
    assert_equal FacebookMediaSource, MediaSource.model_for_url(url)

    url = "https://mobile.twitter.com/MichelCaballero/status/1637639770347040769"
    assert_equal TwitterMediaSource, MediaSource.model_for_url(url)

    url = "https://www.tiktok.com/@guess/video/7091753416032128299"
    assert_equal TikTokMediaSource, MediaSource.model_for_url(url)
  end

  test "HostError has everything properly" do
    error = MediaSource::HostError.new("https://www.example.com")
    assert_equal({ code: 10, error: "No valid scraper found for the url https://www.example.com" }, error.to_response_structure)
  end
end
