
function get_dyes_candidate(df::DataFrame, markername::Symbol)
    @from item in df begin
        @where item.markers == String(markername)
        @select Symbol(item.dyes)
        @collect
    end
end

function get_dye_wave_score(df::DataFrame, dyename::Symbol, loc::Int64, scale::Int64=0)
    waverange = range(loc-scale, stop=loc+scale, step=1)
    score_array = @from item in df begin
        @where item.Wavelength in waverange
        @select item[dyename]
        @collect
    end

    _score = mean(score_array)
    return _score>0 ? _score : 0  #XXX: why there could be a negative value in the data csv???
end

function get_interaction_sheet(readin_marker_density::Array{Tuple{Symbol, T}, 1}, markerfile::String, emissionfile::String, excitationfile::String, device::FCMDevice) where {T <: Number}
    marker_sheet = CSV.read(markerfile, allowmissing=:none)
    dye_emission_sheet = CSV.read(emissionfile, allowmissing=:none)
    dye_excitation_sheet = CSV.read(excitationfile, allowmissing=:none)

    sparse_interaction = DataFrame(laser=Vector{Symbol}(undef, 0),
                                   lens_mu=Vector{Int64}(undef, 0),
                                   lens_sig=Vector{Int64}(undef, 0),
                                   marker=Vector{Symbol}(undef, 0),
                                   dye=Vector{Symbol}(undef, 0),
                                   score=Vector{Float64}(undef, 0))

    for (laser_name, laser_lambda) in device.lasers, (marker_name, marker_density) in readin_marker_density
        dye_candidate = get_dyes_candidate(marker_sheet, marker_name)
        for (lens_mu, lens_sig) in device.lens[laser_name], dye_name in dye_candidate
            excitation_score = get_dye_wave_score(dye_excitation_sheet, dye_name, laser_lambda)
            emission_score = get_dye_wave_score(dye_emission_sheet, dye_name, lens_mu, lens_sig)
            _score = excitation_score * emission_score * log10(marker_density)
            push!(sparse_interaction, [laser_name, lens_mu, lens_sig, marker_name, dye_name, _score])
        end
    end

    sparse_interaction
end

function solve(sparse_interaction::DataFrame, readin_marker_density::Array{Tuple{Symbol, T}, 1}) where {T <: Number}
    solution_order = permutations(readin_marker_density)
    solution = Vector{DataFrame}(undef, 0)

    for marker_order in solution_order
        epoch_sheet = sparse_interaction
        possible_result = DataFrame(laser=Vector{Symbol}(undef, 0),
                                    lens_mu = Vector{Int64}(undef, 0),
                                    lens_sig = Vector{Int64}(undef, 0),
                                    marker = Vector{Symbol}(undef, 0),
                                    dye = Vector{Symbol}(undef, 0),
                                    score = Vector{Float64}(undef, 0))

        try
            for (each_marker, _) in marker_order
                thismarker_sheet = epoch_sheet[epoch_sheet.marker .== each_marker, :]
                j, ridx = findmax(thismarker_sheet.score)
                _choice = thismarker_sheet[ridx, :]
                push!(possible_result, convert(Array, _choice))
                epoch_sheet = epoch_sheet[(epoch_sheet.lens_mu .!= _choice.lens_mu).&(epoch_sheet.marker .!= _choice.marker).&(epoch_sheet.dye .!= _choice.dye), :]
            end
        catch e
            continue
        end

        push!(solution, possible_result)
    end
    solution
end
