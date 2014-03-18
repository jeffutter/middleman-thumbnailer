require 'fileutils'
require 'mini_magick'
require 'pry'

module Middleman
  #actually creates the thumbnail names
  class ThumbnailGenerator
    class << self

      def specs(origin, dimensions)
        ret = {original: {name: origin}}

        dirname = File.dirname(origin)
        orig_ext = File.extname(origin)
        basename = File.basename(origin, orig_ext)
        ext = orig_ext == '.pdf' ? '.png' : orig_ext

        dimensions.each do |name, dimension|
          ret[name] = {name: "#{dirname}/#{basename}-#{name}-#{dimension}#{ext}", dimensions: dimension}
        end

        ret
      end

      def generate(source_dir, output_dir, origin, specs)
        origin_absolute = File.join(source_dir, origin)
        yield_images(origin_absolute, specs) do |img, spec|
          output_file = File.join(output_dir, spec[:name])
          origin_mtime = File.mtime origin_absolute
          #FIXME: this sucks & I should be shot, however in before_build, we havend created the build dir
          # therefor we will have to create it here
          output_file_immediate_dir = File.dirname output_file
          FileUtils.mkdir_p output_file_immediate_dir unless Dir.exist? output_file_immediate_dir
          if !File.exist?(output_file) || origin_mtime != File.mtime(output_file) then
            #puts "writing #{output_file}"
            img.write output_file 
          end
          File.utime(origin_mtime, origin_mtime, output_file)
       end
      end

      def yield_images(origin, specs)
        # image = ::Magick::Image.read(origin).first
        specs.each do |name, spec|
          if spec.has_key? :dimensions then
            # Reloads image for each run, less efficient than haivng this outside of the spec.each block
            # but changing format remvoes the original temp file
            image = ::MiniMagick::Image.open(origin)

            # image.change_geometry(spec[:dimensions]) do |cols, rows, img|
            #   img = img.resize(cols, rows)
            #   img = img.sharpen(0.5, 0.5)
            #   yield img, spec
            original_ext = File.extname(origin)

            if original_ext == '.pdf'
              image.depth('8')
              image.alpha('off')
              image.format("png", 0)
            end
            image.combine_options do |i|

              dimensions = /(\d+)\D+(\d+)/.match(spec[:dimensions])
              orig_y = image[:height].to_f
              orig_x = image[:width].to_f
              orig_aspect_ratio = orig_x/orig_y

              if dimensions and dimensions.length == 3
                y = dimensions[1].to_f
                x = dimensions[2].to_f
                aspect_ratio = x/y
              else
                aspect_ratio = orig_aspect_ratio
              end

              if aspect_ratio != orig_aspect_ratio
                i.resize "#{spec[:dimensions]}^"
                i.gravity "center"
                i.extent spec[:dimensions]
              else
                i.resize spec[:dimensions]
              end
             # i.crop "#{spec[:dimensions]}+0+0"
            end
            yield image, spec
          end
        end
      end

      def image_for_spec(origin, spec)
        image = ::MiniMagick::Image.open(origin)

        if spec.has_key? :dimensions then
          original_ext = File.extname(origin)

          if original_ext == '.pdf'
            image.depth('8')
            image.alpha('off')
            image.format("png", 0)
          end
          image.combine_options do |i|

            dimensions = /(\d+)\D+(\d+)/.match(spec[:dimensions])
            orig_y = image[:height].to_f
            orig_x = image[:width].to_f
            orig_aspect_ratio = orig_x/orig_y

            if dimensions and dimensions.length == 3
              y = dimensions[1].to_f
              x = dimensions[2].to_f
              aspect_ratio = x/y
            else
              aspect_ratio = orig_aspect_ratio
            end

            if aspect_ratio != orig_aspect_ratio
              i.resize "#{spec[:dimensions]}^"
              i.gravity "center"
              i.extent spec[:dimensions]
            else
              i.resize spec[:dimensions]
            end
          end
        end
        return image
      end


      #This returns a reverse mapping from a thumbnail's filename to the original filename, and the thumbnail's specs
      def original_map_for_files(files, specs)
        map = files.inject({}) do |memo, file|
          generated_specs = self.specs(file, specs)
          generated_specs.each do |name, spec|
            memo[spec[:name]] = {:original => generated_specs[:original][:name], :spec => spec}
          end
          memo
        end
      end
    end
  end
end
