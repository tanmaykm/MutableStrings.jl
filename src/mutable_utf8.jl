endof(s::MutableUTF8String) = endof(utf8(s))

next(s::MutableUTF8String, i::Int) = (s[i], i+1+Base.utf8_trailing[s.data[i]+1])
sizeof(s::MutableUTF8String) = sizeof(s.data)

isvalid(s::MutableUTF8String, i::Integer) = (1 <= i <= endof(s.data)) && Base.is_utf8_start(s.data[i])

length(s::MutableUTF8String) = length(utf8(s))
getindex(s::MutableUTF8String, i::Int) = getindex(utf8(s), i)
getindex(s::MutableUTF8String, r::Range1{Int}) = getindex(utf8(s), r)

function setindex!(s::MutableUTF8String, x, i0::Real)
    d = s.data
    !Base.is_utf8_start(d[i0]) && error("invalid UTF-8 character index")
    endi = i0+Base.utf8_trailing[d[i0]+1]
    setindex!(s, string(x), i0:endi)
end
function setindex!(s::MutableUTF8String, r::ByteString, I::Range1)
    st, ed = first(I), last(I)
    ed = nextind(s, ed)-1
    splice!(s.data, I, r.data)
    r
end
function setindex!(s::MutableUTF8String, c::Char, I::Range1)
    st, ed = first(I), last(I)
    ed = nextind(s, ed)-1
    if isascii(c)
        s.data[st:ed] = uint8(c)
    else
        iob = IOBuffer()
        print(iob, c)
        nd = nextind(s, st)
        while nd <= ed
            print(iob, c)
            nd = nextind(s, nd)
        end
        splice!(s.data, st:ed, takebuf_array(iob))
    end
end

search(s::MutableUTF8String, c::Char, i::Integer) = search(utf8(s), c, i)
rsearch(s::MutableUTF8String, c::Char, i::Integer) = rsearch(utf8(s), c, i)

function string(a::MutableString...) 
    data = Array(Uint8,0)
    for d in a
        append!(data,d.data)
    end
    MutableUTF8String(data)
end

function reverse!(s::MutableUTF8String)
    indata = copy(s.data)
    if ccall(:u8_reverse, Cint, (Ptr{Uint8}, Ptr{Uint8}, Csize_t), s.data, indata, length(indata)) == 1
        error("invalid UTF-8 data")
    end
    nothing
end

print(io::IO, s::MutableUTF8String) = (write(io, s.data);nothing)
write(io::IO, s::MutableUTF8String) = write(io, s.data)

lcfirst!(s::MutableUTF8String) = (s[1] = lowercase(s[1]); nothing)
ucfirst!(s::MutableUTF8String) = (s[1] = uppercase(s[1]); nothing)

function caseconvert!(s::MutableUTF8String, casefn::Function)
    (length(s) == 0) && return
    st = 1
    iob = IOBuffer()
    d = s.data
    while !done(s, st)
        c, ed = next(s, st)
        seek(iob, 0)
        print(iob, casefn(c))
        splice!(d, st:(ed-1), sub(iob.data, 1:position(iob)))
        st = ed
    end
end

uppercase!(s::MutableUTF8String) = caseconvert!(s, uppercase)
lowercase!(s::MutableUTF8String) = caseconvert!(s, lowercase)

