using Test

@testset "Basic" begin
  include("Basic.jl")
end

@testset "Rules" begin
  include("Rules.jl")
end

@testset "Schedule" begin
  include("Schedule.jl")
end
