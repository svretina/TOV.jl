module Constants
using Unitful
using UnitfulAstro

export L_geom_km, to_solarmass

const M_sun_val = 1.0u"Msun"
const G_val = 1.0u"G"
const c_val = 1.0u"c"

const L_geom_km = ustrip(u"km", G_val * M_sun_val / c_val^2)

to_solarmass(m_geom_km) = m_geom_km / L_geom_km

end
