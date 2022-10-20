require "prawn"
require "json"
require "date"
require "prawn/table"

require_relative "page_fragment"

time = Time.new

ATTRIBUTES = {
  name: "Tony Lin",
  certificate: "Carpentry Level One",
  completion_date: "2022-10-10",
  type: "ar_batch_report",
  report_id: "34512",

  assessment_center: {
    organization_name: "Triangle Rescue Standby Services LLC",
    organization_id: "98373",
    organization_address: "3875 I-10 East, Orange, TX 77630 US",
  },

  assessment_site: {
    organization_name: "Triangle Rescue Standby Services LLC",
    organization_id: "98373",
    organization_address: "3875 I-10 East, Orange, TX 77630 US",
  },

  info: {
    direct: "Yes",
    date_printed: time.strftime("%m/%d/%Y"),
    card_number: "Result ID: ",
    name: "Tony Lin",

    entries: {
      entry1: {
        date_scored: "10/10/2022",
        certificate_type: "Certificate",
        certificate_name: "Scaffold Builder V3",
        credential_type: "Knowledge Verified",
        wallet_card: "Blue Card",
      },

      entry2: {
        date_scored: "10/10/2022",
        certificate_type: "Certificate",
        certificate_name: "Scaffold Builder V3",
        credential_type: "Knowledge Verified",
        wallet_card: "Blue Card",
      },
    },
  },
}

case ATTRIBUTES[:type]
when "certified"
  file = File.read("certificate_template.json")
when "ar_batch_report"
  file = File.read("ar_template.json")
end

DATA_HASH = JSON.parse(file)
COLOR = DATA_HASH["template"]["color"]
BACKGROUND = DATA_HASH["template"]["background_color"]

puts ATTRIBUTES[:info][:entries].count

#json object
#into Ruby Hash

class Renderer
  attr_accessor :page_fragments

  def initialize(options = {})
    @options = options
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

      color = fragment.color? ? fragment.color : COLOR
      alignment = BACKGROUND.nil? ? "center" : "left"

      content.each do |c|
        pdf.text c, :leading => 0, width: fragment.width, align: alignment.to_sym, :color => color, style: fragment.style
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
      set_bg_color(pdf)
      self.page_fragments.each do |fragment|
        render_fragment(pdf, fragment)
      end
    end
  end

  def set_bg_color(pdf)
    if !BACKGROUND.nil?
      pdf.bounding_box([pdf.bounds.left - 50, pdf.bounds.top + 50], width: 900, height: 700) do
        pdf.fill_color BACKGROUND
        pdf.fill { pdf.rectangle [pdf.bounds.left, pdf.bounds.top], pdf.bounds.right, pdf.bounds.top }
      end
    end
  end

  def filename
    "test.pdf"
  end
end

def render_batch_report(renderer)
  fragment = PageFragment.new x: 0, y: 540, width: 720, height: 540, name: "page"
  fragment.font = DATA_HASH["template"]["font-family"]
  fragment.font_size = DATA_HASH["template"]["font-size"].to_i
  fragment.content = DATA_HASH["template"]["title"]
  renderer.add_fragment fragment
  spacing = 0
  y = fragment.width / 2

  DATA_HASH["sections"].each_key do |attr|
    fragment = PageFragment.new
    fragment.font = DATA_HASH["defaults"]["font-family"]
    fragment.y = y + DATA_HASH["defaults"]["height_spacing"].to_i
    fragment.width = DATA_HASH["defaults"]["width"].to_i
    fragment.height = DATA_HASH["defaults"]["height"].to_i
    spacing = DATA_HASH["sections"][attr]["line-spacing".to_s].to_i

    case attr
    when "report_id"
      fragment.font_size = DATA_HASH["sections"][attr]["font-size"].to_i
      fragment.content = DATA_HASH["sections"][attr]["report_id"]
      fragment.content << ATTRIBUTES[:report_id]
      y -= spacing #space every each section

    when "assessment_center", "assessment_site"
      DATA_HASH["sections"][attr].each do |key, value|
  
        fragment.font_size = DATA_HASH["sections"][attr]["font-size"].to_i
        if value.match /\{\{(.*)\}\}/ #ex grabs {{name}}
          attribute = value.tr("{}", "")  #removes {{}} = > name
          fragment.content << ATTRIBUTES[attr.to_sym][attribute.to_sym] << "\n" #this works
        elsif key == "organization_name" || key == "organization_id"
          fragment.content << DATA_HASH["sections"][attr.to_s][key.to_s]
          fragment.content << ATTRIBUTES[attr.to_sym][key.to_sym] << "\n"
        end
      end
      y -= spacing

    when "info"
      DATA_HASH["sections"][attr].each do |key, value|
        fragment.font_size = DATA_HASH["sections"][attr]["font-size"].to_i
        case key
        when "direct"
          fragment.content << DATA_HASH["sections"][attr.to_s][key.to_s]
          fragment.content << ATTRIBUTES[attr.to_sym][key.to_sym] << "\n"

        when "date_printed"
          fragment.content << DATA_HASH["sections"][attr.to_s][key.to_s]
          fragment.content << ATTRIBUTES[attr.to_sym][key.to_sym] << "\n"
        end

      end
    end
    renderer.add_fragment fragment
  end
end

def render_certificate(renderer)
  fragment = PageFragment.new x: 0, y: 540, width: 720, height: 540, name: "page"
  fragment.image_file = "images/certificate-of-merit.jpg"
  renderer.add_fragment fragment

  DATA_HASH["sections"].each_key do |attr|
    fragment = PageFragment.new
    fragment.font = DATA_HASH["defaults"]["font-family"]
    DATA_HASH["sections"][attr].each do |key, value|
      #puts "new #{key}  #{value}"
      if key == "font-size"
        fragment.font_size = value.to_i
      elsif key == "location"
        coordinates = value.split(" ")
        fragment.x = coordinates[0].to_i
        fragment.y = coordinates[1].to_i
        fragment.width = coordinates[2].to_i
        fragment.height = coordinates[3].to_i
      elsif key == "text"
        if value.match /\{\{(.*)\}\}/ #ex grabs {{name}}
          attribute = value.tr("{}", "")  #removes {{}} = > name
          attribute = attribute.to_sym
          fragment.content = ATTRIBUTES[attribute] #this works
        else
          fragment.content = value
        end
      elsif key == "image"
        fragment.image_file = "images/signature.png"
      elsif key == "style"
        fragment.style = value.to_sym
      end
    end
    renderer.add_fragment fragment
  end
end

renderer = Renderer.new
case ATTRIBUTES[:type]
when "certified"
  render_certificate(renderer)
when "ar_batch_report"
  render_batch_report(renderer)
else
  puts "Error No Template"
end
renderer.render
