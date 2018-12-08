include("obj_io.jl")
include("surface_mesh.jl")

ObjIO.tests()
SurfaceMesh.tests()

distance_function = function(x) return sqrt(x[1]^2 + x[2]^2 + x[3]^2) - 1 end
gradient_function = SurfaceMesh.distance_to_gradient_operator(distance_function)
(vertexes, faces) = SurfaceMesh.build_3d_mesh((-1, -1, -1), (1, 1, 1), 0.25, distance_function, gradient_function)

open("test.obj", "w") do file
  write(file, ObjIO.str_from_vertexes(vertexes))
  write(file, ObjIO.str_from_faces(faces))
end
