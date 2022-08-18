require "test_helper"

class InstagramMediaSourceTest < ActiveSupport::TestCase
  def setup; end

  @@instagram_video_posts = InstagramMediaSource.extract(Scrape.create({ url: "https://www.instagram.com/p/Cd0Uhc0hKPB/" }))
  @@instagram_image_posts = InstagramMediaSource.extract(Scrape.create({ url: "https://www.instagram.com/p/CZu6b08OB0Q/" }))

  test "can send error via slack notification" do
    assert_nothing_raised do
      InstagramMediaSource.send_message_to_slack("Test message for Instagram Media Source")
    end
  end

  test "can send error is there is an error while scraping" do
    assert_raise(MediaSource::HostError) do
      InstagramMediaSource.extract(Scrape.create({ url: "https://www.example.com" }))
    end
  end

  test "can extract post without an error being posted to Slack" do
    assert_nothing_raised do
      assert_not_nil(@@instagram_image_posts.first)
    end
  end

  test "extracted video has screenshot" do
    @@instagram_video_posts.each { |post| assert_not_nil(post.screenshot_file) }
  end

  test "extracted image has screenshot" do
    @@instagram_image_posts.each { |post| assert_not_nil(post.screenshot_file) }
  end

  test "extracted post has images and videos uploaded to S3" do
    skip unless ENV["AWS_REGION"].present?

    assert_not_nil(@@instagram_image_posts)

    @@instagram_image_posts.each { |post| assert_not_nil(post.aws_image_keys) }

    assert_not_nil(@@instagram_video_posts)

    @@instagram_video_posts.each { |post| assert_not_nil(post.aws_video_key) }
    @@instagram_video_posts.each { |post| assert_not_nil(post.aws_video_preview_key) }
    @@instagram_video_posts.each { |post| assert_not_nil(post.aws_screenshot_key) }

    json_posts = JSON.parse(PostBlueprint.render(@@instagram_video_posts))
    json_posts.each { |post| assert_nil post["post"]["image_files"] }
    json_posts.each { |post| assert_nil post["post"]["video_file"] }
    json_posts.each { |post| assert_nil post["post"]["video_file_preview"] }
    json_posts.each { |post| assert_nil post["post"]["screenshot_file"] }
  end

  test "extracted post has images and videos are not uploaded to S3 if AWS_REGION isn't set" do
    modify_environment_variable("AWS_REGION", nil) do
      posts = InstagramMediaSource.extract(Scrape.create({ url: "https://www.instagram.com/p/CZu6b08OB0Q/" }))
      assert_not_nil(posts)

      posts.each { |post| assert_nil(post.aws_image_keys) }

      posts = InstagramMediaSource.extract(Scrape.create({ url: "https://www.instagram.com/p/Cd0Uhc0hKPB/" }))
      assert_not_nil(posts)

      posts.each { |post| assert_nil(post.aws_image_keys) }
      posts.each { |post| assert_nil(post.aws_video_key) }
      posts.each { |post| assert_nil(post.aws_video_preview_key) }
      posts.each { |post| assert_nil(post.aws_screenshot_key) }

      json_posts = JSON.parse(PostBlueprint.render(posts))
      json_posts.each { |post| assert_nil post["post"]["aws_image_keys"] }
      json_posts.each { |post| assert_nil post["post"]["aws_video_key"] }
      json_posts.each { |post| assert_nil post["post"]["aws_video_preview_key"] }
      json_posts.each { |post| assert_nil post["post"]["aws_screenshot_key"] }
    end
  end
end
