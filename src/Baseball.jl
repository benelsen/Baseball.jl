module Baseball

using HTTP
using DataFrames
using EzXML
using Dates
using TimeZones

include("utils.jl")
include("data/mlb_game_files/mlb_game_files.jl")
include("atmosphere.jl")

end # module
