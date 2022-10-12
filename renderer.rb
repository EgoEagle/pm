require "prawn"
require "json"
require 'date'

require_relative "page_fragment"
#json object
file = File.read("template.json")
data_hash = JSON.parse(file)
#into Ruby Hash

attributes = {
  name: "Tony Lin",
  certificate: "Carpentry Level One",
  completion_date: "2022-10-10"
}

class Renderer
  attr_reader :page_fragments
  COLOR_WHITE = "FFFFFF"

  def initialize(options = {}) 
    @options = options
    #@data_hash = data_hash
    #@collection = collection
    @page_fragments = Array.new
    @draw_boxes = false
  end

  def add_fragment(fragment)
    self.page_fragments << fragment
  end

  def render_fragment(pdf, fragment)
    render_content(pdf, fragment) if fragment.content?
    render_image(pdf, fragment) if fragment.image_file?
  end

  def render_image(pdf, fragment)
    pdf.image fragment.image_file,
      at: fragment.origin,
      fit: fragment.size
  end

  def render_content(pdf, fragment)
    original_font = pdf.font
    original_size = pdf.font_size

    if fragment.font?
      pdf.font fragment.font
    end

    if fragment.font_size?
      pdf.font_size fragment.font_size
    end

    pdf.bounding_box fragment.origin, width: fragment.width, height: fragment.height do
      pdf.stroke_bounds if draw_boxes?

      if fragment.content.class == String
        content = [fragment.content]
      elsif fragment.content.class == Array
        content = fragment.content
      else
        raise "Unsupported content type #{fragment.content.class}"
      end

      color = fragment.color? ? fragment.color : COLOR_WHITE

      content.each do |c|
        pdf.text c, width: fragment.width, align: :center, color: color
      end
    end

    pdf.font original_font.name
    pdf.font_size = original_size
  end

  def draw_boxes?
    @draw_boxes
  end

  def render
    Prawn::Document.generate(filename, page_layout: :landscape) do |pdf|
      # pdf.stroke_axis
      self.page_fragments.each do |fragment|
        render_fragment(pdf, fragment)
      end
    end
  end

  def filename
    "test.pdf"
  end
end



puts 

renderer = Renderer.new

fragment = PageFragment.new x: 0, y: 540, width: 720, height: 540, name: "page"
fragment.image_file = "images/certificate-of-merit.jpg"
renderer.add_fragment fragment


data_hash["sections"].each_key do |attr|
  fragment = PageFragment.new
  fragment.font = "Times-Roman"
    data_hash["sections"][attr].each do |key,value|
      #puts "new #{key}  #{value}"

      if value.match /\{+\w\}+/
        puts value
        #fragment.content = Date.today.to_s

      elsif value=="{{name}}"
        fragment.content = "Sample Name1"

      elsif key == "font-size"
        fragment.font_size = value.to_i

      elsif key == "location"
        value = value.split(" ")
        fragment.x = value[0].to_i
        fragment.y = value[1].to_i
        fragment.width = value[2].to_i
        fragment.height = value[3].to_i
      
      elsif key == "text"
        fragment.content = value

      elsif key =="image"
        fragment.image_file = "images/signature.png"
      end
    
    end
  renderer.add_fragment fragment
end

renderer.render
