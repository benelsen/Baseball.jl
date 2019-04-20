export air_density, absolute_pressure, vapor_pressure_over_water

"""
    air_density(P, T, ϕ)

Calculate density of humid air [kg/m^3] given absolute pressure `P` [Pa], temperature `T` [K] and relative humidity `ϕ` [1].
"""
function air_density(P, T, ϕ)
    R_d = 287.058
    R_v = 461.495

    P_sat = vapor_pressure_over_water(T - 273.15)
    P_v = ϕ * P_sat
    P_d = P - P_v

    (P_d / R_d + P_v / R_v) / T
end

"""
    absolute_pressure(p0, h)

Calculate the absolute pressure [Pa] at altitude `h` [m] for a given sea level static pressure [Pa].
"""
function absolute_pressure(P0, h)
    R = 8.3144598 # universal gas constant
    M = 0.0289644 # molar mass of Earth's air
    g0 = 9.80665 # gravitational acceleration

    if h < 11000
        Tb = 288.15
        Pb = 101325.00
        hb = 0.0
        Lb = -0.0065 # standard temperature lapse rate (K/m)
    else
        error("not implemented for altitude $(h) m")
    end

    P0 * (Tb / (Tb + Lb * (h - hb)))^(g0 * M / R / Lb)
end

"""
    vapor_pressure_over_water(T)

Compute the saturation vapor pressure over liquid water in Pa given temperature `T` in °C.

# References
- Arden L Buck (1981) - New Equations for Computing Vapor Pressure and Enhancement Factor
- Arden L Buck (1996)
"""
function vapor_pressure_over_water(Tc)
    1000 * 0.61121 * exp((18.678 - Tc / 234.5) * (Tc / (257.14 + Tc)))
end
