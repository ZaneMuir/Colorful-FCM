module ColorfulFCM

using DataFrames
using CSV

include("Device.jl")

export ThermoFisherDevice



##### ThermoFisher Device #####
lasers = Dict(
:red => 640,
:yellow => 561,
:blue => 488,
:violet => 405
)

lens = Dict(
    :red    => [(660, 20), (730, 45), (780, 60)],
    :yellow => [(586, 15), (610, 20), (670, 30), (710, 50), (780, 60)],
    :blue   => [(530, 30), (575, 26), (610, 20), (670, 30), (710, 50),
                (780, 60)],
    :violet => [(450, 50), (510, 50), (605, 40), (660, 40)]
)

ThermoFisherDevice = FCMDevice("ThermoFisher", lasers, lens)

testdevice = FCMDevice("testdevice",
    Dict(:laser1 => 350, :laser2=>500),
    Dict(:laser1 => [(450,30)], :laser2 => [(700,50), (550,40)]))


end # module ColorfulFCM