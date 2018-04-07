module Export

using MAT
# using HDF5

export to_mat

"""
.MAT format can only support dict with string keys.
thus we have to convert symbol and integer key into strings.
in the meantime, we also need to re-organize the data structure into dict type.

return [markers, dyes_name, dyes_brightness, template_mat, interaction_map]
"""
function data_simplification(template, interaction, neodata)
    markers = [String(item) for item in neodata.markers]
    dyes_name = [String(item.name) for item in neodata.dyes]
    dyes_brightness = [item.brightness for item in neodata.dyes]
    template_mat = template[:,:,1]
    interaction_map = begin
        result = Dict{String, Dict{String, Array{Float64,1}}}()
        for (each_color, port_results) in interaction
            for (each_port_number, dyes_results) in port_results
                port_name = String(each_color)*repr(each_port_number)
                result[port_name] = Dict{String, Array{Float64,1}}()
                for (each_dye_name, beta_array) in dyes_results
                    result[port_name][String(each_dye_name)] = beta_array
                end
            end
        end
        result
    end
    markers, dyes_name, dyes_brightness, template_mat, interaction_map
end


"""
export data template, interaction, rawdata into .MAT format.
for the possible future uses in matlab.
"""
function to_mat(name, template, interaction, rawdata)
    markers, dyes_name, dyes_brightness, template_mat, interaction_map = data_simplification(template, interaction, rawdata)
    matwrite(name, Dict(
        "markers" => markers,
        "dyes_name" => dyes_name,
        "dyes_brightness" => dyes_brightness,
        "template" => template_mat,
        "interaction" => interaction_map))
end


# """
# export data template, interaction, rawdata into .MAT format.
# for the possible future uses in other general programming languages.
# """
# function to_hdf5(name, template, interaction, rawdata)
#    markers, dyes_name, dyes_brightness, template_mat, interaction_map = data_simplification(template, interaction, rawdata)
#    h5write(name, "markers", markers)
# end

end  # module Export
