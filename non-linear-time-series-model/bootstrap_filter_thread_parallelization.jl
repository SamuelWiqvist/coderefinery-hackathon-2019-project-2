include(pwd()*"/non-linear-time-series-model/model.jl")

#using PyPlot
using Random
using Statistics
using Printf

# generate some data from the non-linear model
Random.seed!(42) # fix
x,y = generate_data_naive(100)

# naive bootstrap filter
function bootstrap_naive(y::Vector, N::Int, θ::Vector, save_paths::Bool=false)

    # pre-allocation

    if mod(N, Threads.nthreads()) != 0
        error("We must have that mod(N, Threads.nthreads()) == 0")
    end

    n_threads = Threads.nthreads()
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
            state_prop!(x, t, σ_u, n_threads)

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

    Threads.@threads for i = 1:length(x) # multi thread this!
        x[i] = state_model_step(x[i], t, σ_u)
    end

end


# state prop function (using (naive) looping)
function state_prop!(x::Vector, t::Real, σ_u::Real, n_threads::Int)


    if n_threads == 1

        state_prop!(x, t, σ_u)

    else

        idx = reshape(1:length(x), div(length(x), n_threads), n_threads)

        for j in 1:n_threads
            x[idx[:,j]] = _state_prop(x[idx[:,j]], t, σ_u)
        end

    end

end

function _state_prop(x::Vector, t::Real, σ_u::Real)

    x_new =  zeros(size(x))

    for i = 1:length(x) # multi thread this!
        x_new[i] = state_model_step(x[i], t, σ_u)
    end

    return x_new


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
loglik, x_paths = @time bootstrap_naive(y, N, θ_true, true)



N = 1200
nbr_loglik_est = 500

loglik_vec = zeros(nbr_loglik_est)
run_times = zeros(nbr_loglik_est)

for i in 1:nbr_loglik_est
    run_times[i] = @elapsed ll1 =  bootstrap_naive(y, N, θ_true, false)
end

@printf "----------------\n"
@printf "Test thread-parallel bootstrap filter \n"
@printf "Nbr threads:  %.2f\n" Threads.nthreads()
@printf "Nbr particles: %.2f\n" N
@printf "Runtime: %.4f\n" mean(run_times)
