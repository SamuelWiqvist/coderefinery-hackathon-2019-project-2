include(pwd()*"/non-linear-time-series-model/model.jl")

using PyPlot

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
