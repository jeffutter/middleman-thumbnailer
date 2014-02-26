require 'mini_magick'

require 'middleman-thumbnailer/thumbnail-generator'

Then(/^the image "(.*?)" should have width of "([0-9]*?)"$/) do |path, width|
  full_path = File.join(current_dir, path)
 # image = ::Magick::Image.read(full_path).first
  image = ::MiniMagick::Image.open(full_path)
  image.columns.should == width.to_i
end

Then(/^the image "(.*?)" should have height of "(.*?)"$/) do |path, height|
  full_path = File.join(current_dir, path)
  #image = ::Magick::Image.read(full_path).first
  image = ::MiniMagick::Image.open(full_path)
  image.rows.should == height.to_i
end

Then (/^I should be able to rebuild "(.*?)" and the thumbnails do not regenerate$/) do |path|
  image_path = File.join(current_dir, 'build', path)

  specs =  {
    :small => '200x',
    :medium => 'x300'
  }
  thumbnail_paths = ::Middleman::ThumbnailGenerator.specs(image_path, specs)
  thumbnail_path = File.join(Dir.pwd, thumbnail_paths[:small][:name])
  current_mtime = File.mtime(thumbnail_path)
  sleep 1
  step %Q{I run `middleman build`}
  new_mtime = File.mtime(thumbnail_path)
  new_mtime.should == current_mtime
end

Then (/^I should be able to update an image "(.*?)" and the thumbnails regenerate$/) do |path|
  source_path = File.join(current_dir, 'source', path)
  image_path = File.join(current_dir, 'build', path)
  specs =  {
    :small => '200x',
    :medium => 'x300'
  }
  thumbnail_paths = ::Middleman::ThumbnailGenerator.specs(image_path, specs)
  original_mtime = File.mtime(image_path)
  sleep 1
  updated_mtime = Time.now
  File.utime(updated_mtime, updated_mtime, source_path)
  step %Q{I run `middleman build`}
  thumbnail_path = File.join(Dir.pwd, thumbnail_paths[:small][:name])
  new_mtime = File.mtime(thumbnail_path)
  new_mtime.should == updated_mtime
end
