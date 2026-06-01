using DeepCompartmentModels
using ComponentArrays

abstract type AbstractHybridUDEType <: AbstractUDEType end

struct HybridModel{E,NODE} <: Lux.AbstractLuxContainerLayer{(:encoder,:node)}
    num_latent::Int
    encoder::E
    node::NODE
end

DeepCompartmentModels.setup(rng::Random.AbstractRNG, dcm::DeepCompartmentModel{<:UniversalDiffEq,<:HybridModel}) = 
    Lux.setup(rng, dcm.model)

Lux.initialparameters(rng::Random.AbstractRNG, m::HybridModel) = (
    encoder = Lux.initialparameters(rng, m.encoder),
    dynamics = ComponentVector(
        latents = zeros(Float32, m.num_latent),
        node = Lux.initialparameters(rng, m.node),
        I = zero(Float32)
    )
)

Lux.initialstates(rng::Random.AbstractRNG, m::HybridModel) = (
    encoder = Lux.initialstates(rng, m.encoder),
    dynamics = (
        latents = NamedTuple(),
        node = Lux.initialstates(rng, m.node)
    )
)

# TODO: This does not have to be an AbstractHybridUDEType 
struct CustomUDE{O<:StaticSymbol} <: AbstractHybridUDEType 
    ode_fn::O
end

CustomUDE(s::Symbol) = CustomUDE(static(s))
Base.show(io::IO, ude::CustomUDE) = print(io, "CustomUDE{$(dynamic(ude.ode_fn))}()")

Base.show(io::IO, dcm::DeepCompartmentModel{<:UniversalDiffEq{P,T}}) where {P,T} = 
    print(io, "DeepCompartmentModel{ude = $(T), error = $(dcm.error)}")

function(::UniversalDiffEq{P,T})(model, u, p, t) where {P,T<:CustomUDE{StaticSymbol{:two_comp}}} 
    cl₀, v₁, q, v₂ = p.latents
    cl_t = model([t;;], p.node)
    cl = cl₀ * only(cl_t)

    k₁₀ = cl / v₁
    k₁₂ = q / v₁
    k₂₁ = q / v₂
    
    return [
        p.I / v₁ - (k₁₀ + k₁₂) * u[1] + k₂₁ * u[2],
        k₁₂ * u[1] - k₂₁ * u[2]
    ]
end

function DeepCompartmentModels.solve(
        dcm::DeepCompartmentModel{<:UniversalDiffEq,<:HybridModel}, 
        individual::AbstractIndividual, 
        ps::Union{NamedTuple, ComponentArray},
        st::NamedTuple; 
        kwargs...
    )
    ζ, _ = dcm.model.encoder(get_x(individual), ps.theta.encoder, st.theta.encoder)
    z = vec(random_effect(ζ, ps, st))
    ps_dynamic = ComponentVector([z; ps.theta.dynamics.node; zero(ps.theta.dynamics.I)], getaxes(ps.theta.dynamics))
    
    prob = DeepCompartmentModels.build_problem(dcm.problem, dcm.model, st)
    return solve(prob, individual, ps_dynamic; sensealg = dcm.sensealg, kwargs...)
end

random_effect(ζ::AbstractArray, _, ::NamedTuple{(:theta,)}) = ζ
function random_effect(ζ::AbstractVector, ps, st::NamedTuple{(:theta,:phi)})
    η = DeepCompartmentModels.get_random_effects(ps, st)
    return @. ζ * exp(η)
end

function DeepCompartmentModels.solve_for_target(
        dcm::DeepCompartmentModel{<:UniversalDiffEq,<:HybridModel}, 
        individual::AbstractIndividual, 
        ps::NamedTuple,
        st::NamedTuple; 
        kwargs...
    )
    sol = solve(dcm, individual, ps, st; kwargs...)
    return DeepCompartmentModels._take_target(sol, individual, dcm.target)
end

function DeepCompartmentModels.build_problem(ude::UniversalDiffEq{P}, model::HybridModel, st::NamedTuple) where P<:SciMLBase.AbstractODEProblem
    stateful = Lux.StatefulLuxLayer{true}(model.node, nothing, st.theta.dynamics.node)
    dudt(u, p, t; model = stateful) = ude(model, u, p, t)
    return remake(ude.problem, f = dudt)
end

DeepCompartmentModels._estimate_typ_parameter_size(dcm::DeepCompartmentModel{<:UniversalDiffEq, <:HybridModel}, ::Population, args...) = 
    dcm.model.num_latent

function DeepCompartmentModels.predict(dcm::DeepCompartmentModel{<:UniversalDiffEq,<:HybridModel}, data, ps, st; individual = true, target = true, kwargs...)
    if individual
        ps_local = ps
    else
        _keys = filter(!∈([:omega, :phi]), keys(ps))
        ps_local = ps[_keys]
    end
    
    if target
        return solve_for_target(dcm, data, ps, st; kwargs...)
    else
        return solve(dcm, data, ps, st; kwargs...)
    end
end