# frozen_string_literal: true

require "fileutils"

module Jekyll
  module ResponsiveImages
    class << self
      # Cache for image dimensions: path => [width, height]
      def dimensions_cache
        @dimensions_cache ||= {}
      end

      # Find ImageMagick CLI command
      def magick_cmd
        @magick_cmd ||= begin
          if system("which magick > /dev/null 2>&1")
            "magick"
          elsif system("which convert > /dev/null 2>&1")
            "convert"
          else
            nil
          end
        end
      end

      def identify_cmd
        @identify_cmd ||= begin
          if system("which identify > /dev/null 2>&1")
            "identify"
          elsif magick_cmd
            "#{magick_cmd} identify"
          else
            nil
          end
        end
      end

      # Get height for a 665px wide image
      def get_image_height(file_path)
        return nil unless File.exist?(file_path)

        dimensions_cache[file_path] ||= begin
          if identify_cmd
            output = `#{identify_cmd} -format "%w %h" "#{file_path}" 2>/dev/null`.strip.split
            output.length == 2 ? output[1].to_i : nil
          else
            nil
          end
        end
      end

      # Generate 320, 480, and 665 WebP versions if any are missing
      def ensure_variants(site_source, dir, base, orig_candidate = nil)
        return unless magick_cmd

        dest_dir = File.join(site_source, dir)
        v320 = File.join(dest_dir, "#{base}-320.webp")
        v480 = File.join(dest_dir, "#{base}-480.webp")
        v665 = File.join(dest_dir, "#{base}-665.webp")

        return if File.exist?(v320) && File.exist?(v480) && File.exist?(v665)

        # Look for source image if not specified
        source_img = orig_candidate
        unless source_img && File.exist?(source_img)
          candidates = [
            File.join(dest_dir, "#{base}.jpg"),
            File.join(dest_dir, "#{base}.jpeg"),
            File.join(dest_dir, "#{base}.png"),
            File.join(dest_dir, "#{base}.webp"),
            v665 # If 665 exists, we can downscale from it
          ]
          source_img = candidates.find { |path| File.exist?(path) }
        end

        return unless source_img && File.exist?(source_img)

        FileUtils.mkdir_p(dest_dir)

        unless File.exist?(v320)
          system(magick_cmd, source_img, "-resize", "320x", "-quality", "80", "-strip", v320)
        end
        unless File.exist?(v480)
          system(magick_cmd, source_img, "-resize", "480x", "-quality", "80", "-strip", v480)
        end
        unless File.exist?(v665)
          system(magick_cmd, source_img, "-resize", "665x", "-quality", "80", "-strip", v665)
        end
      end

      # Process an individual <img> tag string and replace with responsive tag
      def make_responsive(img_tag, site_source)
        # Skip if already has srcset
        return img_tag if img_tag.match?(/\bsrcset\s*=/i)

        src_match = img_tag.match(/\bsrc\s*=\s*["']([^"']+)["']/i)
        return img_tag unless src_match

        src = src_match[1]
        clean_src = src.split("?").first.split("#").first
        rel_path = clean_src.sub(%r{^/}, "")

        # Only process content images inside assets/img/
        return img_tag unless rel_path.start_with?("assets/img/")

        dir = File.dirname(rel_path)
        filename = File.basename(rel_path)

        # Extract base name without size suffix (-320, -480, -665) or extension
        base = filename
          .sub(/-(?:320|480|665)(?=\.[^.]+$)/, "")
          .sub(/\.[^.]+$/, "")

        # Ensure responsive variants exist
        ensure_variants(site_source, dir, base, File.join(site_source, rel_path))

        v665_full = File.join(site_source, dir, "#{base}-665.webp")
        height = get_image_height(v665_full)

        # Extract existing attributes
        alt_match = img_tag.match(/\balt\s*=\s*(["'])(.*?)\1/i)
        alt_text = alt_match ? alt_match[2] : ""

        class_match = img_tag.match(/\bclass\s*=\s*(["'])(.*?)\1/i)
        class_attr = class_match ? " class=\"#{class_match[2]}\"" : ""

        web_dir = "/#{dir}"
        height_attr = height ? " height=\"#{height}\"" : ""

        %(<img src="#{web_dir}/#{base}-665.webp" srcset="#{web_dir}/#{base}-320.webp 320w, #{web_dir}/#{base}-480.webp 480w, #{web_dir}/#{base}-665.webp 665w" sizes="(max-width: 665px) 100vw, 665px" alt="#{alt_text}" width="665"#{height_attr}#{class_attr} loading="lazy" />)
      end
    end
  end
end

# Hook into Jekyll post_render for documents (posts, collections, pages)
Jekyll::Hooks.register [:documents, :pages], :post_render do |doc|
  next unless doc.output&.include?("<img")

  doc.output = doc.output.gsub(/<img\b(?![^>]*\bsrcset=)[^>]*?>/i) do |match|
    Jekyll::ResponsiveImages.make_responsive(match, doc.site.source)
  end
end
