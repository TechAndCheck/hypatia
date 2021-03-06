class FacebookUserBlueprint < Blueprinter::Base
  identifier :id

  fields  :profile_link,
          :name,
          :id,
          :profile,
          :number_of_followers,
          :number_of_likes,
          :verified,
          :profile_image_file,
          :profile_image_url

  field :profile_image_file do |user|
    unless user.profile_image_file.nil?
      file = File.open(user.profile_image_file).read
      Base64.encode64(file)
    end
  end
end
