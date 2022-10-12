class PageFragment
     attr_accessor :x, :y, :width, :height, :name
     attr_accessor :content, :font, :font_size, :color
     attr_accessor :image_file

     def initialize(options = {})
          self.x = options[:x] || 0
          self.y = options[:y] || 0
          self.width = options[:width] || 0
          self.height = options[:height] || 0
          self.name = options[:name] || ""
          self.content = options[:content] || ""
          self.image_file = options[:image_file] || ""
          self.font = options[:font] || ""
          self.font_size = options[:font_size] || 0
          self.color = options[:color]
        end

        
        def origin
          [self.x, self.y]
        end
      
        def size
          [self.width, self.height]
        end
      
        def name?
          !self.name.empty?
        end
      
        def content?
          !self.content.empty?
        end
      
        def image_file?
          !self.image_file.empty?
        end
      
        def font?
          !self.font.empty?
        end
      
        def font_size?
          self.font_size > 0
        end
      
        def color?
          !self.color.nil?
        end
      end       