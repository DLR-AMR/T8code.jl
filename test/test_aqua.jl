module TestAqua

using Aqua: Aqua
using ExplicitImports: test_explicit_imports
using Test
using T8code

@testset "Aqua.jl" begin
    Aqua.test_all(T8code)
end

@testset "ExplicitImports.jl" begin
    test_explicit_imports(T8code,
                          # We use `MPI_Comm` and `MPI_File`, which are non-public
                          all_explicit_imports_are_public = false,
                          # We use `MPIPreferences.binary`, which is non-public
                          all_qualified_accesses_are_public = false)
end

end #module
