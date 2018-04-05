#include("Device.jl")

module ReadIn

using DataFrames
using CSV
# using MAT
using SHA
using JLD
# using HDF5
using Device


struct Dye
    name :: Symbol
    brightness :: Int
end

struct RawData
    exspectrum :: DataFrames.DataFrame
    emspectrum :: DataFrames.DataFrame
    antigens   :: DataFrames.DataFrame

    markers :: Array{Symbol,1}
    dyes    :: Array{Dye, 1}
end

export get_normalized_data

function get_dye_brightness(dye_list; default_brightness=3)
    default_chart = Dict()
    for item in dye_list
        default_chart[item] = default_brightness
    end
    return chart-> begin
        for i =1:length(chart[:,1])
            name = Symbol(chart[i,1])
            value = chart[i,2]
            default_chart[name] = value
        end
        default_chart
    end
end

function readcsv(excitation_csv, emission_csv,
    antigens_csv, brightness_csv=nothing)

    excitation = CSV.read(excitation_csv, nullable=false)
    emission = CSV.read(emission_csv, nullable=false)
    antigens = CSV.read(antigens_csv,nullable=false)

    markernames = [Symbol(item) for item in antigens[:markers]] |> unique

    dyes_em = [item for item in emission.colindex.names
               if item != :Wavelength && item !=:wavelength] |> sort!
    dyes_ex = [item for item in excitation.colindex.names
               if item != :Wavelength && item !=:wavelength] |> sort!

    if dyes_em == dyes_ex
        dyenames = dyes_ex
    else
        throw(ArgumentError("names of dyes not match!"))
    end


    if brightness_csv != nothing
        brightness = CSV.read(brightness_csv, nullable=false) |>
                     get_dye_brightness(dyenames)
    else  # TODO: readin dyebrightness.csv
        dye_brightness = antigens[2:3] |> unique |> get_dye_brightness(dyenames)
    end

    dyes = [Dye(name, dye_brightness[name]) for name in dyenames]

    return RawData(excitation, emission, antigens, markernames, dyes)
end

function get_excitation_ratio(lasers, dye_excitation)
    result = Dict()
    for (laser_name, laser_lambda) in lasers
        index = find(x->x==laser_lambda, dye_excitation[:Wavelength])[1]
        target = dye_excitation[index, :]
        result[laser_name] = target
    end
    result
end

function get_emission_ratio(lens, dye_emission)
    result = Dict()
    for (laser_name, ports) in lens
        port_result = Dict()
        for (target, range) in ports
            ranger = find(x->(target-range)<=x<=(target+range), dye_emission[:Wavelength])
            port_result[target] = dye_emission[ranger[1]:ranger[end],2:end]
        end
        result[laser_name] = port_result
    end
    result
end

function generate_dyes_interaction(excite_ratio, emit_ratio, dyes, fcm_device)

    result = Dict{Symbol, Dict{Int, Dict{Symbol, Array{Float64,1}}}}()

    for (laser_name, _) in fcm_device.lasers
        laser_array = Dict()
        for (port, _) in fcm_device.lens[laser_name]
            port_array = Dict()
            for dominator in dyes
                domi_value = excite_ratio[laser_name][dominator.name][1] / 100 *
                            mean(emit_ratio[laser_name][port][dominator.name]) *
                            dominator.brightness
                dye_array = []
                for liberator in dyes
                    if liberator.name != dominator.name
                        libe_value = excite_ratio[laser_name][liberator.name][1] / 100 *
                                     mean(emit_ratio[laser_name][port][liberator.name]) *
                                     liberator.brightness
                        push!(dye_array, (domi_value-libe_value)/(domi_value+libe_value+1))
                    else
                        push!(dye_array, -Inf)
                    end
                end
                port_array[dominator.name] = dye_array
            end
            laser_array[port]=port_array
        end
        result[laser_name] = laser_array
    end
    result
end

function get_template(antigens, markers, dyes, level=1)
    template = zeros(length(markers), length(dyes))
    dyes_list = [item.name for item in dyes]
    for i=1:length(antigens[:,1])
        a1 = indexin([antigens[i,:markers] |> Symbol], markers)[1]
        a2 = indexin([antigens[i,:dyes] |> Symbol], dyes_list)[1]

        if a2 == 0  # FIXME: antigen that is never used?
            continue
        end

        template[a1, a2] = 1
    end
    template
    [sum(template[i,:]) == 1 && (template[i,:]*=999) for i =1:size(template)[1]]
    repeat(template, outer=(1,1,level))
end

function store_data(name, template, interaction, format=:JLD)
    if format == :JLD
        save(name, "template",template, "interaction",interaction)
    elseif format == :MAT
        nothing  # TODO: store in MAT format
    else
        throw(ArgumentError("storing format not defined."))
    end
end

function restore_data(filename, format=:JLD)
    if format == :JLD
        data = load(filename)
        return data["template"], data["interaction"]
    # TODO: restore MAT file
    # TODO: restore HDF5 file
    end
end

function generate_compact_sha(excitation_csv, emission_csv, antigens_csv)
    ex_sha = open(excitation_csv) do f
        bytes2hex(sha2_256(f))
    end

    em_sha = open(emission_csv) do f
        bytes2hex(sha2_256(f))
    end

    ag_sha = open(antigens_csv) do f
        bytes2hex(sha2_256(f))
    end

    shas = ex_sha[1:10] * em_sha[11:20] * ag_sha[21:30]

    shas
end

function get_normalized_data(excitation_csv, emission_csv, antigens_csv,
    fcm_device::Device.FCMDevice)
    preserved_data = generate_compact_sha(excitation_csv, emission_csv, antigens_csv)*".jld"
    if !isfile(preserved_data)
        # Generate data
        rawdata = readcsv(excitation_csv, emission_csv, antigens_csv)
        exratio = get_excitation_ratio(fcm_device.lasers, rawdata.exspectrum)
        emratio = get_emission_ratio(fcm_device.lens, rawdata.emspectrum)

        interaction = generate_dyes_interaction(exratio, emratio, rawdata.dyes, fcm_device)
        template = get_template(rawdata.antigens, rawdata.markers,
                                rawdata.dyes, Device.getlensnumber(fcm_device))
        store_data(preserved_data, template, interaction)
        println("data stored in: ", preserved_data)
    else
        template, interaction = restore_data(preserved_data)
        println("data restored from: ", preserved_data)
    end

    return (template, interaction)
end

end  # module ReadIn
