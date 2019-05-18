module Sploxels

    struct Sploxel
        g_shift :: Array{Float64,1}
        g_value :: Array{Float64,1}
        topology :: Array{Array{Bool,1},1}
        # topology = connections to the neighboring sploxels
        # x-axis -1:+1
        # y-axis -1:+1
        # z-axis -1:+1
    end

end
