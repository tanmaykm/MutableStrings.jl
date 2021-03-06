endof(s::MutableASCIIString) = length(s.data)
getindex(s::MutableASCIIString, i::Int) = (x=s.data[i]; x < 0x80 ? char(x) : '\ufffd')

getindex(s::MutableASCIIString, r::Vector) = ASCIIString(getindex(s.data,r))
getindex(s::MutableASCIIString, r::UnitRange{Int}) = ASCIIString(getindex(s.data,r))
getindex(s::MutableASCIIString, indx::AbstractVector{Int}) = ASCIIString(s.data[indx])

setindex!(s::MutableASCIIString, x, i0::Real) = (s.data[i0] = x)
setindex!(s::MutableASCIIString, r::ASCIIString, I::UnitRange) = (s.data[I] = r.data)
setindex!(s::MutableASCIIString, c::Char, I::UnitRange) = (s.data[I] = uint8(c))

search(s::MutableASCIIString, c::Char, i::Integer) = c < 0x80 ? search(s.data,uint8(c),i) : 0
rsearch(s::MutableASCIIString, c::Char, i::Integer) = c < 0x80 ? rsearch(s.data,uint8(c),i) : 0

string(c::MutableASCIIString) = c
function string(c::MutableASCIIString...)
    n = 0
    for s in c
        n += length(s.data)
    end
    v = Array(Uint8,n)
    o = 1
    for s in c
        ls = length(s.data)
        unsafe_copy!(v, o, s.data, 1, ls)
        o += ls
    end
    MutableASCIIString(v)
end

function ucfirst!(s::MutableASCIIString)
    if length(s) > 0 && 'a' <= s[1] <= 'z'
        s.data[1] -= 32
    end
    nothing
end
function lcfirst!(s::MutableASCIIString)
    if length(s) > 0 && 'A' <= s[1] <= 'Z'
        s.data[1] += 32
    end
    nothing
end

function uppercase!(s::MutableASCIIString)
    d = s.data
    for i = 1:length(d)
        if 'a' <= d[i] <= 'z'
            d[i] -= 32
        end
    end
end

function lowercase!(s::MutableASCIIString)
    d = s.data
    const l::Int = length(d)
    for i = 1:l
        if 'A' <= d[i] <= 'Z'
            d[i] += 32
        end
    end
end

reverse!(s::MutableASCIIString) = reverse!(s.data)

function _splice!{T<:Integer}(a::Vector, r::UnitRange{T}, ins::AbstractArray=Base._default_splice, m::Int=length(ins))
    #m = length(ins)
    if m == 0
        deleteat!(a, r)
        return
    end

    n = length(a)
    f = first(r)
    l = last(r)
    d = length(r)

    if m < d
        delta = d - m
        if f-1 < n-l
            Base._deleteat_beg!(a, f, delta)
        else
            Base._deleteat_end!(a, l-delta+1, delta)
        end
    elseif m > d
        delta = m - d
        if f-1 < n-l
            Base._growat_beg!(a, f, delta)
        else
            Base._growat_end!(a, l+1, delta)
        end
    end

    for k = 1:m
        a[f+k-1] = ins[k]
    end
end

function replace!{T}(str::MutableASCIIString, pattern::T, repl::Union(Function,ASCIIString,Char), limit::Integer=0) 
    n = 1
    es = endof(str)
    r = search(str,pattern,1)
    j, k = first(r), last(r)
    while j != 0
        rv::Union(ASCIIString,Char) = isa(repl, Function) ? repl(SubString(str, j, k)) : repl
        if isa(rv, ASCIIString)
            _splice!(str.data, r, rv.data)
            lrv = length(rv)
            lr = length(r)
            if lrv != lr
                k = j+lrv
                es = es - lr + lrv
            end
        else
            str[r] = rv
        end
        ((k+1) > es) && break
        r = search(str, pattern, k+1)
        j, k = first(r), last(r)
        n == limit && break
        n += 1
    end
end

function replace!(str::MutableASCIIString, re::Regex, repl::Union(Function,ASCIIString,Char), limit::Integer=0) 
    regex = Base.compile(re).regex
    extra = re.extra
    n = length(str.data)
    offset = int32(0)
    opts = re.options & Base.PCRE.EXECUTE_MASK
    opts_nonempty = opts | Base.PCRE.ANCHORED | Base.PCRE.NOTEMPTY_ATSTART
    prevempty = false
    ovec = Array(Int32, 3)
    n_repl = 1
    while true
        result = ccall((:pcre_exec, :libpcre), Int32,
                       (Ptr{Void}, Ptr{Void}, Ptr{Uint8}, Int32,
                       Int32, Int32, Ptr{Int32}, Int32),
                       regex, extra, str.data, n,
                       offset, prevempty ? opts_nonempty : opts, ovec, 3)

        if result < 0
            if prevempty && offset < n
                offset = int32(nextind(str, offset + 1) - 1)
                prevempty = false
                continue
            else
                break
            end
        end

        rv::Union(ASCIIString,Char) = isa(repl, Function) ? repl(SubString(str, ovec[1]+1, ovec[2])) : repl
        r = (ovec[1]+1):(ovec[2])
        if isa(rv, ASCIIString)
            _splice!(str.data, r, rv.data)
            
            lrv = length(rv)
            lr = length(r)
            if lrv != lr
                n = n - lr + lrv
            end

            prevempty = offset == ovec[2]
            offset = ovec[1]+1+lrv
        else
            str[r] = rv
            prevempty = offset == ovec[2]
            offset = ovec[2]
        end
        n_repl == limit && break
        n_repl += 1
    end
    nothing
end

function map!(f, s::MutableASCIIString)
    d = s.data
    for i = 1:length(d)
        d[i] = convert(Uint8, f(d[i]))
    end
end


