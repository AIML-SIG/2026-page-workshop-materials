using Accessors, Logging, LoggingExtras

function InitialScale(init::AbstractVector; freeze=true)
    layer = Lux.Scale(length(init), use_bias=false; init_weight=(args...) -> Float32.(init))
    return freeze ? Lux.Experimental.freeze(layer) : layer
end


function copy_over_previous_weights(pair::Pair{<:NamedTuple, <:NamedTuple})
    ps_from, ps_to = pair

    # :theta is always in the ps:
    Accessors.@reset ps_to.theta.encoder = deepcopy(ps_from.theta)

    if :phi in keys(ps_from) && :phi in keys(ps_to)
        Accessors.@reset ps_to.error = deepcopy(ps_from.error)
    end
    if :omega in keys(ps_from) && :omega in keys(ps_to)
        Accessors.@reset ps_to.error = deepcopy(ps_from.error)
    end
    if :error in keys(ps_from) && :error in keys(ps_to)
        Accessors.@reset ps_to.error = deepcopy(ps_from.error)
    end
    
    return ps_to
end

function population_to_df(population; covariates=[:wt, :age, :sex, :crcl])
    X = get_x(population)
    kwargs = map(eachrow(X), covariates) do x, cov
        NamedTuple{(cov, )}((x, ))
    end
    return DataFrame(merge(kwargs...))
end

function shap_predict(model, data::DataFrame, ps, st; explain_idx=1)
    X = transpose(Matrix{Float32}(data))

    data_pred = DataFrame(y_pred = first(model(X, ps.theta, st.theta))[explain_idx, :])
    return data_pred
end

function interpret(dcm, covariate, explain_idx, ps, st)
    num_cov = length(dcm.model.layer_1.lb)
    x_dummy = transpose(hcat([collect(0:0.01f0:1) for _ in 1:num_cov]...))

    out, _ = dcm.model.layer_2.layers[covariate](x_dummy, ps.theta.layer_2[covariate], st.theta.layer_2[covariate])
    anchor = reshape(fill(0.5f0, num_cov), :, 1)
    out_anchor, _ = dcm.model.layer_2.layers[covariate](anchor, ps.theta.layer_2[covariate], st.theta.layer_2[covariate])

    effect = out ./ out_anchor

    x = x_dummy .* st.theta.layer_1.ub

    if explain_idx > size(effect, 1)
        throw(ErrorException("`explain_idx` ($explain_idx) is greater than the number of outputs / heads for this layer ($(size(effect, 1)))."))
    end 

    return x[1, :], effect[explain_idx, :]
end

function interpret_node(dcm, ps, st; t_dummy=0:360)
    t_dummy = transpose(collect(t_dummy))
    effect, _ = dcm.model.node(t_dummy, ps.theta.dynamics.node, st.theta.dynamics.node)
    return vec(t_dummy), vec(effect)
end


# The newest version of OrdinaryDiffEq added logging to warn when dt[1] 
# is smaller than floatmin. This is quite annoying so we disable this:
filter_func(log) = !occursin("Initial timestep too small (near machine epsilon)", log.message)
global_logger(ActiveFilteredLogger(filter_func, global_logger()))

