require "test_helper"

class FacebookMediaSourceTest < ActiveSupport::TestCase
  def setup; end

  test "can send error via slack notification" do
    assert_nothing_raised do
      FacebookMediaSource.send_message_to_slack("Test message for Facebook Media Source")
    end
  end

  test "can send error is there is an error while scraping" do
    assert_raise(MediaSource::HostError) do
      FacebookMediaSource.extract(Scrape.create({ url: "https://www.example.com" }))
    end
  end

  test "can extract post without an error being posted to Slack" do
    assert_nothing_raised do
      post = FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/photo/?fbid=10161587852468065&set=a.10150148489178065" }))
      assert_not_nil(post)
    end
  end

  test "extracted post has images and videos uploaded to S3" do
    skip unless ENV["AWS_REGION"].present?

    posts = FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/photo/?fbid=10161587852468065&set=a.10150148489178065" }))
    assert_not_nil(posts)

    posts.each { |post| assert_not_nil(post.aws_image_keys) }

    posts = FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/PlandemicMovie/videos/588866298398729/" }))
    assert_not_nil(posts)

    posts.each { |post| assert_not_nil(post.aws_video_key) }
    posts.each { |post| assert_not_nil(post.aws_video_preview_key) }
    posts.each { |post| assert_not_nil(post.aws_screenshot_key) }

    json_posts = JSON.parse(PostBlueprint.render(posts))
    json_posts.each { |post| assert_nil post["post"]["video_file"] }
    json_posts.each { |post| assert_nil post["post"]["video_file_preview"] }
    json_posts.each { |post| assert_nil post["post"]["screenshot_file"] }
  end

  test "extracted post has images and videos are not uploaded to S3 if AWS_REGION isn't set" do
    modify_environment_variable("AWS_REGION", nil) do
      posts = FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/photo/?fbid=10161587852468065&set=a.10150148489178065" }))
      assert_not_nil(posts)

      posts.each { |post| assert_nil(post.aws_image_keys) }

      posts = FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/PlandemicMovie/videos/588866298398729/" }))
      assert_not_nil(posts)

      posts.each { |post| assert_nil(post.aws_video_key) }
      posts.each { |post| assert_nil(post.aws_video_preview_key) }
      posts.each { |post| assert_nil(post.aws_screenshot_key) }


      json_posts = JSON.parse(PostBlueprint.render(posts))
      json_posts.each { |post| assert_nil post["post"]["video_file_key"] }
      json_posts.each { |post| assert_nil post["post"]["video_file_preview_key"] }
      json_posts.each { |post| assert_nil post["post"]["screenshot_file"] }
    end
  end
end
