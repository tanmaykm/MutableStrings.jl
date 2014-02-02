module MutableStrings

import Base.convert, Base.promote_rule, Base.endof, Base.getindex, Base.setindex!, Base.sizeof, Base.search, Base.rsearch, Base.string, Base.print, Base.write, Base.map!, Base.reverse!, Base.matchall, Base.next, Base.length, Base.isvalid

export MutableASCIIString, MutableUTF8String, MutableString, uppercase!, lowercase!, replace!, map!, ucfirst!, lcfirst!, reverse!, matchall, search, rsearch, getindex, setindex!
export convert, promote_rule, next, length, endof, sizeof, isvalid, string

immutable MutableASCIIString <: DirectIndexString
    data::Array{Uint8,1}
end

immutable MutableUTF8String <: String
    data::Array{Uint8,1}
end

typealias MutableString Union(MutableASCIIString, MutableUTF8String)

sizeof{T<:MutableString}(s::T) = sizeof(s.data)

matchall(re::Regex, str::MutableString, overlap::Bool=false) = matchall(re, convert(UTF8String, str), overlap)

replace!(s::MutableString, pat, r) = replace!(s, pat, r, 0)

# won't be required if MutableASCIIString is made part of ByteString
search(str::MutableString, re::Regex) = search(str, re, 1)
function search(str::MutableString, re::Regex, idx::Integer)
    if idx > nextind(str,endof(str))
        throw(BoundsError())
    end
    opts = re.options & Base.PCRE.EXECUTE_MASK
    Base.compile(re)
    m, n = exec(re.regex, re.extra, str, idx-1, opts, true)
    isempty(m) ? (0:-1) : ((m[1]+1):prevind(str,m[2]+1))
end

# won't be required if MutableASCIIString is made part of ByteString
exec(regex::Ptr{Void}, extra::Ptr{Void}, str::MutableString, offset::Integer, options::Integer, cap::Bool) = exec(regex, extra, str, 0, offset, sizeof(str), options, cap)

function exec(regex::Ptr{Void}, extra::Ptr{Void}, str::MutableString, shift::Integer, offset::Integer, len::Integer, options::Integer, cap::Bool)
    if offset < 0 || len < offset || len+shift > sizeof(str)
        error(BoundsError)
    end
    ncap = Base.PCRE.info(regex, extra, Base.PCRE.INFO_CAPTURECOUNT, Int32)
    ovec = Array(Int32, 3(ncap+1))
    n = ccall((:pcre_exec, :libpcre), Int32,
              (Ptr{Void}, Ptr{Void}, Ptr{Uint8}, Int32, Int32, Int32, Ptr{Int32}, Int32),
              regex, extra, pointer(str.data,shift+1), len, offset, options, ovec, length(ovec))
    if n < -1
        error("error $n")
    end
    cap ? ((n > -1 ? ovec[1:2(ncap+1)] : Array(Int32,0)), ncap) : n > -1
end


print{T <: MutableString}(io::IO, s::T) = (write(io, s);nothing)
write{T <: MutableString}(io::IO, s::T) = write(io, s.data)

convert(::Type{UTF8String},         s::MutableASCIIString) = UTF8String(s.data)
convert(::Type{ASCIIString},        s::MutableASCIIString) = ASCIIString(s.data)
convert(::Type{MutableASCIIString}, s::ASCIIString)        = MutableASCIIString(copy(s.data))
convert(::Type{MutableASCIIString}, s::UTF8String)         = convert(MutableASCIIString, copy(s.data))
convert(::Type{MutableASCIIString}, a::Array{Uint8,1})     = is_valid_ascii(a) ? MutableASCIIString(a) : error("invalid ASCII sequence")
convert(::Type{MutableASCIIString}, s::MutableASCIIString) = s
convert(::Type{MutableASCIIString}, s::String)             = convert(MutableASCIIString, bytestring(s))

convert(::Type{UTF8String},         s::MutableUTF8String)  = UTF8String(s.data)
convert(::Type{MutableUTF8String},  s::ByteString)         = MutableUTF8String(copy(s.data))
convert(::Type{MutableUTF8String},  a::Array{Uint8,1})     = is_valid_utf8(a) ? MutableUTF8String(a) : error("invalid UTF8 sequence")
convert(::Type{MutableUTF8String},  s::MutableUTF8String)  = s
convert(::Type{MutableUTF8String},  s::String)             = convert(MutableUTF8String, bytestring(s))

promote_rule(::Type{UTF8String},  ::Type{MutableUTF8String})  = UTF8String
promote_rule(::Type{UTF8String},  ::Type{MutableASCIIString}) = UTF8String
promote_rule(::Type{ASCIIString}, ::Type{MutableASCIIString}) = ASCIIString

include("mutable_ascii.jl")
include("mutable_utf8.jl")

end

