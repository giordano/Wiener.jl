
using NumberTheoreticTransforms

export fermat

"""
    fermat(convolved, h, g, q)

Calculates deconvolution with Number Theoretic Transform.
"""
function fermat(convolved::AbstractArray{T, 1}, h::AbstractArray{T, 1}, g::T, q::T) where {T<:Integer}
    N = length(convolved)
    bias = div(q-1, 2) + 1 #negative numbers are represeted by the upper half of [0, q) range
    H = fnt(h, g, q)
    H_inv = invmod.(H, q)
    D = fft(h) |> prod |> real |> T #TODO: avoid floats
    Dm = mod(D, q)
    xm = ifnt(H_inv .* fnt(convolved, g, q), g, q)
    x0 = mod.(Dm * xm, q)
    x0[x0 .>= bias] .-= q
    x = x0
    y_prim = fft(h) .* fft(x0) |> ifft .|> real .|> round.|> T #TODO: avoid floats
    @assert all(iszero, rem.(convolved * D - y_prim, q))
    y = div.(convolved * D - y_prim, q)
    ym = mod.(y, q)
    j = 1
    while !all(iszero, y)
        xj = ifnt(H_inv .* fnt(ym, g, q), g, q)
        xj[xj .>= bias] .-= q
        x = x .+ (xj * q^j)
        y_prim = fft(h) .* fft(xj) |> ifft .|> real .|> round .|> T #TODO: avoid floats
        @assert all(iszero, rem.(y - y_prim, q))
        y = div.(y - y_prim, q)
        ym = mod.(y, q)
        j = j + 1
    end

    return x // D
end