module SurfaceMesh
  export build_3d_mesh, distance_to_gradient_operator

  function build_3d_mesh(bbox_min, bbox_max, cube_size, distance_in_point, gradient_in_point)
    points = []
    faces = []
    for z in bbox_min[3]:cube_size:bbox_max[3]
      for y in bbox_min[2]:cube_size:bbox_max[2]
        for x in bbox_min[1]:cube_size:bbox_max[1]
          # detect border, create walls
          cube_center = (x + cube_size / 2., y + cube_size / 2., z + cube_size / 2.)
          neighbor100 = (x - cube_size / 2., y + cube_size / 2., z + cube_size / 2.)
          neighbor010 = (x + cube_size / 2., y - cube_size / 2., z + cube_size / 2.)
          neighbor001 = (x + cube_size / 2., y + cube_size / 2., z - cube_size / 2.)
          d = distance_in_point(cube_center)
          d100 = distance_in_point(neighbor100)
          d010 = distance_in_point(neighbor010)
          d001 = distance_in_point(neighbor001)

          # x-wall
          if(sign(d) != sign(d100))
            start_index = length(points) + 1
            push!(points, (x, y, z))
            push!(points, (x, y + cube_size, z))
            push!(points, (x, y + cube_size, z + cube_size))
            push!(points, (x, y, z + cube_size))
            if (d < d100)
	      push!(faces, (start_index, start_index + 1, start_index + 2))
	      push!(faces, (start_index, start_index + 2, start_index + 3))
            else
	      push!(faces, (start_index, start_index + 2, start_index + 1))
	      push!(faces, (start_index, start_index + 3, start_index + 2))
            end
          end

          # y-wall
          if(sign(d) != sign(d010))
            start_index = length(points) + 1
            push!(points, (x, y, z))
            push!(points, (x + cube_size, y, z))
            push!(points, (x + cube_size, y, z + cube_size))
            push!(points, (x, y, z + cube_size))
            if (d < d010)
	      push!(faces, (start_index, start_index + 1, start_index + 2))
	      push!(faces, (start_index, start_index + 2, start_index + 3))
            else
	      push!(faces, (start_index, start_index + 2, start_index + 1))
	      push!(faces, (start_index, start_index + 3, start_index + 2))
            end
          end

          # z-wall
          if(sign(d) != sign(d001))
            start_index = length(points) + 1
            push!(points, (x, y, z))
            push!(points, (x + cube_size, y, z))
            push!(points, (x + cube_size, y + cube_size, z))
            push!(points, (x, y + cube_size, z))
            if (d < d001)
	      push!(faces, (start_index, start_index + 1, start_index + 2))
	      push!(faces, (start_index, start_index + 2, start_index + 3))
            else
	      push!(faces, (start_index, start_index + 2, start_index + 1))
	      push!(faces, (start_index, start_index + 3, start_index + 2))
            end
          end
        end
      end
    end

    # shift the points to match the target surface better
    better_points = []
    for point in points
      shift = vscale(gradient_in_point(point), -distance_in_point(point))
      better_point = vsum(point, shift)
      push!(better_points, better_point)
    end

    return (better_points, faces)
  end

  function distance_to_gradient_operator(distance_in_point)
    eps = 1e-5 # warning! arbitrary number
    return function(point)
      d = distance_in_point(point)
      d100 = distance_in_point(vsum(point, (eps, 0., 0.)))
      d010 = distance_in_point(vsum(point, (0., eps, 0.)))
      d001 = distance_in_point(vsum(point, (0., 0., eps)))
      return ((d100 - d)/eps, (d010 - d)/eps, (d001 - d)/eps)
    end
  end

  function vsum(a, b)
    return tuple([ai + bi for (ai, bi) in zip(a, b)]...)
  end

  function vscale(a, x)
    return tuple([ai * x for ai in a]...)
  end

  function tests()
    if vsum((1,2,3), (4,5,6)) != (5,7,9)
      println("vsum is broken")
    end
    distance_function = function(x) return sqrt(x[1]^2 + x[2]^2 + x[3]^2) - 1 end
    gradient_function = distance_to_gradient_operator(distance_function)
    build_3d_mesh((-1, -1, -1), (1, 1, 1), 0.25, distance_function, gradient_function)
  end
end
