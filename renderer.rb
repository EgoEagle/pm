require "prawn"
require "json"
require "date"
require "prawn/table"

require_relative "page_fragment"

time = Time.new
$info
$table = false

#time.strftime("%m/%d/%Y"),
#json object
#into Ruby Hash

class Renderer
  attr_accessor :page_fragments , :template, :attributes

  def initialize(options = {},template,attributes)
    @template = template
    @attributes = attributes
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
      if $table
        generate_table(pdf, $info)
      end
      self.page_fragments.each do |fragment|
        render_fragment(pdf, fragment)
      end
    end
  end

  def generate_table(pdf, info)
    header_text = [[{ content: "Result Id: #{attributes["report_id"]}", colspan: 9 }]]
    Array displayArray = Array.new
    displayArray.push(["NCCER Card #", "Name", "Date Scored", "Certification Type", "Credential Type", "Certification Name", "Blue Card", "Silver Card", "Gold Card"])
    info.each_slice(9) do |a|
      displayArray.push(a)
    end

    pdf.bounding_box([0, 300], width: 720, height: 600) do
      pdf.table(header_text + displayArray, header: 2) do
        row(0).font_style = :bold
      end
    end
  end

  def set_bg_color(pdf)
    if !BACKGROUND.nil?
      pdf.canvas do
        pdf.fill_color BACKGROUND
        pdf.fill_rectangle [pdf.bounds.left, pdf.bounds.top], pdf.bounds.right, pdf.bounds.top
        pdf.fill_color "000000"
      end
    end
  end

  def filename
    "test.pdf"
  end

  def render_batch_report
    fragment = PageFragment.new x: 0, y: 540, width: 720, height: 540, name: "page"
    fragment.font = @template[:template][:font_family]
    fragment.font_size = @template[:template][:font_size].to_i
    fragment.content = @template[:template][:title]
    self.add_fragment fragment
    spacing = 0
    y = fragment.width / 2

    @template[:sections].each_key do |attr|
      fragment = PageFragment.new
      fragment.font = @template["defaults".to_sym]["font-family".to_sym]
      fragment.y = y + @template["defaults".to_sym]["height_spacing".to_sym].to_i
      fragment.width = @template["defaults".to_sym]["width".to_sym].to_i
      fragment.height = @template["defaults".to_sym]["height".to_sym].to_i
      spacing = @template["sections".to_sym][attr]["line-spacing".to_sym].to_i

      case attr
      when "report_id"
        fragment.font_size = @template["sections".to_sym][attr]["font-size".to_sym].to_i
        fragment.content = @template["sections".to_sym][attr]["report_id".to_sym]
        fragment.content << @attributes["report_id".to_sym]
        y -= spacing #space every each section
      when "assessment_center", "assessment_site"
        @template["sections"][attr].each do |key, value|
          fragment.font_size = @template["sections"][attr]["font-size"].to_i
          if value.match /\{\{(.*)\}\}/ #ex grabs {{name}}
            attribute = value.tr("{}", "")  #removes {{}} = > name
            fragment.content << @attributes[attr.to_s][attribute.to_s] << "\n" #this works
          elsif key == "organization_name" || key == "organization_id"
            fragment.content << @template["sections"][attr.to_s][key.to_s]
            fragment.content << @attributes[attr.to_s][key.to_sym] << "\n"
          end
        end
        y -= spacing
      when "info"
        $info = Array.new
        count = 0
        @attributes["info"]["entries"].each_key do |attr|
          @attributes["info"]["entries"][attr.to_s].each do |key, value|
            if count % 7 == 0
              $info.push(@attributes["info"]["cardnumber"], @attributes["info"]["name"])
            end
            $info.push(value)
            count += 1
          end
        end

        @template["sections"][attr].each do |key, value|
          fragment.font_size = @template["sections"][attr]["font-size"].to_i
          case key
          when "direct"
            fragment.content << @template["sections"][attr.to_s][key.to_s]
            fragment.content << @attributes[attr.to_s][key.to_s] << "\n"
          when "date_printed"
            fragment.content << @template["sections"][attr.to_s][key.to_s]
            fragment.content << @attributes[attr.to_s][key.to_s] << "\n"
          end
        end
      end
      self.add_fragment fragment
    end
  end

  def render_certificate
    fragment = PageFragment.new x: 0, y: 540, width: 720, height: 540, name: "page"
    fragment.image_file = "images/certificate-of-merit.jpg"
    self.add_fragment fragment

    @template[:sections].each_key do |attr|
      fragment = PageFragment.new
      fragment.font = @template[:defaults][:font_family]
      @template[:sections][attr].each do |key, value|
        if key == "font_size".to_sym
          fragment.font_size = value.to_i
        elsif key == "location".to_sym
          coordinates = value.split(" ")
          fragment.x = coordinates[0].to_i
          fragment.y = coordinates[1].to_i
          fragment.width = coordinates[2].to_i
          fragment.height = coordinates[3].to_i
        elsif key == "text".to_sym
          if value.match /\{\{(.*)\}\}/ #ex grabs {{name}}
            attribute = value.tr("{}", "")  #removes {{}} = > name
            attribute = attribute.to_sym
            fragment.content = @attributes[attribute] #this works
          else
            fragment.content = value
          end
        elsif key == "image".to_sym
          fragment.image_file = "images/signature.png"
        elsif key == "style".to_sym
          fragment.style = value.to_sym
        end
      end
      self.add_fragment fragment
    end
  end
end


attributes = {
  "name": "Tony Lin",
  "certificate": "Carpentry Level One",
  "completion_date": "2022-10-10",
  "type": "ar_batch_report",
  "report_id": "34512",

  "assessment_center": {
       "organization_name": "Triangle Rescue Standby Services LLC",
       "organization_id": "98373",
       "organization_address": "3875 I-10 East, Orange, TX 77630 US"
  },

  "assessment_site": {
       "organization_name": "Triangle Rescue Standby Services LLC",
       "organization_id": "98373",
       "organization_address": "3875 I-10 East, Orange, TX 77630 US"
  },


  
  "info": {
       "direct": "Yes",
       "date_printed": "10/26/2022",
       "card_number": "98232",
       "name": "Tony Lin",

       "entries": {
            "entry1": {
                 "date_scored": "10/10/2022",
                 "certificate_type": "Certificate",
                 "certificate_name": "Scaffold Builder V3",
                 "credential_type": "Knowledge Verified",
                 "wallet_card": "X",
                 "silver_card": "",
                 "gold_card": ""
      },

      "entry2": {
       "date_scored": "10/10/2022",
       "certificate_type": "Wallet Card",
       "certificate_name": "Scaffold Builder V3",
       "credential_type": "Knowledge Verified",
       "blue_card": "X",
       "silver_card": "",
       "gold_card": ""
      }
    }
  }
}


template = {
  "template": {
    "title": "2023 Craft Certificate",
    "category": "certificates",
    "page_size": "400 900",
    "type": "certificate",
    "color": "FFFFFF"
  },

  "defaults": {
    "font_family": "Times-Roman",
    "font_size": "12pt"
  },

  "sections": {
    "header1": {
      "font_size": "20pt",
      "location": "70 360 400 30",
      "text": "NCCER Presents",
      "style": "italic"
    },
    "header2": {
      "font_size": "20pt",
      "location": "240 360 400 70",
      "text": "2023 Craft Certificate",
      "style": "italic"
    },
    "name": {
      "font_size": "40pt",
      "font_style": "italic",
      "location": "160 280 400 110",
      "text": "{{name}}",
      "style": "italic"
    },

    "presented-header": {
      "location": "150 150 90 220",
      "text": "Presented On"
    },
    "presented-date": {
      "location": "140 130 120 250",
      "text": "{{completion_date}}"
    },

    "signature": {
      "location": "450 150 125 120",
      "image": "images/certificates/boyd_signature.png"
    }
  }
}


renderer = Renderer.new(template,attributes)

#puts renderer.template[:template][:title]
case renderer.template["template".to_sym]["type".to_sym]

when "certificate"
  COLOR = template["template".to_sym]["color".to_sym]
  BACKGROUND = template[:template][:background_color]
  renderer.render_certificate

when "ar_batch_report", "pv_batch_report"
  COLOR = template["template".to_sym]["color".to_sym]
  BACKGROUND = template["template".to_sym]["background_color".to_sym]
  #$table = true
  puts $table
  renderer.render_batch_report

else
  puts "Non Existent"
  BACKGROUND = "FFFFFF"
end

renderer.render
