using Luxor, Colors

function draw_neutron_star(pos, col, radius)
    @layer begin
        translate(pos)

        # 1. Background glow
        sethue(col)
        setopacity(0.3)
        circle(O, radius * 1.5, :fill)

        # 2. Core 
        setopacity(1.0)
        sethue("white")
        circle(O, radius * 0.3, :fill)

        # 3. Accretion Swirls
        sethue(col)
        setline(2)
        for start_angle in range(0, 2π, length=6)
            points = Point[]
            for t in 0:0.1:1.5π
                r = (radius * 0.3) + (t * radius * 0.18)
                push!(points, polar(r, start_angle + t))
            end
            poly(points, :stroke)
        end
    end
end

function create_tov_logo(filename="tov_logo.svg")
    # Increase dimensions slightly for padding
    Drawing(1000, 1000, filename)
    origin()
    # background(colorant"#0a1128")

    j_green = colorant"#389826"
    j_red = colorant"#cb3c33"
    j_blue = colorant"#4063d8"

    # 1. Outer Silver Borders
    setline(10)
    sethue("silver")
    circle(O, 420, :stroke)
    setline(4)
    circle(O, 445, :stroke)

    # 2. Position the stars
    dist = 195
    p_green = Point(0, -dist)
    p_red = Point(dist * cos(π / 6), dist * sin(π / 6))
    p_blue = Point(-dist * cos(π / 6), dist * sin(π / 6))

    # Central gravity glow
    # @layer begin
    #     sethue("white")
    #     setopacity(0.15)
    #     circle(O, 120, :fill)
    # end

    draw_neutron_star(p_green, j_green, 85)
    draw_neutron_star(p_red, j_red, 85)
    draw_neutron_star(p_blue, j_blue, 85)

    # 3. Typography
    sethue("white")
    fontface("sans-serif")

    # Top Text: textcurve(string, angle_rotation, radius, center)
    fontsize(80)
    # Luxor's textcurve: center of text is at the angle provided
    textcurve("TOV.jl", -π / 2 - 0.32, 340, O)

    # 4. Year
    # fontsize(22)
    # text("2026", Point(0, 395), halign=:center)

    finish()
    println("Success! Logo saved to $(abspath(filename))")
end

create_tov_logo()