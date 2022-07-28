class FacebookPostBlueprint < Blueprinter::Base
  identifier :id

  fields  :url,
          :text,
          :created_at,
          :num_comments,
          :num_views,
          :num_shares,
          :reactions,
          :id

  association :user, blueprint: FacebookUserBlueprint

  field :image_file do |post|
    if post.image_file.nil? == false && post.aws_image_keys.blank?
      file = File.open(post.image_file).read
      Base64.encode64(file)
    end
  end

  field :video_file do |post|
    if post.video_file.nil? == false && post.aws_video_key.blank?
      file = File.open(post.video_file).read
      Base64.encode64(file)
    end
  end

  field :video_preview_image_file do |post|
    if post.video_preview_image_file.nil? == false && post.aws_video_preview_key.blank?
      file = File.open(post.video_preview_image_file).read
      Base64.encode64(file)
    end
  end

  field :screenshot_file do |post|
    if post.aws_video_preview_key.blank?
      file = File.open(post.screenshot_file).read
      Base64.encode64(file)
    end
  end

  field :aws_video_key do |post|
    post.aws_video_key()
  end

  field :aws_video_preview_key do |post|
    post.aws_video_preview_key()
  end


  field :aws_image_keys do |post|
    post.aws_image_keys()
  end
end
