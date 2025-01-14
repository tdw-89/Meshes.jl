# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    Rope(p1, p2, ..., pn)

An open polygonal chain from a sequence of points `p1`, `p2`, ..., `pn`.

See also [`Chain`](@ref) and [`Ring`](@ref).
"""
struct Rope{Dim,T,V<:AbstractVector{Point{Dim,T}}} <: Chain{Dim,T}
  vertices::V
end

function boundary(r::Rope)
  v = r.vertices
  PointSet([first(v), last(v)])
end

isclosed(::Type{<:Rope}) = false

Base.close(r::Rope) = Ring(r.vertices)

Base.open(r::Rope) = r

Base.reverse!(r::Rope) = (reverse!(r.vertices); r)
