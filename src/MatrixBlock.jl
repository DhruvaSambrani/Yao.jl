export MatrixBlock

"""
    MatrixBlock{N, T} <: AbstractBlock

abstract type that all block with a matrix form will subtype from.
"""
abstract type MatrixBlock{N, T} <: AbstractBlock end

"""
    nqubits(::Type{MT}) -> Int
    nqubits(::MatrixBlock) -> Int

Return the number of qubits of a `MatrixBlock`.
"""
YaoBase.nqubits(::Type{MT}) where {N, MT <: MatrixBlock{N}} = N
YaoBase.nqubits(::MatrixBlock{N}) where N = N

# Traits
YaoBase.isunitary(x::MatrixBlock) = isunitary(mat(x))
#isunitary(::Type{X}) where {X <: MatrixBlock} = isunitary(mat(X))

YaoBase.isreflexive(x::MatrixBlock) = isreflexive(mat(x))
#isreflexive(::Type{X}) where {X <: MatrixBlock} = isreflexive(mat(X))

YaoBase.ishermitian(x::MatrixBlock) = ishermitian(mat(x))
#ishermitian(::Type{X}) where {X <: MatrixBlock} = ishermitian(mat(X))

_default_iscommute(op1, op2) = length(intersect(usedbits(op1), usedbits(op2))) == 0 || iscommute(mat(op1), mat(op2))
YaoBase.iscommute(op1::MatrixBlock{N}, op2::MatrixBlock{N}) where N = _default_iscommute(op1, op2)

function apply!(reg::AbstractRegister, b::MatrixBlock)
    reg.state .= mat(b) * reg
    reg
end

"""
    datatype(x) -> DataType

Returns the data type of x.
"""
datatype(block::MatrixBlock{N, T}) where {N, T} = T

"""all blocks are matrix blocks"""
_allmatblock(blocks) = all(b->b isa MatrixBlock, blocks)
"""promote types of blocks"""
_blockpromote(blocks) = promote_type([each isa MatrixBlock ? datatype(each) : Bool for each in blocks]...)

"""
    addrs(block::AbstractBlock) -> Vector{Int}

Occupied addresses (include control bits and bits occupied by blocks), fall back to all bits if this method is not provided.
"""
usedbits(block::MatrixBlock{N}) where N = collect(1:N)

include("Primitive.jl")
include("Container.jl")
include("Composite.jl")
