class YoutubeVideoBlueprint < Blueprinter::Base
  identifier :id

  fields  :title,
          :created_at,
          :language,
          :duration,
          :num_views,
          :num_likes,
          :num_comments,
          :live,
          :made_for_kids

  association :channel, blueprint: YoutubeChannelBlueprint

  field :video_preview_image_file do |video|
    unless video.video_preview_image_file.nil?
      file = File.open(video.video_preview_image_file).read
      Base64.encode64(file)
    end
  end

  field :video_file do |video|
    if video.video_file.nil? == false && video.aws_video_key.blank?
      file = File.open(video.video_file).read
      Base64.encode64(file)
    end
  end

  field :video_preview_image do |video|
    to_return = nil
    if video.video_preview_image_file.nil? == false && video.aws_video_preview_key.blank?
      file = File.open(video.video_preview_image_file).read
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

  field :aws_video_key do |video|
    video.aws_video_key()
  end

  field :aws_video_preview_key do |video|
    video.aws_video_preview_key()
  end
end
