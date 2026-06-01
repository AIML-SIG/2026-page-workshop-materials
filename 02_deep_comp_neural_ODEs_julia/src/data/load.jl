import CSV

using DataFrames

function load_data(::Type{T}=Float32; covariates=[:wt, :age, :sex, :crcl]) where T
    df = DataFrame(CSV.File("/workspaces/2026-page-workshop-materials/00_data/tobr-simulation.csv"))
    df_group = groupby(df, :subject)

    indvs = Vector{AbstractIndividual}(undef, length(df_group))
    for (i, subject) in enumerate(df_group)
        x = Vector(subject[1, covariates])
        ty = subject[iszero.(subject.mdv), [:time, :dv]]
        a = Matrix(subject[isone.(subject.mdv), [:time, :amt, :rate, :duration]])
        cb = generate_dosing_callback(a, T)
        indvs[i] = Individual("subject_$(subject[1, :subject])", x, ty.time, ty.dv, cb, T)
    end

    return Population(indvs)
end