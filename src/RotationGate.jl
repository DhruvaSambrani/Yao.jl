export RotationGate, Rotor, generator

"""
    RotationGate{N, T, GT <: MatrixBlock{N, Complex{T}}} <: PrimitiveBlock{N, Complex{T}}

RotationGate, with GT both hermitian and isreflexive.
"""
mutable struct RotationGate{N, T, GT <: MatrixBlock{N, Complex{T}}} <: PrimitiveBlock{N, Complex{T}}
    block::GT
    theta::T
    function RotationGate{N, T, GT}(block::GT, theta) where {N, T, GT <: MatrixBlock{N, Complex{T}}}
        ishermitian(block) && isreflexive(block) || throw(ArgumentError("Gate type $GT is not hermitian or not isreflexive!"))
        new{N, T, GT}(block, T(theta))
    end
end
RotationGate(block::GT, theta) where {N, T, GT<:MatrixBlock{N, Complex{T}}} = RotationGate{N, T, GT}(block, theta)

_make_rot_mat(I, block, theta) = I * cos(theta / 2) - im * sin(theta / 2) * block
mat(R::RotationGate{N, T}) where {N, T} = _make_rot_mat(IMatrix{1<<N, Complex{T}}(), mat(R.block), R.theta)
mat(R::RotationGate{N, T, <:Union{XGate, YGate}}) where {N, T} = _make_rot_mat(IMatrix{1<<N, Complex{T}}(), mat(R.block), R.theta) |> Matrix
Base.adjoint(blk::RotationGate) = RotationGate(blk.block, -blk.theta)

function apply!(reg::DenseRegister, rb::RotationGate)
    v0 = copy(reg.state)
    apply!(reg, rb.block)
    reg.state = -im*sin(rb.theta/2)*reg.state + cos(rb.theta/2)*v0
    reg
end

Base.copy(R::RotationGate) = RotationGate(R.block, R.theta)

# parametric interface
niparameters(::Type{<:RotationGate}) = 1
iparameters(x::RotationGate) = x.theta
setiparameters!(r::RotationGate, param::Real) = (r.theta = param; r)

YaoBase.isunitary(r::RotationGate) = true

Base.:(==)(lhs::RotationGate{TA, GTA}, rhs::RotationGate{TB, GTB}) where {TA, TB, GTA, GTB} = false
Base.:(==)(lhs::RotationGate{TA, GT}, rhs::RotationGate{TB, GT}) where {TA, TB, GT} = lhs.theta == rhs.theta

function Base.hash(gate::RotationGate{T, GT}, h::UInt) where {T, GT}
    hashkey = hash(objectid(gate), h)
    hashkey = hash(gate.theta, hashkey)
    hashkey = hash(gate.block, hashkey)
    hashkey
end

cache_key(R::RotationGate) = R.theta

function print_block(io::IO, R::RotationGate)
    print(io, "Rot ", R.block, ": ", R.theta)
end
