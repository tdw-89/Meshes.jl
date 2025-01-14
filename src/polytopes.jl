# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    Polytope{K,Dim,T}

We say that a geometry is a K-polytope when it is a collection of "flat" sides
that constitue a `K`-dimensional subspace. They are called chain, polygon and
polyhedron respectively for 1D (`K=1`), 2D (`K=2`) and 3D (`K=3`) subspaces,
embedded in a `Dim`-dimensional space. The parameter `K` is also known as the
rank or parametric dimension of the polytope: https://en.wikipedia.org/wiki/Abstract_polytope.

The term polytope expresses a particular combinatorial structure. A polyhedron,
for example, can be decomposed into faces. Each face can then be decomposed into
edges, and edges into vertices. Some conventions act as a mapping between vertices
and higher dimensional features (edges, faces, cells...), removing the need to
store all features.

Additionally, the following property must hold in order for a geometry to be considered
a polytope: the boundary of a (K+1)-polytope is a collection of K-polytopes, which may
have (K-1)-polytopes in common. See https://en.wikipedia.org/wiki/Polytope.

### Notes

- Type aliases are `Polygon`, `Polyhedron`.
"""
abstract type Polytope{K,Dim,T} <: Geometry{Dim,T} end

(::Type{PL})(vertices::Vararg{P}) where {PL<:Polytope,P<:Point} = PL(collect(vertices))
(::Type{PL})(vertices::AbstractVector{TP}) where {PL<:Polytope,TP<:Tuple} = PL(Point.(vertices))
(::Type{PL})(vertices::Vararg{TP}) where {PL<:Polytope,TP<:Tuple} = PL(collect(vertices))

"""
    paramdim(polytope)

Return the parametric dimension or rank of the polytope.
"""
paramdim(::Type{<:Polytope{K}}) where {K} = K

"""
    vertex(polytope, ind)

Return the vertex of a `polytope` at index `ind`.
"""
vertex(p::Polytope, ind) = vertices(p)[ind]

"""
    vertices(polytope)

Return the vertices of a `polytope`.
"""
vertices(p::Polytope) = p.vertices

"""
    nvertices(polytope)

Return the number of vertices in the `polytope`.
"""
nvertices(p::Polytope) = length(vertices(p))

"""
    p1 == p2

Tells whether or not polytopes `p1` and `p2` are equal.
"""
==(p1::Polytope, p2::Polytope) = vertices(p1) == vertices(p2)

"""
    centroid(polytope)

Return the centroid of the `polytope`.
"""
centroid(p::Polytope) = Point(sum(coordinates, vertices(p)) / length(vertices(p)))

"""
    unique(polytope)

Return a new `polytope` without duplicate vertices.
"""
Base.unique(p::Polytope) = unique!(deepcopy(p))

"""
    unique!(polytope)

Remove duplicate vertices in `polytope`.
"""
function Base.unique!(::Polytope) end

function Base.show(io::IO, p::Polytope)
  name = prettyname(p)
  vert = join(vertices(p), ", ")
  print(io, "$name($vert)")
end

function Base.show(io::IO, ::MIME"text/plain", p::Polytope{K,Dim,T}) where {K,Dim,T}
  name = prettyname(p)
  println(io, "$name{$Dim,$T}")
  print(io, io_lines(vertices(p), "  "))
end

# -----------
# 1-POLYTOPE
# -----------

"""
    Chain{Dim,T}

A chain is a 1-polytope, i.e. a polytope with parametric dimension 1.
See https://en.wikipedia.org/wiki/Polygonal_chain.

See also [`Segment`](@ref), [`Rope`](@ref), [`Ring`](@ref).
"""
const Chain = Polytope{1}

"""
   length(polytope)

Return the length of the 1-`polytope`.
"""
Base.length(c::Chain) = measure(c)

"""
    segments(chain)

Return the segments linking consecutive points of the `chain`.
"""
function segments(c::Chain)
  v = c.vertices
  n = length(v) - !isclosed(c)
  (Segment(view(v, [i, i + 1])) for i in 1:n)
end

"""
    isperiodic(chain)

Tells whether or not the `chain` is periodic
along each parametric dimension.
"""
isperiodic(C::Type{<:Chain}) = (isclosed(C),)

"""
    isclosed(chain)

Tells whether or not the chain is closed.

A closed chain is also known as a ring.
"""
isclosed(c::Chain) = isclosed(typeof(c))

"""
   issimple(chain)

Tells whether or not the `chain` is simple.

A chain is simple when all its segments only
intersect at end points.
"""
function issimple(c::Chain)
  λ(I) = !(type(I) == CornerTouchingSegments || type(I) == NoIntersection)
  ss = collect(segments(c))
  for i in 1:length(ss)
    for j in (i + 1):length(ss)
      if intersection(λ, ss[i], ss[j])
        return false
      end
    end
  end
  true
end

"""
    close(chain)

Close the `chain`, i.e. add a segment going from the last to the first vertex.
"""
function Base.close(::Chain) end

"""
    open(chain)

Open the `chain`, i.e. remove the segment going from the last to the first vertex.
"""
function Base.open(::Chain) end

"""
    unique!(chain)

Remove duplicate vertices in the `chain`.
Closed chains remain closed.
"""
function Base.unique!(c::Chain)
  # sort vertices lexicographically
  verts = vertices(open(c))
  perms = sortperm(coordinates.(verts))

  # remove true duplicates
  keep = Int[]
  sorted = @view verts[perms]
  for i in 1:(length(sorted) - 1)
    if sorted[i] != sorted[i + 1]
      # save index in the original vector
      push!(keep, perms[i])
    end
  end
  push!(keep, last(perms))

  # preserve chain order
  sort!(keep)

  # update vertices in place
  copy!(verts, verts[keep])

  c
end

"""
    unique(chain)

Return a new `chain` without duplicate vertices.
Closed chains remain closed.
"""
Base.unique(c::Chain) = unique!(deepcopy(c))

"""
    reverse!(chain)

Reverse the `chain` vertices in place.
"""
function Base.reverse!(::Chain) end

"""
    reverse(chain)

Reverse the `chain` vertices.
"""
Base.reverse(c::Chain) = reverse!(deepcopy(c))

"""
    angles(chain)

Return angles `∠(vᵢ-₁, vᵢ, vᵢ+₁)` at all vertices
`vᵢ` of the `chain`. If the chain is open, the first
and last vertices have no angles. Positive angles
represent a CCW rotation whereas negative angles
represent a CW rotation. In either case, the
absolute value of the angles returned is never
greater than `π`.
"""
function angles(c::Chain)
  vs = vertices(c)
  i1 = firstindex(vs) + !isclosed(c)
  i2 = lastindex(vs) - !isclosed(c)
  map(i -> ∠(vs[i - 1], vs[i], vs[i + 1]), i1:i2)
end

# implementations of Chain
include("polytopes/segment.jl")
include("polytopes/rope.jl")
include("polytopes/ring.jl")

# ---------------------
# 2-POLYTOPE (POLYGON)
# ---------------------

"""
    Polygon{Dim,T}

A polygon is a 2-polytope, i.e. a polytope with parametric dimension 2.

See also [`Ngon`](@ref) and [`PolyArea`](@ref).
"""
const Polygon = Polytope{2}

"""
    area(polygon)

Return the area of the `polygon`.
"""
area(p::Polygon) = measure(p)

"""
    rings(polygon)

Return the outer and inner rings of the polygon.
"""
function rings end

"""
    hasholes(polygon)

Tells whether or not the `polygon` contains holes.
"""
function hasholes end

"""
    issimple(polygon)

Tells whether or not the `polygon` is simple.
See [https://en.wikipedia.org/wiki/Simple_polygon]
(https://en.wikipedia.org/wiki/Simple_polygon).
"""
issimple(p::Polygon) = issimple(typeof(p))

"""
    windingnumber(point, polygon)

Winding number of `point` with respect to the `polygon`.
"""
function windingnumber end

"""
    orientation(polygon)

Returns the orientation of the rings of the `polygon`
as either counter-clockwise (CCW) or clockwise (CW).
"""
orientation(p::Polygon) = orientation(p, WindingOrientation())

function orientation(p::Polygon, algo)
  o = [orientation(ring, algo) for ring in rings(p)]
  hasholes(p) ? o : first(o)
end

"""
    boundary(polygon)

Returns the boundary of the `polygon`.
"""
boundary(p::Polygon) = hasholes(p) ? Multi(rings(p)) : first(rings(p))

"""
    isconvex(polygon)

Tells whether or not the `polygon` is convex.
"""
isconvex(p::Polygon{Dim,T}) where {Dim,T} = issimple(p) && all(≤(T(π)), innerangles(boundary(p)))

"""
    bridge(polygon; width=0)

Transform `polygon` with holes into a single outer chain
via bridges of given `width` as described in Held 1998.
Return the outer chain and a vector with pairs of indices
for duplicate vertices. These indices can be used to undo
the bridges.

## References

* Held. 1998. [FIST: Fast Industrial-Strength Triangulation of Polygons]
  (https://link.springer.com/article/10.1007/s00453-001-0028-4)
"""
function bridge(p::Polygon{Dim,T}; width=zero(T)) where {Dim,T}
  if hasholes(p)
    bridge(rings(p), width=width)
  else
    first(rings(p)), []
  end
end

# implementations of Polygon
include("polytopes/ngon.jl")
include("polytopes/polyarea.jl")

# ------------------------
# 3-POLYTOPE (POLYHEDRON)
# ------------------------

"""
    Polyhedron{Dim,T}

A polyhedron is a 3-polytope, i.e. a polytope with parametric dimension 3.

See also [`Tetrahedron`](@ref), [`Hexahedron`](@ref) and [`Pyramid`](@ref).
"""
const Polyhedron = Polytope{3}

"""
   volume(polyhedron)

Return the volume of the `polyhedron`.
"""
volume(p::Polyhedron) = measure(p)

# implementations of Polyhedron
include("polytopes/tetrahedron.jl")
include("polytopes/hexahedron.jl")
include("polytopes/pyramid.jl")
