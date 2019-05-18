module Sploxels
    @enum VoxelState begin
        inside = -1
        on_margin = 0
        outside = 1
    end

    struct Sploxel
        g_shift :: Array{Float64,1}
        g_value :: Array{Float64,1}
        voxel_state :: VoxelState
        topology :: Array{Array{Bool,1},1}
        # topology = connections to the neighboring sploxels
        # x-axis -1:+1
        # y-axis -1:+1
        # z-axis -1:+1
    end
end
