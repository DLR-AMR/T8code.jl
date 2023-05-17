module TestAll

using Test
using MPI: MPI
using P4est
using T8code

MPI.Init()

comm = MPI.COMM_WORLD

@testset "init" begin
  include("test_init.jl")
end

@testset "general" begin
  if !Sys.iswindows()
    # These tests do not work in Windows since the DLL loader does not search for symbols beyond libt8.dll.
    include("test_refcount.jl")
  end
end

@testset "cmesh" begin
  include("cmesh/test_readmshfile.jl")
end

@testset "forest" begin
  include("forest/test_element_volume.jl")
end

end # module
