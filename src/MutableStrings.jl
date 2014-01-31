module MutableStrings

import Base.convert, Base.promote_rule, Base.endof, Base.getindex, Base.setindex!, Base.sizeof, Base.search, Base.rsearch, Base.string, Base.print, Base.write, Base.map!, Base.reverse!, Base.matchall, Base.next, Base.length

export MutableASCIIString, MutableUTF8String, MutableString, uppercase!, lowercase!, replace!, map!, ucfirst!, lcfirst!, reverse!, matchall, search, rsearch, getindex, setindex!
export convert, promote_rule, next, length

immutable MutableASCIIString <: DirectIndexString
    data::Array{Uint8,1}
end

immutable MutableUTF8String <: String
    data::Array{Uint8,1}
end

typealias MutableString Union(MutableASCIIString, MutableUTF8String)

sizeof(s::MutableString) = sizeof(s.data)

convert(::Type{UTF8String},         s::MutableUTF8String)  = UTF8String(s.data)
convert(::Type{UTF8String},         s::MutableASCIIString) = UTF8String(s.data)
convert(::Type{ASCIIString},        s::MutableASCIIString) = ASCIIString(s.data)
convert(::Type{MutableASCIIString}, s::ASCIIString)        = MutableASCIIString(copy(s.data))
convert(::Type{MutableASCIIString}, s::UTF8String)         = convert(MutableASCIIString, copy(s.data))
convert(::Type{MutableASCIIString}, a::Array{Uint8,1})     = is_valid_ascii(a) ? MutableASCIIString(a) : error("invalid ASCII sequence")
convert(::Type{MutableASCIIString}, s::MutableASCIIString) = s
convert(::Type{MutableASCIIString}, s::String)             = convert(MutableASCIIString, bytestring(s))

promote_rule(::Type{UTF8String},  ::Type{MutableUTF8String})  = UTF8String
promote_rule(::Type{UTF8String},  ::Type{MutableASCIIString}) = UTF8String
promote_rule(::Type{ASCIIString}, ::Type{MutableASCIIString}) = ASCIIString

include("mutable_ascii.jl")
include("mutable_utf8.jl")

end

