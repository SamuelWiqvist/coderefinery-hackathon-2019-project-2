# the non-linear time-series model
σ_u = sqrt(10)
σ_v = sqrt(1)

θ_true = [σ_u;σ_v]

# Step function for the state model
state_model_step(x_old::Real, t::Real) = x_old/2 + 25*(x_old)/(1+x_old^2) + 8*cos(1.2*t) + σ_u*randn()
state_model_step(x_old::Real, t::Real, σ_u::Real) = x_old/2 + 25*(x_old)/(1+x_old^2) + 8*cos(1.2*t) + σ_u*randn()

# Step function for the obs model
obs_model_sample(x::Real) = x^2/20 + σ_v*randn()
obs_model_pred(x::Real) = x^2/20

# naive function to generate data
function generate_data_naive(T::Int)

    x = zeros(T)
    y = zeros(T)

    x[1] = sqrt(10)*randn()
    y[1] = obs_model_sample(x[1])

    for t in 2:T

        x[t] = state_model_step(x[t-1], t)
        y[t] = obs_model_sample(x[t])

    end

    return x,y


end
