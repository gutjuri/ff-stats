import JSON

using Dates
using Plots

const logpath = "collected-data"
const outpath = "plots"
const df = DateFormat("YYYY-mm-dd HH:MM")

# reads log data from the specified file
function readfile(file)
  data = Dict()
  for line in eachline(file)
    linedata = JSON.parse(line)
    date = DateTime(linedata["date"], df)
    userstats = linedata["user_stats"]
    data[date] = userstats
  end
  data
end

# reads all .log files in the logfolder
function readfflogs(logfolder)
  data = Dict()
  for logfile in filter(fname -> endswith(fname, ".log"), readdir(logfolder))
    open(logfolder * "/" * logfile) do file
      merge!(data, readfile(file))
    end
  end
  data
end

function users_summed(data)
  summedusers = Dict()
  for (date, userdata) in data
    summedusers[date] = sum(values(userdata))
  end
  summedusers
end

function plotnetstats(data)
  summeddata = sort(collect(users_summed(data)), by = x -> x[1])
  plot(map(x->x[1], summeddata), map(x->x[2], summeddata), linewidth=2, title="Test")
end

function filterbyhost(data, host)
  husers = Dict()
  for (date, userdata) in data
    husers[date] = userdata[host]
  end
  husers
end

function plotjuhastats(data)
  juhadata_withzeroes = collect(filterbyhost(data, "JuHa_Blaubeuren"))
  juhadata = sort(filter(e -> e[2] != 0, juhadata_withzeroes), by = x -> x[1])
  
  xvals = map(x->x[1], juhadata)
  yvals = map(x->x[2], juhadata)
  
  scatter(xvals, yvals, title="JuHa Blaubeuren Freifunk Daten", label=["Nutzer/Stunde"], m=(:heat, 0.8, Plots.stroke(1, :red)))
  
  xlabel!("Datum")
  ylabel!("Nutzer")
  
  outfile = outpath * "/stats-juha.svg"
  savefig(outfile)
end

gr()