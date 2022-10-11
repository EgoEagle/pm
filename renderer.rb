require 'prawn'
require 'json'

file = File.read('template.json')
data_hash = JSON.parse(file)

data_hash['sections']['name']['text'] = "Tony";
data_hash['sections']['presented-date']['text'] = "10/10/22";
