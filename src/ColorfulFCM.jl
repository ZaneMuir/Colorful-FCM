module ColorfulFCM

using Statistics
using DataFrames
using CSV
using Query
using Combinatorics

include("Device.jl")
# include("ReadIn.jl")
# include("Evaluation.jl")
include("SparseSolution.jl")

export ThermoFisherDevice
# export get_normalized_data
# export get_result!
export get_interaction_sheet, solve



##### ThermoFisher Attune NxT in Jianhuali Lab #####
lasers = Dict(
:red => 637,
#:yellow => 561,
:blue => 488,
:violet => 405
)

lens = Dict(
    :red    => [(670, 14), (720, 30), (780, 60)],
    #:yellow => [(585, 16), (620, 15), (695, 40), (780, 60)],
    :blue   => [(530, 30), (590, 40), (695, 40)],
    :violet => [(440, 50), (512, 25), (603, 48), (710, 50)]
)

ThermoFisherDevice = FCMDevice("ThermoFisher", lasers, lens)

testdevice = FCMDevice("testdevice",
    Dict(:laser1 => 350, :laser2=>500),
    Dict(:laser1 => [(450,30)], :laser2 => [(700,50), (550,40)]))


end # module ColorfulFCM
