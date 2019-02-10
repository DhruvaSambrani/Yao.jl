export TimeEvolution

"""
    TimeEvolution{N, TT, GT} <: PrimitiveBlock{N, ComplexF64}

    TimeEvolution(H::GT, t::TT; tol::Real=1e-7) -> TimeEvolution

TimeEvolution, where GT is block type. input matrix should be hermitian.
"""
mutable struct TimeEvolution{N, TT, GT} <: PrimitiveBlock{N, ComplexF64}
    H::GT
    t::TT
    tol::Float64
    function TimeEvolution{N, TT, GT}(H::GT, t; tol::Real) where {N, TT, GT <: MatrixBlock{N}}
        # we ignore hermitian check here for efficiency!
        #ishermitian(H) || throw(ArgumentError("Gate type $GT is not hermitian!"))
        new{N, TT, GT}(H, TT(t), Float64(tol))
    end
end
TimeEvolution(H::GT, t::TT; tol::Real=1e-7) where {N, TT<:Number, GT<:MatrixBlock{N}} = TimeEvolution{N, TT, GT}(H, t; tol=tol)

mat(te::TimeEvolution{N}) where N = exp(Matrix(-im*te.t*mat(te.H)))

function apply!(reg::DenseRegister, te::TimeEvolution{N}) where N
    st = state(reg)
    Hmat = mat(te.H)
    LinearMap(x->apply!(DenseRegister(x), te.H), size(st, 1))
    for j in 1:size(st, 2)
        st[:,j] .= expmv(-im*te.t, Hmat, st[:,j], tol=te.tol)
    end
    reg
end

Base.adjoint(blk::TimeEvolution) = TimeEvolution(blk.H, -blk.t', tol=blk.tol)
Base.copy(te::TimeEvolution) = TimeEvolution(te.H, te.t, tol=te.tol)

# parametric interface
niparameters(::Type{<:TimeEvolution}) = 1
iparameters(x::TimeEvolution) = x.t
setiparameters!(r::TimeEvolution, param::Real) = (r.t = param; r)

YaoBase.isunitary(te::TimeEvolution) = (ishermitian(te.H) && ishermitian(te.t)) || ishermitian(mat(te.t*te.H))
Base.:(==)(lhs::TimeEvolution, rhs::TimeEvolution) = lhs.H == rhs.H && lhs.t == rhs.t

function Base.hash(gate::TimeEvolution{<:Any, <:Any, GT}, h::UInt) where GT
    hashkey = hash(objectid(gate), h)
    hashkey = hash(gate.t, hashkey)
    hashkey = hash(gate.H, hashkey)
    hashkey
end

cache_key(te::TimeEvolution) = te.t

function print_block(io::IO, te::TimeEvolution)
    print(io, "Time Evolution ", te.H, "Δt = $(te.t), tol = $(te.tol)")
end
