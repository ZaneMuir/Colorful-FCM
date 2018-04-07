module Device


struct FCMDevice
    name :: String
    lasers :: Dict{Symbol,Int}
    lens :: Dict{Symbol,Array{Tuple{Int,Int},1}}
end


export ThermoFisher


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

ThermoFisher = FCMDevice("ThermoFisher", lasers, lens)
testdevice = FCMDevice("testdevice",
    Dict(:laser1 => 350, :laser2=>500),
    Dict(:laser1 => [(450,30)], :laser2 => [(700,50), (550,40)]))

function getcolornames(device::Device.FCMDevice)
    [name for (name, _) in device.lasers]
end

function getlensnumber(device::Device.FCMDevice)
    count = 0
    for (name, port) in device.lens
        count += length(port)
    end
    count
end

end  # module Device
