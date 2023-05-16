local const = {}

local d = defines.direction
const.signal_positions = {
    ["straight-rail"] = {
        [d.north] = {
            {x = -1.5, y =  0.5, direction = d.north},
            {x = -1.5, y = -0.5, direction = d.north},
            {x =  1.5, y =  0.5, direction = d.south},
            {x =  1.5, y = -0.5, direction = d.south},
        },
        [d.northeast] = {
            {x =  1.5, y = -1.5, direction = d.southeast},
            {x = -0.5, y =  0.5, direction = d.northwest},
        },
        [d.east] = {
            {x = -0.5, y = -1.5, direction = d.east},
            {x = -0.5, y =  1.5, direction = d.west},
            {x =  0.5, y = -1.5, direction = d.east},
            {x =  0.5, y =  1.5, direction = d.west},
        },
        [d.southeast] = {
            {x = -0.5, y = -0.5, direction = d.northeast},
            {x =  1.5, y =  1.5, direction = d.southwest},
        },
        [d.southwest]= {
            {x = -1.5, y =  1.5, direction = d.northwest},
            {x =  0.5, y = -0.5, direction = d.southeast},
        },
        [d.northwest] = {
            {x = -1.5, y = -1.5, direction = d.northeast},
            {x =  0.5, y =  0.5, direction = d.southwest},
        },
    },
    ["curved-rail"] = {
        [d.north] = {
            {x = -0.5, y =  3.5, direction = d.north},
            {x =  2.5, y =  3.5, direction = d.south},
            {x = -2.5, y = -1.5, direction = d.northwest},
            {x = -0.5, y = -3.5, direction = d.southeast},
        },
        [d.northeast] = {
            {x = -2.5, y =  3.5, direction = d.north},
            {x =  0.5, y =  3.5, direction = d.south},
            {x =  0.5, y = -3.5, direction = d.northeast},
            {x =  2.5, y = -1.5, direction = d.southwest},
        },
        [d.east] = {
            {x = -3.5, y = -0.5, direction = d.east},
            {x = -3.5, y =  2.5, direction = d.west},
            {x =  1.5, y = -2.5, direction = d.northeast},
            {x =  3.5, y = -0.5, direction = d.southwest},
        },
        [d.southeast] = {
            {x = -3.5, y = -2.5, direction = d.east},
            {x = -3.5, y =  0.5, direction = d.west},
            {x =  3.5, y =  0.5, direction = d.southeast},
            {x =  1.5, y =  2.5, direction = d.northwest},
        },
        [d.south] = {
            {x = -2.5, y = -3.5, direction = d.north},
            {x =  0.5, y = -3.5, direction = d.south},
            {x =  0.5, y =  3.5, direction = d.northwest},
            {x =  2.5, y =  1.5, direction = d.southeast},
        },
        [d.southwest] = {
            {x = -0.5, y = -3.5, direction = d.north},
            {x =  2.5, y = -3.5, direction = d.south},
            {x = -2.5, y =  1.5, direction = d.northeast},
            {x = -0.5, y =  3.5, direction = d.southwest},
        },
        [d.west] = {
            {x =  3.5, y = -2.5, direction = d.east},
            {x =  3.5, y =  0.5, direction = d.west},
            {x = -3.5, y =  0.5, direction = d.northeast},
            {x = -1.5, y =  2.5, direction = d.southwest},
        },
        [d.northwest] = {
            {x =  3.5, y = -0.5, direction = d.east},
            {x =  3.5, y =  2.5, direction = d.west},
            {x = -1.5, y = -2.5, direction = d.southeast},
            {x = -3.5, y = -0.5, direction = d.northwest},
        },
    }
}

return const