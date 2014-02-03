const utf8_offset = [
    0x00000000, 0x00003080,
    0x000e2080, 0x03c82080,
    0xfa082080, 0x82082080,
]       

const utf8_trailing = [
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, 3,3,3,3,3,3,3,3,4,4,4,4,5,5,5,5,
]


function endof(s::MutableUTF8String)
    d = s.data
    i = length(d)
    i == 0 && return i
    while !Base.is_utf8_start(d[i])
        i -= 1
    end
    i
end
length(s::MutableUTF8String) = int(ccall(:u8_strlen, Csize_t, (Ptr{Uint8},), s.data))


next(s::MutableUTF8String, i::Int) = (s[i], i+1+utf8_trailing[s.data[i]+1])

isvalid(s::MutableUTF8String, i::Integer) = (1 <= i <= endof(s.data)) && Base.is_utf8_start(s.data[i])

# common base method for utf8 strings would avoid duplication of getindex
function getindex(s::MutableUTF8String, i::Int)
    d = s.data
    b = d[i]
    if !Base.is_utf8_start(b)
        j = i-1
        while 0 < j && !Base.is_utf8_start(d[j])
            j -= 1
        end
        if 0 < j && i <= j+utf8_trailing[d[j]+1] <= length(d)
            # b is a continuation byte of a valid UTF-8 character
            error("invalid UTF-8 character index")
        end
        return '\ufffd'
    end
    trailing = utf8_trailing[b+1]
    if length(d) < i + trailing
        return '\ufffd'
    end
    c::Uint32 = 0
    for j = 1:trailing+1
        c <<= 6
        c += d[i]
        i += 1
    end
    c -= utf8_offset[trailing+1]
    char(c)
end

function getindex(s::MutableUTF8String, r::Range1{Int})
    isempty(r) && return empty_utf8
    i, j = first(r), last(r)
    d = s.data
    if !Base.is_utf8_start(d[i])
        i = nextind(s,i)
    end
    if j > endof(s)
        throw(BoundsError())
    end
    j = nextind(s,j)-1
    UTF8String(d[i:j])
end

function setindex!(s::MutableUTF8String, x, i0::Real)
    d = s.data
    !Base.is_utf8_start(d[i0]) && error("invalid UTF-8 character index")
    endi = i0+utf8_trailing[d[i0]+1]
    setindex!(s, string(x), i0:endi)
end
function setindex!(s::MutableUTF8String, r::ByteString, I::Range1)
    st, ed = first(I), last(I)
    ed = nextind(s, ed)-1
    _splice!(s.data, I, r.data)
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
        _splice!(s.data, st:ed, takebuf_array(iob))
    end
    c
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

lcfirst!(s::MutableUTF8String) = (s[1] = lowercase(s[1]); nothing)
ucfirst!(s::MutableUTF8String) = (s[1] = uppercase(s[1]); nothing)

function uppercase!(s::MutableUTF8String)
    (length(s) == 0) && return
    st = 1
    iob = IOBuffer()
    d = s.data
    while !done(s, st)
        c, ed = next(s, st)
        seek(iob, 0)
        print(iob, uppercase(c))
        p = position(iob)
        _splice!(d, st:(ed-1), iob.data, p)
        st += p
    end
end

function lowercase!(s::MutableUTF8String)
    (length(s) == 0) && return
    st = 1
    iob = IOBuffer()
    d = s.data
    while !done(s, st)
        c, ed = next(s, st)
        print(iob, lowercase(c))
        p = position(iob)
        _splice!(d, st:(ed-1), iob.data, p)
        seek(iob, 0)
        st += p
    end
end

function replace!{T}(str::MutableUTF8String, pattern::T, repl::Union(Function,ByteString,Char), limit::Integer=0)
    n = 1
    es = endof(str)
    r = search(str,pattern,1)
    j, k = first(r), last(r)
    k = nextind(str,k) - 1
    while j != 0
        rv::Union(ByteString,Char) = isa(repl, Function) ? repl(SubString(str, j, k)) : repl
        if isa(rv, ByteString)
            _splice!(str.data, j:k, rv.data)
            lrv = length(rv.data)
            lr = k-j+1
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
        k = nextind(str,k) - 1
        n == limit && break
        n += 1
    end
end

function replace!(str::MutableUTF8String, re::Regex, repl::Union(Function,ByteString,Char), limit::Integer=0) 
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

        rv::Union(ByteString,Char) = isa(repl, Function) ? repl(SubString(str, ovec[1]+1, ovec[2])) : repl
        r = (ovec[1]+1):(nextind(str, ovec[2])-1)
        if isa(rv, ByteString)
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

function map!(f, s::MutableUTF8String)
    st = 1
    d = s.data
    while !done(s, st)
        s[st] = f(s[st])
        st = st + 1 + utf8_trailing[d[st] + 1]
    end
end

