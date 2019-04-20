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
    req = HTTP.get("https://baseballsavant.mlb.com/statcast_search/csv", query = query_req, status_exception = true, verbose = 1)
    IOBuffer(req.body)
end

function statcast_search(query::AbstractDict)
    io = fetch_statcast_search(query)

    data = CSV.read(
        io,
        allowmissing = :all,
        missingstrings = ["null"],
        categorical = false,
        types = Dict(
            :game_pk => Int64,
            :launch_angle => Union{Float64, Missing},
            :hit_distance_sc => Union{Float64, Missing},
            :release_spin_rate => Union{Float64, Missing},
            :sv_id => Union{String, Missing},
            :des => Union{String, Missing},
            :player_name => Union{String, Missing},
        )
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
