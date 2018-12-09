include("obj_io.jl")
include("surface_mesh.jl")

ObjIO.tests()
SurfaceMesh.tests()

# some checker bump-map. It can be any noise function for instance
bump_map_w = 64
bump_map_h = 64
bump_map = zeros(Float64, bump_map_w, bump_map_h)
for i in 1:bump_map_h
  for j in 1:bump_map_w
    bump_map[i, j] = xor(((i - 1) % 16 < 8), ((j - 1) % 16 < 8)) ? 1.0 : 0.0
  end
end

bump_from_uv = function(uv)
  # bump-map coordinates
  j = 1 + uv[1] * bump_map_w
  i = 1 + uv[2] * bump_map_h
  j0 = floor(Int, j)
  j1 = min(floor(Int, j) + 1, bump_map_w)
  i0 = floor(Int, i)
  i1 = min(floor(Int, i) + 1, bump_map_h)
#  bump = bump_map[i0, j0]
  bump = bump_map[i1, j1] * (j - j0) * (i - i0)   # syntax thing, you can't just split a string into several
  bump += bump_map[i1, j0] * (j1 - j) * (i - i0) 
  bump += bump_map[i0, j0] * (j1 - j) * (i1 - i) 
  bump += bump_map[i0, j1] * (j - j0) * (i1 - i) 
  return bump
end


distance_function = function(x) 
  d = sqrt(x[1]^2 + x[2]^2 + x[3]^2) - 10 
  uv = (x[1] / 10., x[2] / 10.)
  if uv[1] > 0. && uv[1] < 1. && uv[2] > 0. && uv[2] < 1.
    d -= bump_from_uv(uv)
  end
  return d
end
gradient_function = SurfaceMesh.distance_to_gradient_operator(distance_function)
(vertexes, faces) = SurfaceMesh.build_3d_mesh((-10, -10, 5), (10, 10, 11), 0.25, distance_function, gradient_function)

open("test.obj", "w") do file
  write(file, ObjIO.str_from_vertexes(vertexes))
  write(file, ObjIO.str_from_faces(faces))
end
