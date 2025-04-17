module Jekyll
  class DestinationPaginationGenerator < Generator
    safe true

    def generate(site)
      return unless site.collections['destinations']
      
      # Group posts by destination
      site.posts.docs.group_by { |post| post.data['category'] }.each do |destination_name, posts|
        # Find matching destination document
        destination_doc = site.collections['destinations'].docs.find { |doc| 
          doc.data['title'].downcase == destination_name.downcase 
        }
        
        next unless destination_doc
        
        posts_per_page = 1
        total_pages = (posts.length.to_f / posts_per_page).ceil

        (1..total_pages).each do |page_num|
          # Create paginated pages
          site.pages << DestinationPage.new(site, destination_doc, posts, page_num, total_pages)
        end
      end
    end
  end

  class DestinationPage < Page
    def initialize(site, destination_doc, posts, page_num, total_pages)
      @site = site
      @base = site.source
      
      destination_path = destination_doc.data['title'].downcase
      
      if page_num == 1
        @dir = destination_path
      else
        @dir = "#{destination_path}/page/#{page_num}"
      end
      
      @name = 'index.html'
      
      self.process(@name)
      self.read_yaml(File.join(@base, '_layouts'), 'category.html')
      
      # Copy destination document data
      self.data.merge!(destination_doc.data)
      self.data['current_page'] = page_num
      self.data['total_pages'] = total_pages
      self.data['posts'] = posts
    end
  end
end
