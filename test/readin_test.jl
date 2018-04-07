using Base.Test

include("../src/Device.jl")
include("../src/ReadIn.jl")
using ReadIn

excitation_csv = "test_dyes_excitation.csv"
emission_csv = "test_dyes_emission.csv"
antigens_csv = "test_antigens.csv"
fcm_device = Device.testdevice

@testset "routine flow" begin
    (neo_data, template, interaction) = get_normalized_data(excitation_csv,
        emission_csv, antigens_csv, fcm_device)
    @testset "template validation" begin
        @test typeof(template) == Array{Float64,3}
        @test template[:,:,1] == Array{Float64,2}([1 1 0;1 1 1;999 0 0])
    end
    @testset "interaction validation" begin
        @test typeof(interaction) == Dict{Symbol, Dict{Int, Dict{Symbol, Array{Float64,1}}}}
    end
    @testset "meta validation" begin
        @test typeof(neo_data) == ReadIn.NeoData
        @test neo_data.markers == [:marker1, :marker2, :marker3]
        @test neo_data.dyes == [ReadIn.Dye(:dye1, 1),ReadIn.Dye(:dye2, 1),ReadIn.Dye(:dye3, 1)]
    end

    @testset "data export" begin
        @test ReadIn.store_data("export_to_mat", template, interaction, neo_data, export_to=:MAT) == nothing
    end
end
