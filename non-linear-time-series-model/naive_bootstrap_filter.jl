include(pwd()*"/non-linear-time-series-model/model.jl")

using PyPlot
using Random
using Statistics
using BenchmarkTools

# generate some data from the non-linear model
Random.seed!(42) # fix
x,y = generate_data_naive(100)

# Plot data
PyPlot.figure(figsize=(15,7))
PyPlot.subplot(211)
PyPlot.plot(x)
PyPlot.ylabel("x_t")
PyPlot.subplot(212)
PyPlot.plot(y)
PyPlot.ylabel("y_t")
PyPlot.xlabel("t")


# naive bootstrap filter
function bootstrap_naive(y::Vector, N::Int, θ::Vector, save_paths::Bool=false)

    # pre-allocation

    loglik = 0.

    T = length(y) # timesteps

    x = zeros(N) # particels
    w = zeros(N) # weigts
    u_resample_calc = rand(N) # random numbers for resampling

    if save_paths
        x_paths = zeros(N,T)
    end

    σ_u, σ_v = θ

    # set start values
    x = zeros(N) + sqrt(10)*randn(N)

    for t in 1:T

        if t == 1 # first iteration

            # do nothing

        else

            # resample particels using systematic resampling
            ind = sysresample2(w, N, u_resample_calc[t])
            x[:] = x[ind]

            # propagate particels
            state_prop!(x, t, σ_u)

        end

        if save_paths
            x_paths[:,t] = x
        end

        # calc weigths and update loglik
        loglik = loglik + calc_weigths(w, x, y[t], σ_v, N)

    end

    save_paths == true ? (return loglik, x_paths) : (return loglik)


end

# naive help functions for the naive bootstrap filter

# state prop function (using (naive) looping)
function state_prop!(x::Vector, t::Real, σ_u::Real)

    for i = 1:length(x) # multi thread this!
        x[i] = state_model_step(x[i], t, σ_u)
    end

end


# calc weigths and update loglik
function calc_weigths(w::Vector, x::Vector, y::Real, σ_v::Real, N::Int)

    # pre-allocate vectors
    logw = zeros(N)
    w_temp = zeros(N)

    # calc w
    for i in 1:N; logw[i] = log_normalpdf(obs_model_pred(x[i]), σ_v, y); end

    # find largets wegith
    constant = maximum(logw)

    # subtract largets weigth
    for i in 1:N; w_temp[i] = exp(logw[i] - constant); end

    # calc sum of weigths
    w_sum = sum(w_temp)

    # normalize weigths
    for i in 1:N; w_temp[i] = w_temp[i]/w_sum; end

    w[:] = w_temp # updated normalized wegiths

    # return loglik
    return constant + log(w_sum) - log(N)


end


# log-normal pdf function (without the normalizing constant)
function log_normalpdf(μ::Real, σ::Real, x::Real)

  return -0.5*(log(σ^2) + (x-μ)^2/σ^2)

end

# Systematic resampling. Code adapted from Andrew Golightly.
function sysresample2(wts::Array,N::Int64,uni::Real)

  vec = zeros(Int64,N)
  wsum = sum(wts)
  k = 1
  u = uni/N
  wsumtarg = u
  wsumcurr=wts[k]/wsum
  delta = 1/N

  for i = 1:N
    while wsumcurr < wsumtarg
      k = k+1
      wsumcurr=wsumcurr+wts[k]/wsum
    end
    vec[i]=k
    wsumtarg=wsumtarg+delta
  end

  return vec

end

N = 1200 # set nbr particles
loglik, x_paths = @time bootstrap_naive(y, N, [1;0.5], true)

# likelihood at values ture parameter values -181
# likelihood at values other parameter values -23900


PyPlot.figure(figsize=(15,3))
PyPlot.plot(x_paths[:,:]', "r")
PyPlot.plot(x, "g", linewidth=3.0)

# run benchmark
julia_naive_bootstrap_bm_res = @benchmark bootstrap_naive(y, N, θ_true, false)

# find number of particles needed for PMMH

N = 1200
nbr_loglik_est = 500
loglik_vec = zeros(nbr_loglik_est)

for i in 1:nbr_loglik_est
    loglik_vec[i] = bootstrap_naive(y, N, θ_true, false)
end

var(loglik_vec)

# profile naive pf
using Profile

Profile.clear()
@profile bootstrap_naive(y, N, θ_true, false)
Profile.print()
