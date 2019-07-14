require 'json'
require 'date'
require 'gruff' 


# read log data from log files.
# log files have the following format
# {"date": "YYYY-mm-dd HH:MM", "user_stats": {"node1": user_count1, "node2": user_count2, ...} } 
# each line represents one hour, so most logfiles should have 24 lines
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

# Format graph (label style etc.)
class Gruff::Base
  def layout_graph
    @x_label_margin = 40
    @bottom_margin = 60
    @disable_significant_rounding_x_axis = true
    @use_vertical_x_labels = true
    @marker_x_count = 10 # One label every month

    # Label format
    @x_axis_label_format = lambda do |value|
      DateTime.strptime(value.to_i.to_s,'%s').strftime('%b %Y')
    end

    @circle_radius = 2.0
    @marker_font_size = 10

    @font = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'

    #enable_vertical_line_markers = true
    #y_axis_increment = 1
    #stroke_width = 0.01
  end
end

# Read in all data

alldata = {}

puts('Starting to read all data')

Dir.glob('collected-data/*.log') do |filename|
  alldata.merge!(read_from_file(filename))
end

puts('Read all data')

# Make graph of data from the Jugendhaus Blaubeuren

puts('Starting JuHa Plot')

juha_data = alldata.transform_values do |usercounts|
  usercounts.select { |hostname, _| hostname == "JuHa_Blaubeuren"}.values.fetch(0, 0)
end.keep_if { |_, cnt| cnt != 0 }

juha_graph = Gruff::Scatter.new('1500x750')
juha_graph.title = 'Nutzerzahlen JuHa Blaubeuren'
juha_graph.data('Nutzerzahlen', juha_data.keys, juha_data.values)
juha_graph.layout_graph

juha_graph.hide_legend = true
juha_graph.maximum_value = 50
juha_graph.minimum_value = 0.0
juha_graph.write('plots/stats-juha-new.png')

puts('Wrote Juha Plot')

# Make graph of data across all freifunk nodes

class Hash
  def sum_transform_by(&proc)
    transform_values { |usercounts| usercounts.values.reduce(:+) }
      .keep_if { |_, cnt| cnt != 0 }
      .group_by { |k, _| DateTime.strptime(k.to_i.to_s,'%s').strftime('%Y-%m-%d')}
      .map { |_, vs| [vs[0][0], proc.call(vs)] }
      .sort
      .to_h
  end
end


puts('Starting network plot')
summed_data_max = alldata.sum_transform_by { |vs| vs.max_by  { |v| v[1] }[1] }
summed_data_min = alldata.sum_transform_by { |vs| vs.min_by  { |v| v[1] }[1] }

# puts summed_data
summed_graph = Gruff::Line.new('1500x750')
summed_graph.title = 'Nutzerzahlen Gesamtnetz'
summed_graph.dataxy('Maximale gleichzeitige Nutzer', summed_data_max.keys, summed_data_max.values)
summed_graph.dataxy('Minimale gleichzeitige Nutzer', summed_data_min.keys, summed_data_min.values)
summed_graph.layout_graph
summed_graph.labels = summed_data_max.keys.map { |s| [s, DateTime.strptime(s.to_i.to_s,'%s').strftime('%b %Y')] }.uniq { |_, dl| dl }.to_h
#summed_graph.maximum_value = 50
summed_graph.minimum_value = 0.0
summed_graph.y_axis_increment = 50
summed_graph.write('plots/stats-gesamt-new.png')
puts('Wrote network plot')
