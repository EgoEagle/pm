require "prawn"
require "json"
require "date"

require_relative "page_fragment"


time = Time.new


attributes = {
  name: "Tony Lin",
  certificate: "Carpentry Level One",
  completion_date: "2022-10-10",
  type: "knowledge_verified",
  report_id: "927670",
  
  assessment_center: {
    organization_name: "Triangle Rescue Standby Services LLC",
    organization_id: "23272",
    organization_address:"3875 I-10 East, Orange, TX 77630 US"
  },

  assessment_site: {
    organization_name: "Triangle Rescue Standby Services LLC",
    organization_id: "23272",
    organization_address:"3875 I-10 East, Orange, TX 77630 US"
  },

  info: {
    direct: true,
    date_printed: time.strftime("%m/%d/%Y"),
    card_number: "Result ID: ",
    name: "Tony Lin",

    entries: {
      entry1: {
        date_scored: "10/10/2022",
        certificate_type: "Certificate",
        certificate_name: "Scaffold Builder V3",
        credential_type: "Knowledge Verified",
        wallet_card: "Blue Card"
      },

      entry2: {
        date_scored: "10/10/2022",
        certificate_type: "Certificate",
        certificate_name: "Scaffold Builder V3",
        credential_type: "Knowledge Verified",
        wallet_card: "Blue Card"
      }
    }
  }
}



case attributes[:type]
when "certified"
  file = File.read("certificate_template.json")

when "knowledge_verified"
  file = File.read("ar_template.json")

end


#json object
data_hash = JSON.parse(file)
#into Ruby Hash


class Renderer
  attr_reader :page_fragments
  COLOR_WHITE = "FFFFFF"

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

      color = fragment.color? ? fragment.color : COLOR_WHITE

      content.each do |c|
        pdf.text c, width: fragment.width, align: :center, :color => color, style: fragment.style , background_color: "FF0000"
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

case attributes[:type]
when "certified"
  fragment = PageFragment.new x: 0, y: 540, width: 720, height: 540, name: "page"
  fragment.image_file = "images/certificate-of-merit.jpg"
  renderer.add_fragment fragment

  data_hash["sections"].each_key do |attr|
    fragment = PageFragment.new
    fragment.font = "Times-Roman"
    data_hash["sections"][attr].each do |key, value|
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
          fragment.content = attributes[attribute] #this works
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

when "knowledge_verified"
  fragment = PageFragment.new x: 0, y: 540, width: 720, height: 540, name: "page"
  fragment.background_color = "FF0000"
  fragment.content = "BA"
  renderer.add_fragment fragment
  
end


renderer.render
