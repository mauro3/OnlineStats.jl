"""
```julia
Bootstrap(s::Series, nreps, d, f = value)
```

Online Statistical Bootstrapping.

Create `nreps` replicates of the OnlineStat in Series `s`.  When `fit!` is called,
each of the replicates will be updated `rand(d)` times.  Standard choices for `d` are `Distributions.Poisson()`, `[0, 2]`, etc.  `value(b)` returns `f` mapped to the replicates.

### Example
```julia
b = Bootstrap(Series(Mean()), 100, [0, 2])
fit!(b, randn(1000))
value(b)        # `f` mapped to replicates
mean(value(b))  # mean
```
"""
mutable struct Bootstrap{I, D, O <: OnlineStat{I}, S <: Series{I, O}, F <: Function}
    series::S
    replicates::Vector{O}
    f::F
    d::D
end
function Bootstrap{I, O <:OnlineStat{I}}(s::Series{I, O}, nreps::Integer, d,
                                         f::Function = value)
    o = stats(s)
    replicates = [deepcopy(o) for i in 1:nreps]
    S, F, D = typeof(s), typeof(f), typeof(d)
    Bootstrap{I, D, O, S, F}(s, replicates, f, d)
end
function Base.show(io::IO, b::Bootstrap)
    OnlineStatsBase.header(io, name(b))
    println(io, "    > n replicates : $(length(b.replicates))")
    println(io, "    > function     : $(b.f)")
    println(io, "    > boot method  : $(b.d)")
    show(io, b.series)
end
value(b::Bootstrap) = b.f.(b.replicates)

"""
```julia
replicates(b)
```
Return the vector of replicates from Bootstrap `b`
"""
replicates(b::Bootstrap) = b.replicates

"""
```julia
confint(b, coverageprob = .95)
```
Return a confidence interval for a Bootstrap `b`.
"""
function confint(b::Bootstrap, coverageprob = 0.95, method = :quantile)
    states = value(b)
    # If any NaN, return NaN, NaN
    if any(isnan, states)
        return (NaN, NaN)
    else
        α = 1 - coverageprob
        return (quantile(states, α / 2), quantile(states, 1 - α / 2))
    end
end

#-----------------------------------------------------------------------# fit!
function fit_replicates!(b::Bootstrap, yi)
    γ = weight(b.series)
    for r in b.replicates
        for _ in 1:rand(b.d)
            fit!(r, yi, γ)
        end
    end
end
#-----------------------------------------------------------------------# Input: 0
function fit!(b::Bootstrap{0}, y::Real)
    fit!(b.series, y)
    fit_replicates!(b, y)
    b
end
function fit!(b::Bootstrap{0}, y::AVec)
    for yi in y
        fit!(b, yi)
    end
    b
end
#-----------------------------------------------------------------------# Input: 1
function fit!(b::Bootstrap{1}, y::AVec)
    fit!(b.series, y)
    fit_replicates!(b, y)
end
function fit!(b::Bootstrap{1}, y::AMat)
    for i in 1:size(y, 1)
        fit!(b, view(y, i, :))
    end
    b
end
