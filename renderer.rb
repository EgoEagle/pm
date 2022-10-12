require "prawn"
require "json"
require 'date'

require_relative "page_fragment"

file = File.read("template.json")
data_hash = JSON.parse(file)

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

renderer = Renderer.new

fragment = PageFragment.new x: 0, y: 540, width: 720, height: 540, name: "page"
fragment.image_file = "images/certificate-of-merit.jpg"
renderer.add_fragment fragment

fragment = PageFragment.new x: data_hash["sections"]["header1"]["location"][0], y: data_hash["sections"]["header1"]["location"][1], width: data_hash["sections"]["header1"]["location"][2], height: data_hash["sections"]["header1"]["location"][3], name: "head1", font_size: data_hash["sections"]["header1"]["font-size"].to_i
fragment.content = data_hash["sections"]["header1"]["text"]
renderer.add_fragment fragment

fragment = PageFragment.new x: data_hash["sections"]["header2"]["location"][0], y: data_hash["sections"]["header2"]["location"][1], width: data_hash["sections"]["header2"]["location"][2], height: data_hash["sections"]["header2"]["location"][3], name: "head2", font_size: data_hash["sections"]["header2"]["font-size"].to_i
fragment.content = data_hash["sections"]["header2"]["text"]
renderer.add_fragment fragment

fragment = PageFragment.new x: data_hash["sections"]["name"]["location"][0], y: data_hash["sections"]["name"]["location"][1], width: data_hash["sections"]["name"]["location"][2], height: data_hash["sections"]["name"]["location"][3], name: "head2", font_size: data_hash["sections"]["name"]["font-size"].to_i
fragment.content = "Tony Lin"
renderer.add_fragment fragment

fragment = PageFragment.new x: data_hash["sections"]["presented-date"]["location"][0], y: data_hash["sections"]["presented-date"]["location"][1], width:data_hash["sections"]["presented-date"]["location"][2], height:data_hash["sections"]["presented-date"]["location"][3] , font_size: 20
fragment.content = Date.today.to_s

renderer.add_fragment fragment

renderer.render
