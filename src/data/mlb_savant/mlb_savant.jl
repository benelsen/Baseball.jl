export statcast_search

# all=true
# hfPT=
# hfAB=
# hfBBT=
# hfPR=
# hfZ=
# stadium=
# hfBBL=
# hfNewZones=
# hfGT=R|
# hfC=
# hfSea=
# hfSit=
# player_type=pitcher
# hfOuts=
# opponent=
# pitcher_throws=
# batter_stands=
# hfSA=
# game_date_gt=
# game_date_lt=
# hfInfield=
# team=
# position=
# hfOutfield=
# hfRO=
# home_road=
# hfFlag=
# hfPull=
# metric_1=
# hfInn=
# min_pitches=0
# min_results=0
# group_by=name
# sort_col=pitches
# player_event_sort=h_launch_speed
# sort_order=desc
# min_pas=0
# type=details

const q_base = HTTP.URIs.queryparams("all=true&hfPT=&hfAB=&hfBBT=&hfPR=&hfZ=&stadium=&hfBBL=&hfNewZones=&hfGT=R%7C&hfC=&hfSea=&hfSit=&player_type=&hfOuts=&opponent=&pitcher_throws=&batter_stands=&hfSA=&game_date_gt=&game_date_lt=&hfInfield=&team=&position=&hfOutfield=&hfRO=&home_road=&hfFlag=&hfPull=&metric_1=&hfInn=&min_pitches=0&min_results=0&group_by=&sort_col=&player_event_sort=&sort_order=desc&min_pas=0&type=details&")

function fetch_statcast_search(query::AbstractDict)
    query_req = merge(q_base, query)
    req = HTTP.get("https://baseballsavant.mlb.com/statcast_search/csv", query = query_req, status_exception = true, verbose = 0)
    IOBuffer(req.body)
end

statcast_search(pairs::Pair...) = statcast_search(Dict(pairs...))

function statcast_search(query::AbstractDict)
    io = fetch_statcast_search(query)

    data = CSV.read(
        io,
        allowmissing = :all,
        missingstrings = ["null"],
        categorical = false,
        types = savant_types,
    )

    if :error ∈ names(data)
        error(data[1, :error])
    end

    # Delete deprecated columns? Are they always empty?
    # deletecols!(data, [:spin_dir, :spin_rate_deprecated, :break_angle_deprecated, :break_length_deprecated, :tfs_deprecated, :tfs_zulu_deprecated])

    # These columns should not have any missings
    disallowmissing!(data, [:game_date, :game_pk, :at_bat_number])

    # Baseball Savant's Statcast Search seems to truncate at 40000 rows. Better warn the user.
    if size(data, 1) === 40000
        @warn "Baseball Savant Statcast Search returned 40000 rows. Data might be truncated, check extents."
    end

    data
end

savant_types = Dict(
    :pitch_type => Union{String, Missing},
    :game_date => Date,
    :release_speed => Union{Float64, Missing},
    :release_pos_x => Union{Float64, Missing},
    :release_pos_y => Union{Float64, Missing},
    :release_pos_z => Union{Float64, Missing},
    :player_name => Union{String, Missing},
    :batter => Int64,
    :pitcher => Int64,
    :events => Union{String, Missing},
    :description => Union{String, Missing},
    :spin_dir => Union{Float64, Missing},
    :spin_rate_deprecated => Union{Float64, Missing},
    :break_angle_deprecated => Union{Float64, Missing},
    :break_length_deprecated => Union{Float64, Missing},
    :zone => Union{Int64, Missing},
    :des => Union{String, Missing},
    :game_type => Union{String, Missing},
    :stand => String,
    :p_throws => String,
    :home_team => String,
    :away_team => String,
    :type => String,
    :hit_location => Union{Int64, Missing},
    :bb_type => Union{String, Missing},
    :balls => Int64,
    :strikes => Int64,
    :game_year => Int64,
    :pfx_x => Union{Float64, Missing},
    :pfx_z => Union{Float64, Missing},
    :plate_x => Union{Float64, Missing},
    :plate_z => Union{Float64, Missing},
    :on_3b => Union{Int64, Missing},
    :on_2b => Union{Int64, Missing},
    :on_1b => Union{Int64, Missing},
    :outs_when_up => Int64,
    :inning => Union{Int64, Missing},
    :inning_topbot => Union{String, Missing},
    :hc_x => Union{Float64, Missing},
    :hc_y => Union{Float64, Missing},
    :tfs_deprecated => Union{String, Missing},
    :tfs_zulu_deprecated => Union{String, Missing},
    :fielder_2 => Union{Int64, Missing},
    :umpire => Union{Int64, Missing},
    :sv_id => Union{String, Missing},
    :vx0 => Union{Float64, Missing},
    :vy0 => Union{Float64, Missing},
    :vz0 => Union{Float64, Missing},
    :ax => Union{Float64, Missing},
    :ay => Union{Float64, Missing},
    :az => Union{Float64, Missing},
    :sz_top => Union{Float64, Missing},
    :sz_bot => Union{Float64, Missing},
    :hit_distance_sc => Union{Float64, Missing},
    :launch_speed => Union{Float64, Missing},
    :launch_angle => Union{Float64, Missing},
    :effective_speed => Union{Float64, Missing},
    :release_spin_rate => Union{Float64, Missing},
    :release_extension => Union{Float64, Missing},
    :game_pk => Int64,
    :pitcher_1 => Int64,
    :fielder_2_1 => Union{Int64, Missing},
    :fielder_3 => Union{Int64, Missing},
    :fielder_4 => Union{Int64, Missing},
    :fielder_5 => Union{Int64, Missing},
    :fielder_6 => Union{Int64, Missing},
    :fielder_7 => Union{Int64, Missing},
    :fielder_8 => Union{Int64, Missing},
    :fielder_9 => Union{Int64, Missing},
    :estimated_ba_using_speedangle => Union{Float64, Missing},
    :estimated_woba_using_speedangle => Union{Float64, Missing},
    :woba_value => Union{Float64, Missing},
    :woba_denom => Union{Float64, Missing},
    :babip_value => Union{Float64, Missing},
    :iso_value => Union{Float64, Missing},
    :launch_speed_angle => Union{Float64, Missing},
    :at_bat_number => Int64,
    :pitch_number => Int64,
    :pitch_name => Union{String, Missing},
    :home_score => Int64,
    :away_score => Int64,
    :bat_score => Int64,
    :fld_score => Int64,
    :post_away_score => Int64,
    :post_home_score => Int64,
    :post_bat_score => Int64,
    :post_fld_score => Int64,
    :if_fielding_alignment => Union{String, Missing},
    :of_fielding_alignment => Union{String, Missing}
)
