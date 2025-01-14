# Polytopes

```@example polytopes
using JSServe: Page # hide
Page(exportable=true, offline=true) # hide
```

```@example polytopes
using Meshes, MeshViz # hide
import WGLMakie as Mke # hide
```

## Abstract

```@docs
Polytope
Polyhedron
Polygon
Chain
```

## Concrete

```@docs
Segment
```

```@example polytopes
Segment((0., 0.), (1.,1.)) |> viz
```

```@docs
Rope
```

```@example polytopes
Rope((0.,0.), (1.,0.5), (1.,1.), (2.,0.)) |> viz
```

```@docs
Ring
```

```@example polytopes
Ring((0.,0.), (1.,0.5), (1.,1.), (2.,0.)) |> viz
```

```@docs
Ngon
```

```@example polytopes
Triangle((0.,0.), (1.,0.), (0.,1.)) |> viz
```

```@docs
PolyArea
```

```@example polytopes
outer = [(0.0,0.0),(1.0,0.0),(1.0,1.0),(0.0,1.0)]
hole1 = [(0.2,0.2),(0.4,0.2),(0.4,0.4),(0.2,0.4)]
hole2 = [(0.6,0.2),(0.8,0.2),(0.8,0.4),(0.6,0.4)]
poly  = PolyArea(outer, [hole1, hole2]) |> viz
```

```@docs
Tetrahedron
```

```@example polytopes
Tetrahedron([(0,0,0),(1,0,0),(0,1,0),(0,0,1)]) |> viz
```

```@docs
Hexahedron
```

```@example polytopes
Hexahedron([(0,0,0),(1,0,0),(1,1,0),(0,1,0),
            (0,0,1),(1,0,1),(1,1,1),(0,1,1)]) |> viz
```

```@docs
Pyramid
```

```@example polytopes
Pyramid([(0,0,0),(1,0,0),(1,1,0),(0,1,0),(0,0,1)]) |> viz
```