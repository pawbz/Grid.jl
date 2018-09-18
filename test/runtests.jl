using Grid
using Test


# generate 1D grid
g1d=Grid.M1D(0.0,2.0,1000)
g2d=Grid.M1D(0.0,2.0,1000)

@test isequal(g1d.x[1],0.0)
@test isequal(g1d.x[end],2.0)

@test isequal(g1d, g2d)

