module ObjIO
  export vertexes_from_str, triangles_from_str, str_from_vertexes, str_from_triangles

  function _list_by_prefix(prefix, text, to_type)
    ls = []
    for line in split(text, '\n')
      if startswith(line, prefix)
          line = strip(line[length(prefix)+1:length(line)])
          push!(ls, tuple([to_type(replace(l, "," => ".")) for l in split(line,' ')]...))
      end
    end
    return ls
  end

  function vertexes_from_str(text)
    return _list_by_prefix("v ", text, function(s) parse(Float64, s) end)
  end

  function faces_from_str(text)
    return _list_by_prefix("f ", text, function(s) parse(Int64, split(s, "/")[1]) end)
  end

  function _str_by_prefix(prefix, elements)
    st = ""
    for (a, b, c) in elements
      st *= string(prefix, a, ' ', b, ' ', c, '\n')
    end
    return st
  end

  function str_from_vertexes(vertexes)
    return _str_by_prefix("v ", vertexes)
  end

  function str_from_faces(faces)
    return _str_by_prefix("f ", faces)
  end

  function tests()
    vertexes = [(-1.0, -1.0, -1.0), (1.0, -1.0, -1.0), (-1.0, 1.0, -1.0), (1.0, 1.0, -1.0), (-1.0, -1.0, 1.0), (1.0, -1.0, 1.0), (-1.0, 1.0, 1.0), (1.0, 1.0, 1.0)]
    faces  = [(1, 2, 3), (3, 2, 4), (8, 6, 7), (6, 7, 5)]
    println("Writing test obj")
    open("test.obj", "w") do file
      write(file, str_from_vertexes(vertexes))
      write(file, str_from_faces(faces))
    end
    open("test.obj", "r") do file
      text = read(file, String)
      new_vertexes = vertexes_from_str(text)
      new_faces = faces_from_str(text)
      println(new_vertexes)
      println(new_faces)
    end
  end
end
