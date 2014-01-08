require 'mini_magick'

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
        specs.each do |name, spec|
          if spec.has_key? :dimensions then

            # Reloads image for each run, less efficient than haivng this outside of the spec.each block
            # but changing format remvoes the original temp file
            image = ::MiniMagick::Image.open(File.join(source_dir, origin))

            original_ext = File.extname(File.join(source_dir, origin))

            if original_ext == '.pdf'
              image.depth('8')
              image.alpha('off')
              image.format("png", 0)
            end
            image.combine_options do |i|
              i.resize spec[:dimensions]
              i.gravity "center"
              i.crop "#{spec[:dimensions]}+0+0"
            end
            image.write File.join(output_dir, spec[:name])
          end
        end
      end

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
