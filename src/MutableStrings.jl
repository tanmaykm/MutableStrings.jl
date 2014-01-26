module MutableStrings

import Base.convert, Base.promote, Base.endof, Base.getindex, Base.sizeof, Base.search, Base.rsearch, Base.string, Base.print, Base.write, Base.map!, Base.reverse!, Base.matchall

export MutableASCIIString, MutableString, uppercase!, lowercase!, replace!, replaceall!, map!, ucfirst!, lcfirst!, reverse!, matchall, search, rsearch
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

# won't be required if MutableASCIIString is made part of ByteString
#const ovec = Array(Int32, 30)
search(str::MutableASCIIString, re::Regex) = search(str, re, 1)
function search(str::MutableASCIIString, re::Regex, idx::Integer)
    if idx > nextind(str,endof(str))
        throw(BoundsError())
    end
    opts = re.options & Base.PCRE.EXECUTE_MASK
    Base.compile(re)
    m, n = mexec(re.regex, re.extra, str, idx-1, opts, true)
    #m = ovec
    isempty(m) ? (0:-1) : ((m[1]+1):prevind(str,m[2]+1))
end

# won't be required if MutableASCIIString is made part of ByteString
mexec(regex::Ptr{Void}, extra::Ptr{Void}, str::MutableASCIIString, offset::Integer, options::Integer, cap::Bool) =
    mexec(regex, extra, str, 0, offset, sizeof(str), options, cap)

function mexec(regex::Ptr{Void}, extra::Ptr{Void},
              str::MutableASCIIString, shift::Integer, offset::Integer, len::Integer, options::Integer, cap::Bool)
    if offset < 0 || len < offset || len+shift > sizeof(str)
        error(BoundsError)
    end
    ncap = Base.PCRE.info(regex, extra, Base.PCRE.INFO_CAPTURECOUNT, Int32)
    #println("ncap = $ncap")
    ovec = Array(Int32, 3(ncap+1))
    n = ccall((:pcre_exec, :libpcre), Int32,
              (Ptr{Void}, Ptr{Void}, Ptr{Uint8}, Int32,
               Int32, Int32, Ptr{Int32}, Int32),
              regex, extra, pointer(str.data,shift+1), len,
              offset, options, ovec, length(ovec))
              #offset, options, ovec, 3(ncap+1))
    if n < -1
        error("error $n")
    end
    cap ? ((n > -1 ? ovec[1:2(ncap+1)] : Array(Int32,0)), ncap) : n > -1
    #cap ? ncap : (n > -1)
end



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

function replace!{T}(str::MutableASCIIString, pattern::T, repl::Function, limit::Integer=0) 
    n = 1
    e = endof(str)
    #println("end: $e")
    #astr = convert(UTF8String, str)
    #r = search(astr,pattern,1)
    r = search(str,pattern,1)
    j, k = first(r), last(r)
    while j != 0
        #println("j: $j, k: $k")
        repl(str.data, r)
        #r = search(astr, pattern, k+1)
        ((k+1) > e) && break
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

matchall(re::Regex, str::MutableASCIIString, overlap::Bool=false) = matchall(re, convert(UTF8String, str), overlap)

function replace!(str::MutableASCIIString, re::Regex, repl::Function, limit::Integer=0) 
    regex = Base.compile(re).regex
    extra = re.extra
    n = length(str.data)
    #matches = SubString{UTF8String}[]
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

        #push!(matches, SubString(str, ovec[1]+1, ovec[2]))
        #str.data[ovec[1]+1, ovec[2]] = replace_char
        repl(str.data, (ovec[1]+1):ovec[2])
        prevempty = offset == ovec[2]
        #if overlap
        #    if !prevempty
        #        offset = int32(nextind(str, offset + 1) - 1)
        #    end
        #else
        offset = ovec[2]
        #end
        n_repl == limit && break
        n_repl += 1
    end
    nothing
end


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

