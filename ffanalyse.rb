require 'json'
require 'date'
require 'gruff' 

def read_from_file filename
  fdata = {}
  File.open(filename).each do |line|
    record = JSON.parse(line)
    date = DateTime.strptime(record['date'], '%Y-%m-%d %H:%M').to_time.to_i
    user_counts = record['user_stats']
    fdata.store(date, user_counts)
  end
  fdata
end

def make_date_labels graph
    graph.x_label_margin = 40
    graph.bottom_margin = 60
    graph.disable_significant_rounding_x_axis = true
    graph.use_vertical_x_labels = true
    #graph.enable_vertical_line_markers = true
    graph.marker_x_count = 50 # One label every 2 days
    graph.x_axis_label_format = lambda do |value|
      DateTime.strptime(value.to_i.to_s,'%s').strftime('%d.%m.%Y')
    end
   # graph.y_axis_increment = 1
end

alldata = {}

puts('Starting to read all data')

Dir.glob('collected-data/*.log') do |filename|
  alldata.merge!(read_from_file(filename))
end

puts('Read all data')

# Filter and keep only data of JuHa Blaubeuren
juha_data = alldata.transform_values do |usercounts|
  usercounts.keep_if { |hostname, _| hostname == "JuHa_Blaubeuren"}.values.fetch(0, 0)
end.keep_if { |_, cnt| cnt != 0 }


#puts juha_data

juha_graph = Gruff::Scatter.new('1500x750')
juha_graph.title = 'Nutzerzahlen JuHa Blaubeuren'
juha_graph.font = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
juha_graph.data('Nutzerzahlen', juha_data.keys, juha_data.values)
juha_graph.circle_radius = 2.0
juha_graph.hide_legend = true
juha_graph.marker_font_size = 10
#juha_graph.stroke_width = 0.01
make_date_labels(juha_graph)
juha_graph.write('plots/stats-juha-new.png')


puts('Wrote Juha Graph')
