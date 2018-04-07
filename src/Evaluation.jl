module Evaluation

export get_result

const alpha_dict = Dict(:normal=>1, :biotin=>4)

function get_marker_density(readin_marker_density, markers;
                            default_value=1, default_flag=:normal)

    result = Dict{Symbol, Float64}()

    for item in markers
        result[item] = default_value * alpha_dict[default_flag]
    end

    for item in readin_marker_density
        if length(item) == 2
            result[item[1]] = item[2]*alpha_dict[default_flag]
        elseif length(item) == 3
            result[item[1]] = item[2]*alpha_dict[item[3]]
        else
            throw(BoundsError("""readin_marker_density have invalid shape.
            require: Array{Tuple{Symbol, Float64[, Symbol]}}"""))
        end
    end
    [(name, result[name]) for name in markers]
end

function initiate_template_matrix(
                marker_density,
                template,
                device,
                metadata)

    template_n = 0
    template_copy = template
    for (each_laser, ports) in device.lens
        for (each_port, _) in ports
            template_n += 1

            for i=1:length(metadata.markers)
                template_copy[i,:,template_n] *= log(marker_density[i][2])
            end

            for i=1:length(metadata.dyes)
                dyename = metadata.dyes[i].name

                template_copy[:,i,template_n] *= 2^metadata.dyes[i].brightness *
                    metadata.exratio[each_laser][1, dyename]/100 *
                    mean(metadata.emratio[each_laser][each_port][:, dyename])
            end
        end
    end
    #template_copy[isnan.(demo_template)]=-999
    template_copy
end

function findmax_pos(ndarray)
    value, pos = findmax(ndarray)
    value, (pos % size(ndarray)[1],
            ceil(pos/size(ndarray)[1]) % size(ndarray)[2] |> Int,
            ceil(pos/size(ndarray)[1]/size(ndarray)[2]) % size(ndarray)[1] |> Int )
end


function get_result(metadata, template, interaction, device, readin_marker_density)

    result = Dict{Symbol, Tuple{Symbol, Float64}}()
    choicer = :unkown
    marker_density = get_marker_density(readin_marker_density, metadata.markers)
    initiation = initiate_template_matrix(marker_density, template, device, metadata)

    for each_epoch in readin_marker_density
        value, pos = findmax_pos(initiation)
        choicer = metadata.dyes[pos[2]].name
        choicee = metadata.markers[pos[1]]
        result[choicee] = (choicer, value)

        initiation[:,pos[2],:] = NaN
        initiation[pos[1],:,:] = NaN

        template_n = 0
        for (each_laser, ports) in device.lens
            for (each_port, _) in ports
                template_n += 1
                applyer = interaction[each_laser][each_port][choicer]
                initiation[:,:,template_n] .*= applyer'
            end
        end
    end
    result
end

end  # module Evaluation
