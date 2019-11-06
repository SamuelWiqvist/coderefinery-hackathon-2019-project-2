include(pwd()*"/non-linear-time-series-model/model.jl")

using LinearAlgebra
using StaticArrays
using BenchmarkTools
using Random
using PyPlot
using Printf
using Statistics


nbr_samples = 10


# loop based state prop function
function state_prop!(x::Vector, t::Real)

    for i = 1:length(x)
        x[i] = state_model_step(x[i], t)
    end

end

# test runs
x = randn(nbr_samples)
state_prop!(x,1)
state_prop!(x,1)

x


function state_prop!(x::Array, t::Real, σ_u::Real)

    for i = 1:length(x)
        x[i] = state_model_step(x[i], t, σ_u)
    end

end

function state_prop!(x::MVector, t::Real)

    for i = 1:length(x)
        x[i] = state_model_step(x[i], t)
    end

end

function state_prop(x::SVector, t::Real)

    return x/2 + 25*x./(1+x.^2) .+ 8*cos(1.2*t) + σ_u*noise

end



function state_prop(x::SVector, t::Real)

    x = x/2 + 25*x./(1+x.^2) .+ 8*cos(1.2*t)
    return map(x -> σ_u*rand(), x)

end


# test runs
x = randn(nbr_samples,1)
@code_lowered  state_prop!(x,1)
@code_native  state_prop!(x,1)

x

x = @MVector randn(nbr_samples)
state_prop!(x,1)
x

x = @SVector randn(nbr_samples)
@btime state_prop(x,1)
x

# map based state prop function
function state_prop_map!(x::Array, t::Real)

    map!(x -> state_model_step(x, t), x, x)

end


function state_prop_map!(x::MVector, t::Real)

    map!(x -> state_model_step(x, t), x, x)

end

function state_prop_vector(x::SVector, t::Real)

    return map(x -> state_model_step(x, t), x)

end


# test runs
x = @MVector randn(nbr_samples)
state_prop_map!(x,1)
x

x = randn(nbr_samples,1)
state_prop_map!(x,1)
x


x = @SVector randn(nbr_samples)
x = @code_lowered state_prop_vector(x, 1)



for nbr_samples in [10,20,50]

    julia_naive_bm_res = @benchmark state_prop!(x,1) setup=(x=rand(nbr_samples,1))
    julia_mvector_loop_bm_res = @benchmark state_prop!(x,1) setup=(x= @MVector rand(nbr_samples))
    julia_svector_vector_bm_res = @benchmark state_prop(x,1) setup=(x= @SVector rand(nbr_samples))

    julia_mvector_map_bm_res = @benchmark state_prop_map!(x,1) setup=(x= @MVector rand(nbr_samples))
    julia_naive_map_bm_res = @benchmark state_prop_map!(x,1) setup=(x= rand(nbr_samples,1))
    julia_static_map_bm_res = @benchmark state_prop_map(x,1) setup=(x= @SVector rand(nbr_samples))

    @printf("Benchmark results for %.0f particles\n", nbr_samples)

    @printf("Julia naive loop [0.25, 0.5, 0.75] quantile: [%.1f,%.1f,%.1f]\n", quantile(julia_naive_bm_res.times, [0.25, 0.5, 0.75])...)
    @printf("Julia MVector loop [0.25, 0.5, 0.75] quantile: [%.1f,%.1f,%.1f]\n", quantile(julia_mvector_loop_bm_res.times, [0.25, 0.5, 0.75])...)
    @printf("Julia MVector loop [0.25, 0.5, 0.75] quantile: [%.1f,%.1f,%.1f]\n", quantile(julia_svector_vector_bm_res.times, [0.25, 0.5, 0.75])...)

    @printf("Julia naive map! [0.25, 0.5, 0.75] quantile: [%.1f,%.1f,%.1f]\n", quantile(julia_mvector_map_bm_res.times, [0.25, 0.5, 0.75])...)
    @printf("Julia MVector map! [0.25, 0.5, 0.75] quantile: [%.1f,%.1f,%.1f]\n", quantile(julia_naive_map_bm_res.times, [0.25, 0.5, 0.75])...)
    @printf("Julia SVector vectorized [0.25, 0.5, 0.75] quantile: [%.1f,%.1f,%.1f]\n", quantile(julia_static_vector_bm_res.times, [0.25, 0.5, 0.75])...)

end

nbr_samples = 20

julia_naive_bm_res = @benchmark state_prop!(x,1) setup=(x=rand(nbr_samples))
julia_mvector_loop_bm_res = @benchmark state_prop!(x,1) setup=(x= @MVector rand(nbr_samples))
julia_svector_vector_bm_res = @benchmark state_prop(x,1) setup=(x= @SVector rand(nbr_samples))

julia_mvector_map_bm_res = @benchmark state_prop_map!(x,1) setup=(x= @MVector rand(nbr_samples))
julia_naive_map_bm_res = @benchmark state_prop_map!(x,1) setup=(x= rand(nbr_samples,1))
julia_static_map_bm_res = @benchmark state_prop_map(x,1) setup=(x= @SVector rand(nbr_samples))


julia_naive_bm_res.times/1000

julia_static_vector_bm_res.times

bm_res = zeros(10000,6)
bm_res[:,1] = julia_naive_bm_res.times/1000
bm_res[:,2] = julia_mvector_loop_bm_res.times/1000
bm_res[:,2] = julia_svector_vector_bm_res.times/1000
bm_res[:,3] = julia_mvector_map_bm_res.times/1000
bm_res[:,4] = julia_naive_map_bm_res.times/1000
bm_res[:,6] = julia_static_vector_bm_res.times/1000

PyPlot.figure()
PyPlot.boxplot(bm_res)
PyPlot.title(nbr_samples)



v = @SVector randn(5)

function test(v::SVector)

    return NaN

end

m4 = @SMatrix randn(4,4)

@btime inv(m4)

@benchmark  inv(x) setup=(x= @SMatrix randn(4,4))



m5 = randn(4,4)

@btime inv(m5)

@benchmark  inv(x) setup=(x= randn(4,4))
