module TestAqua

using Aqua: Aqua
using ExplicitImports: test_explicit_imports
using Test
using T8code

# When run in CI, check if we are running with system MPI or Julia artifacts
JULIA_MPI_PROVIDER = get(ENV, "JULIA_MPI_PROVIDER", "JLL_MPI")

@testset "Aqua.jl" begin
    # in case we are running with system MPI t8code_jll will not be loaded
    if JULIA_MPI_PROVIDER == "SYSTEM_MPI"
        stale_deps_ignore = (ignore = [:T8code],)
    else
        stale_deps_ignore = ()
    end

    Aqua.test_all(T8code; stale_deps = stale_deps_ignore)
end

@testset "ExplicitImports.jl" begin
    test_explicit_imports(T8code,
                          # We use `MPI_Comm` and `MPI_File`, which are non-public
                          all_explicit_imports_are_public = false,
                          # We use `MPIPreferences.binary`, which is non-public
                          all_qualified_accesses_are_public = false)
end

end #module
