require "aws-sdk-s3"

# Wraps Amazon S3 object actions.
class AwsObjectUploadFileWrapper
  attr_reader :object

  # @param object [Aws::S3::Object] An existing Amazon S3 object.
  def initialize(file_path)
    bucket_name = Figaro.env.AWS_S3_BUCKET_NAME
    object_key = object_key_for_file_path(file_path)
    @file_path = file_path

    @object = Aws::S3::Object.new(bucket_name, object_key)
  end

  # Uploads a file to an Amazon S3 object by using a managed uploader.
  #
  # @param file_path [String] The path to the file to upload.
  # @return [Boolean] True when the file is uploaded; otherwise false.
  def upload_file
    @object.upload_file(@file_path)
    true
  rescue Aws::Errors::ServiceError => e
    puts "Couldn't upload file #{@file_path} to #{@object.key}. Here's why: #{e.message}"
    false
  end

private

  def object_key_for_file_path(file_path)
    object_key = File.basename(file_path) if Figaro.env.AWS_S3_PATH.blank?
    object_key = File.join(Figaro.env.AWS_S3_PATH, File.basename(file_path)) if object_key.nil?
    object_key
  end
end
