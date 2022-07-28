class InstagramPostBlueprint < Blueprinter::Base
  identifier :id

  fields  :id,
          :text,
          :date,
          :number_of_likes

  association :user, blueprint: InstagramUserBlueprint

  field :object_type do |post|
    "instagram"
  end

  field :image_files do |post|
    to_return = nil
    if post.image_file_names.nil? == false && post.aws_image_keys.blank?
      to_return = post.image_file_names.map do |file_name|
        file = File.open(file_name).read
        Base64.encode64(file)
      end
    end

    to_return
  end

  field :video_file do |post|
    to_return = nil
    if post.video_file_name.nil? == false && post.aws_video_key.blank?
      file = File.open(post.video_file_name).read
      to_return = Base64.encode64(file)
    end

    to_return
  end

  field :video_preview_image do |post|
    to_return = nil
    if post.video_preview_image.nil? == false && post.aws_video_preview_key.blank?
      file = File.open(post.video_preview_image).read
      to_return = Base64.encode64(file)
    end

    to_return
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
