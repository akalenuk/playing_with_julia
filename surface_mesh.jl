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
            if (d > d100)
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
            if (d > d001)
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

    # remove the redundant points
    xyz_to_is = Dict()
    for (i, point) in enumerate(points)
      if haskey(xyz_to_is, point)
        push!(xyz_to_is[point], i)
      else
        xyz_to_is[point] = [i]
      end
    end
    less_points = []
    old_is_to_i = Dict()
    for (i, xyz_is) in enumerate(xyz_to_is)
      push!(less_points, xyz_is[1])
      for j in xyz_is[2]
        old_is_to_i[j] = i
      end
    end
    new_faces = []
    for face in faces
      push!(new_faces, tuple([old_is_to_i[i] for i in face]...))
    end

    # shift the points to match the target surface better
    better_points = []
    for point in less_points
      gradient_shift = vscale(gradient_in_point(point), -distance_in_point(point))
      # limiter gives worse approximation quality, but nicer mesh
      # let's try limiting shift if necessary by renormalizing the whole thing
#      max_axial_shift = max([abs(di) for di in gradient_shift]...)
#      if max_axial_shift > cube_size  # let's limit to the cube size since there are cases where this is the case. Doesn't exclude intersects though
#        gradient_shift = vscale(gradient_shift, cube_size / max_axial_shift)
#      end
      better_point = vsum(point, gradient_shift)
      push!(better_points, better_point)
    end

    return (better_points, new_faces)
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

  function vlimit(a, min_ai, max_ai)
    return tuple([min(max(min_ai, ai), max_ai) for ai in a]...)
  end

  function vsum(a, b)
    return tuple([ai + bi for (ai, bi) in zip(a, b)]...)
  end

  function vscale(a, x)
    return tuple([ai * x for ai in a]...)
  end

  function vdot(a, b)
    return sum([ai * bi for (ai, bi) in zip(a, b)])
  end

  function vnormalized(a)
    d = sqrt(sum(vdot(a, a)))
    return vscale(a, 1. / d)
  end

  function tests()
    if vsum((1,2,3), (4,5,6)) != (5,7,9)
      println("vsum is broken")
    end
    if vlimit((1, 2, 3), 1.5, 2.5) != (1.5, 2, 2.5)
      println("vlimit is broken")
    end
    distance_function = function(x) return sqrt(x[1]^2 + x[2]^2 + x[3]^2) - 1 end
    gradient_function = distance_to_gradient_operator(distance_function)
    points, faces = build_3d_mesh((-1, -1, -1), (1, 1, 1), 0.25, distance_function, gradient_function)
    for face in faces
      for i in 1:3
        j = i == 3 ? 1 : i + 1
        edge_to_normal = vdot(
            points[face[i]], 
            vnormalized(
              vsum(
                points[face[i]], 
                vscale(points[face[j]], -1.))))
        if edge_to_normal < 0 || edge_to_normal > 0.2
          println("Mesh generator is broken ", edge_to_normal)
        end
      end
    end
  end
end
