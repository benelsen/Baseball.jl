export get_games, get_weather_mlb, fetch_game_file

function fetch_game_file(date::TimeType, basename::AbstractString)
    year = Dates.format(date, "yyyy")
    month = Dates.format(date, "mm")
    day = Dates.format(date, "dd")

    url = "https://gd2.mlb.com/components/game/mlb/year_$(year)/month_$(month)/day_$(day)/$(basename).xml"
    req = HTTP.get(url, status_exception = true)
    doc = parsexml(req.body)
end

function fetch_game_file(game_data_directory::AbstractString, basename::AbstractString)
    url = "https://gd2.mlb.com$(game_data_directory)/$(basename).xml"
    req = HTTP.get(url, status_exception = true)
    doc = parsexml(req.body)
end

function fetch_game_file(date::TimeType, game_id::AbstractString, basename::AbstractString)
    year = Dates.format(date, "yyyy")
    month = Dates.format(date, "mm")
    day = Dates.format(date, "dd")

    game_data_directory = "/components/game/mlb/year_$(year)/month_$(month)/day_$(day)/$(game_id)"
    fetch_game_file(game_data_directory, basename)
end

function fetch_game_file(date::TimeType, home_team_code::AbstractString, away_team_code::AbstractString, game_number::Integer, basename::AbstractString; home_sport_code = "mlb", away_sport_code = "mlb")
    year = Dates.format(date, "yyyy")
    month = Dates.format(date, "mm")
    day = Dates.format(date, "dd")
    game_id = "gid_$(year)_$(month)_$(day)_$(away_team_code)$(away_sport_code)_$(home_team_code)$(home_sport_code)_$(game_number)"

    game_data_directory = "/components/game/mlb/year_$(year)/month_$(month)/day_$(day)/$(game_id)"
    fetch_game_file(game_data_directory, basename)
end

game_types = [
    :status_indicator => String,
    :status => String,
    :id => String,
    :game_pk => Int64,
    :game_type => String,
    :stats_season => Union{Missing, Int64},

    :time_zone => String,
    :time_date => Union{Missing, ZonedDateTime},
    :original_date => Union{Missing, Date},
    :time => Union{Missing, Time},
    :ampm => String,

    :resume_time_date => Union{Missing, ZonedDateTime},
    :resume_date => Union{Missing, Date},
    :resume_time => Union{Missing, Time},
    :resume_ampm => Union{Missing, String},

    :description => Union{Missing, String},
    :location => Union{Missing, String},
    :venue => String,
    :venue_id => Int64,
    :venue_w_chan_loc => Union{Missing, String},
    :league => String,
    :away_code => String,
    :away_file_code => String,
    :away_division => Union{Missing, String},
    :away_league_id => Union{Missing, Int64},
    :away_name_abbrev => String,
    :away_sport_code => String,
    :away_team_id => Int64,
    :away_team_name => String,
    :away_team_city => String,
    :home_code => String,
    :home_file_code => String,
    :home_division => Union{Missing, String},
    :home_league_id => Union{Missing, Int64},
    :home_name_abbrev => String,
    :home_sport_code => String,
    :home_team_id => Int64,
    :home_team_name => String,
    :home_team_city => String,
    :double_header_sw => Union{Missing, Bool},
    :game_nbr => Union{Missing, Int64},
    :scheduled_innings => Int64,
    :series => Union{Missing, String},
    :ser_games => Union{Missing, Int64},
    :ser_home_nbr => Union{Missing, Int64},
    :series_num => Union{Missing, Int64},
    :tbd_flag => Union{Missing, Bool},
    :tiebreaker_sw => Union{Missing, Bool},
    :game_data_directory => Union{Missing, String}
]

function get_games(date::TimeType = today())
    doc = fetch_game_file(date, "master_scoreboard")

    games_year = findfirst("/games/@year", doc).content

    games = map(findall("/games/game", doc)) do game

        status_node = findfirst("status", game)

        ks = first.(game_types)
        vals = map(ks[3:end]) do key
            key_str = string(key)
            haskey(game, key_str) ? game[key_str] : missing
        end
        prepend!(vals, [status_node["ind"], status_node["status"]])

        NamedTuple{(ks...,)}(vals)
    end

    if isempty(games)
        DataFrame(last.(game_types), first.(game_types), 0)
    else
        d = DataFrame(games)
        for name in names(d)
            i = findfirst(isequal(name), first.(game_types))
            T = last(game_types[i])

            if name === :stats_season
                d[name] = map(eachrow(d)) do r
                    if ismissing(r[:stats_season]) || isempty(r[:stats_season])
                        games_year
                    else
                        r[:stats_season]
                    end
                end
            end

            if name == :time_date
                d[name] = map(eachrow(d)) do r
                    if ismissing(r[:time_date]) || isempty(r[:time_date])
                        if ismissing(r[:time]) || ismissing(r[:original_date])
                            return missing
                        end
                        r[:time_date] = r[:original_date] * " " * r[:time]
                    end
                    create_time(r[:time_date], r[:ampm], tz"America/New_York")
                end

            elseif name == :resume_time_date
                d[name] = map(eachrow(d)) do r
                    if ismissing(r[:resume_time_date]) || isempty(r[:resume_time_date])
                        if ismissing(r[:resume_time]) || ismissing(r[:resume_date])
                            return missing
                        end
                        r[:resume_time_date] = r[:resume_date] * " " * r[:resume_time]
                    end
                    create_time(r[:resume_time_date], r[:resume_ampm], tz"America/New_York")
                end

            elseif T === Char || T === Union{Missing, Char}
                d[name] = getindex.(d[name], 1)

            elseif T === Bool
                d[name] = isequal.(Ref("Y"), d[name])

            elseif T === Union{Missing, Bool}
                d[name] = map(d[name]) do e
                    ismissing(e) ? missing : isequal("Y", e)
                end

            elseif T <: Real
                d[name] = parse.(Ref(T), d[name])

            elseif T <: Union{Missing, Real}
                d[name] = map(e -> ismissing(e) || isempty(e) ? missing : parse.(Ref(get_union_type_2(T)), e), d[name])

            elseif T === Time || T === Union{Missing, Time}
                d[name] = map(d[name]) do e
                    try
                        Time(e)
                    catch
                        missing
                    end
                end

            elseif T === Date || T === Union{Missing, Date}
                d[name] = map(e -> ismissing(e) || isempty(e) ? missing : Date(e, dateformat"yyyy/mm/dd"), d[name])

            elseif T === String || T === Union{Missing, String}
                d[name] = map(e -> ismissing(e) || isempty(e) ? missing : e, d[name])

            else
                error("$(name) $(T) not implemented")
            end

            d[name] = convert(Vector{T}, d[name])
        end

        return d
    end
end

function get_weather_mlb(game_pk::Integer, game_data_directory::AbstractString)
    doc = fetch_game_file(game_data_directory, "plays")

    node = findfirst("//weather", doc)
    m_wind = match(r"(?<speed>\d+) ?mph (?<direction>[\w ]+)", node["wind"])

    (
        game_pk = game_pk,
        inside = node["condition"] == "Dome" || node["condition"] == "Roof Closed",
        cond = node["condition"],
        temperature = round((parse(Float64, node["temp"]) - 32) * (5/9), digits = 1),
        wind = node["wind"],
        wind_speed = round(parse(Float64, m_wind[:speed]) * 0.44704, digits = 2),
        wind_direction_str = m_wind[:direction]
    )
end
