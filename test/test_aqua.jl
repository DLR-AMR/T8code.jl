module TestAqua

using Aqua: Aqua
using ExplicitImports: test_explicit_imports
using Test
using T8code

@testset "Aqua.jl" begin
    Aqua.test_all(T8code)
end

@testset "ExplicitImports.jl" begin
    test_explicit_imports(T8code)
end

end #module
