export get_weather_darksky

function fetch_weather_darksky(api_key, time, longitude, latitude, altitude)
    timestr = Dates.format(astimezone(time, tz"UTC"), "yyyy-mm-ddTHH:MM:SS")

    url = "https://api.darksky.net/forecast/$( api_key )/$( latitude ),$( longitude ),$( timestr )Z?exclude=currently,alerts&units=si"
    req = HTTP.get(url)

    j = JSON.parse(String(req.body))

    weather = vcat(DataFrame.(merge.(Ref(Dict("precipType" => missing, "precipAccumulation" => missing, "windBearing" => missing, "pressure" => missing)), j["hourly"]["data"]))...)
    weather[:time] = ZonedDateTime.(unix2datetime.(weather[:time]), tz"UTC")
    weather[:pressure_absolute] = pressure_absolute.(weather[:pressure], altitude)
    weather[:density] = air_density.(weather[:pressure_absolute] .* 100, weather[:temperature] .+ 273.15, weather[:humidity])

    weather
end

fetch_weather_darksky(time, longitude, latitude, altitude) = fetch_weather_darksky(ENV["DARKSKY_API_KEY"], time, longitude, latitude, altitude)

function get_weather_darksky(time_date, ampm, longitude, latitude, altitude)
    gametime = create_time(time_date, ampm)

    w = fetch_weather_darksky(time_date, longitude, latitude, altitude)
    w2 = filter(r -> (round(time_date, Hour, RoundDown) + Hour(4)) >= r[Symbol("time")] >= round(time_date, Hour, RoundDown), w)

    wind_bearing = mean(skipmissing(w2[:windBearing]))
    pressure_absolute = mean(skipmissing(w2[:pressure_absolute]))

    (
        density           = round(mean(w2[:density]), digits = 4),
        temperature       = round(mean(w2[:temperature]), digits = 1),
        dew_point         = round(mean(w2[:dewPoint]), digits = 1),
        humidity          = round(mean(w2[:humidity]), digits = 3),
        pressure_absolute = ismissing(pressure_absolute) ? pressure_absolute : round(pressure_absolute, digits = 2),
        wind_bearing      = ismissing(wind_bearing) ? wind_bearing : round(wind_bearing, digits = 1),
        wind_speed        = round(mean(w2[:windSpeed]), digits = 2),
        wind_gust         = round(mean(w2[:windGust]), digits = 2),
    )
end
