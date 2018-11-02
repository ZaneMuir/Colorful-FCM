# Device.jl
#
# container and manipulations with FCM devices.
#
# author: yizhan miao
# email: yzmiao@protonmail.com
# last update: Oct 18 2018


"""FCMDevice

basic configurations of an FCM device.

Fields:
name  ::String
lasers::Dict{Symbol, Int}
lens  ::Dict{Symbol,Array{Tuple{Int,Int},1}}

- name:   the name of your fcm device
- lasers: the wave length of the lasers, 
          Symbol of the color or the name of the laser
- lens:   Symbol as the laser name. Array as the sensors of
          each laser. Tuple as the mean sensor wave length and 
          the sensor range, repectively.
"""
struct FCMDevice
    name :: String
    lasers :: Dict{Symbol,Int}
    lens :: Dict{Symbol,Array{Tuple{Int,Int},1}}
end



function getcolornames(device::FCMDevice)
    [name for (name, _) in device.lasers]
end


function getlensnumber(device::FCMDevice)
    count = 0
    for (name, port) in device.lens
        count += length(port)
    end
    count
end