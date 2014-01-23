module MutableStrings

import Base.convert, Base.promote, Base.endof, Base.getindex, Base.sizeof, Base.search, Base.rsearch, Base.string, Base.print, Base.write, Base.map!, Base.reverse!, Base.matchall

export MutableASCIIString, MutableString, uppercase!, lowercase!, replace!, map!, ucfirst!, lcfirst!, reverse!, matchall
export convert, promote

type MutableASCIIString <: DirectIndexString
    data::Array{Uint8,1}
end

type MutableUTF8String <: String
    data::Array{Uint8,1}
end

typealias MutableString Union(MutableASCIIString, MutableUTF8String)

endof(s::MutableASCIIString) = length(s.data)
getindex(s::MutableASCIIString, i::Int) = (x=s.data[i]; x < 0x80 ? char(x) : '\ufffd')

sizeof(s::MutableASCIIString) = sizeof(s.data)

getindex(s::MutableASCIIString, r::Vector) = ASCIIString(getindex(s.data,r))
getindex(s::MutableASCIIString, r::Range1{Int}) = ASCIIString(getindex(s.data,r))
getindex(s::MutableASCIIString, indx::AbstractVector{Int}) = ASCIIString(s.data[indx])
search(s::MutableASCIIString, c::Char, i::Integer) = c < 0x80 ? search(s.data,uint8(c),i) : 0
rsearch(s::MutableASCIIString, c::Char, i::Integer) = c < 0x80 ? rsearch(s.data,uint8(c),i) : 0

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
    for i = 1:length(d)
        if 'A' <= d[i] <= 'Z'
            d[i] += 32
        end
    end
end

function reverse!(s::MutableASCIIString) 
    reverse!(s.data)
end

print(io::IO, s::MutableASCIIString) = (write(io, s);nothing)
write(io::IO, s::MutableASCIIString) = write(io, s.data)

function replace!(str::MutableASCIIString, pattern, repl::Function, limit::Integer=0) 
    n = 1
    e = endof(str)
    r = search(str,pattern,1)
    j, k = first(r), last(r)
    while j != 0
        repl(str.data, r)
        r = search(str, pattern, k+1)
        j, k = first(r), last(r)
        n == limit && break
        n += 1
    end
end

function map!(f, s::MutableASCIIString)
    d = s.data
    for i = 1:length(d)
        d[i] = convert(Uint8, f(d[i]))
    end
end

matchall(re::Regex, str::MutableASCIIString, overlap::Bool=false) = matchall(re, convert(ASCIIString, str), overlap)

convert(::Type{UTF8String}, s::MutableUTF8String) = UTF8String(s.data)
convert(::Type{UTF8String}, s::MutableASCIIString) = UTF8String(s.data)
convert(::Type{ASCIIString}, s::MutableASCIIString) = ASCIIString(s.data)
convert(::Type{MutableASCIIString}, s::ASCIIString) = MutableASCIIString(copy(s.data))
convert(::Type{MutableASCIIString}, s::UTF8String) = convert(MutableASCIIString, s.data)
convert(::Type{MutableASCIIString}, a::Array{Uint8,1}) = is_valid_ascii(a) ? MutableASCIIString(a) : error("invalid ASCII sequence")
convert(::Type{MutableASCIIString}, s::String) = convert(MutableASCIIString, bytestring(s))

promote_rule(::Type{UTF8String} , ::Type{MutableUTF8String}) = UTF8String
promote_rule(::Type{UTF8String} , ::Type{MutableASCIIString}) = UTF8String
promote_rule(::Type{ASCIIString} , ::Type{MutableASCIIString}) = ASCIIString

end

