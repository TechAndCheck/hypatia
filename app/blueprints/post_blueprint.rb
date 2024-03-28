class PostBlueprint < Blueprinter::Base
  identifier :id
  fields :id

  field :post do |post|
    to_return = nil

    case post.class.to_s # This is converted to a string because apparently comparing classes breaks
    when "Forki::Post"
      to_return = FacebookPostBlueprint.render_as_hash(post)
    when "Zorki::Post"
      to_return = InstagramPostBlueprint.render_as_hash(post)
    when "YoutubeArchiver::Video"
      to_return = YoutubeVideoBlueprint.render_as_hash(post)
    when "Mosquito::Tweet"
      to_return = TwitterPostBlueprint.render_as_hash(post)
    when "Morris::Post"
      to_return = TikTokPostBlueprint.render_as_hash(post)
    else
      raise "Unsupported class for a post passed into PostBlueprint"
    end

    to_return
  end
end
