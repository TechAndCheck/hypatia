class TikTokUserBlueprint < Blueprinter::Base
  identifier :username

  fields  :name,
          :username,
          :number_of_posts,
          :number_of_followers,
          :number_of_following,
          :verified,
          :profile,
          :profile_link,
          :profile_image,
          :profile_image_url

  # No I don't know why I can't just use the accessor. Oh well, this fixes it
  field :aws_profile_image_key do |user|
    user.aws_profile_image_key
  end

  field :profile_image do |user|
    to_return = nil
    if user[:profile_image].nil? == false && user.aws_profile_image_key.blank?
      File.open(user[:profile_image]) { |file| to_return = Base64.encode64(file.read) }
    end

    to_return
  end

end
