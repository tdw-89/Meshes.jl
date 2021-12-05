# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    RegularDiscretization(n1, n2, ..., np)

A method to discretize primitive geometries using regular
samples along each parametric dimension. The number of
samples `n1`, `n2`, ..., `np` is passed to [`RegularSampling`](@ref).
"""
struct RegularDiscretization{N} <: DiscretizationMethod
  sizes::Dims{N}
end

RegularDiscretization(sizes::Vararg{Int,N}) where {N} =
  RegularDiscretization(sizes)

function discretize(sphere::Sphere{3,T},
                    method::RegularDiscretization) where {T}
  nx, ny = fitdims(method.sizes, paramdim(sphere))

  # sample points regularly
  sampler = RegularSampling((nx, ny))
  points  = collect(sample(sphere, sampler))

  # connect regular samples with quadrangles
  topo   = GridTopology((nx-1, ny-1))
  middle = collect(elements(topo))
  offset = nx*ny - nx
  for i in 1:nx-1
    u = offset + i
    v = offset + i + 1
    w = i + 1
    z = i
    quad = connect((u, v, w, z))
    push!(middle, quad)
  end

  # add north and south poles
  c = center(sphere)
  r = radius(sphere)
  e⃗ = Vec{3,T}(0, 0, 1)
  push!(points, c + r*e⃗)
  push!(points, c - r*e⃗)

  # connect north pole with triangles
  north = map(1:ny-1) do j
    u = nx*ny + 1
    v = 1 + (j-1)*nx
    w = 1 + (j  )*nx
    connect((u, v, w))
  end
  u = nx*ny + 1
  v = 1 + (ny-1)*nx
  w = 1
  push!(north, connect((u, v, w)))

  # connect south pole with triangles
  south = map(1:ny-1) do j
    u = nx*ny + 2
    v = (j  )*nx
    w = (j+1)*nx
    connect((u, w, v))
  end
  u = nx*ny + 2
  v = ny*nx
  w = nx
  push!(south, connect((u, w, v)))

  connec = [middle; north; south]

  SimpleMesh(points, connec)
end