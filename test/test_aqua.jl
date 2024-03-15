module TestAqua

using Aqua
using Test
using T8code

@testset "Aqua.jl" begin
    Aqua.test_all(T8code)
end

end #module
