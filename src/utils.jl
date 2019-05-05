
get_union_type_2(::Type{Union{Missing, T}}) where T = T

function create_time(time_str, ampm, tz)
    if ismissing(time_str) || ismissing(ampm)
        return missing
    end
    dt = DateTime(time_str, dateformat"yyyy/mm/dd H:MM")
    dt += hour(dt) == 12 ? (ampm == "AM" ? Hour(12) : Hour(0)) : (ampm == "PM" ? Hour(12) : Hour(0))
    ZonedDateTime(dt, tz)
end
