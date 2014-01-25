using MutableStrings

const nstr = 10^7
const lstr = 6

function makestr()
    iob = IOBuffer()
    for idx in 1:nstr
        write(iob, randstring(lstr))
    end
    takebuf_string(iob)
end

mk_blank(x::Array{Uint8,1}, y::Range1{Int64}) = (x[y] = uint8(' '))

function warmup()
    _mstr = MutableASCIIString(copy("asdsdsf".data))
    l = length(_mstr)
    lowercase!(_mstr);
    uppercase!(_mstr);
    reverse!(_mstr);
    ucfirst!(_mstr);
    lcfirst!(_mstr);
    replace!(_mstr, "abc", mk_blank);
    rx = r"c[a-z]+\s"
    search(_mstr, rx)
    search(_mstr, "abc")
    matchall(rx, _mstr)
end

function test()
    str = makestr();
    mstr = MutableASCIIString(copy(str.data));
    @printf("%20s%30s%40s\n", "", "string", "mutable string")
    @printf("%20s%30s%40s\n", "length", "$(length(str))", "$(length(mstr))")
    @printf("%20s%20s%20s%20s%20s\n", "", "time", "bytes", "time", "bytes")

    gc(); _ret, t, b = @timed str = lowercase(str);
    gc(); _mret, mt, mb = @timed lowercase!(mstr);
    @printf("%20s%20s%20s%20s%20s\n", "lowercase", "$t", "$b", "$mt", "$mb")

    gc(); _ret, t, b = @timed str = reverse(str);
    gc(); _mret, mt, mb = @timed reverse!(mstr);
    @printf("%20s%20s%20s%20s%20s\n", "reverse", "$t", "$b", "$mt", "$mb")

    gc(); _ret, t, b = @timed str = replace(str, "ab", "  ");
    gc(); _mret, mt, mb = @timed replace!(mstr, "ab", mk_blank);
    @printf("%20s%20s%20s%20s%20s\n", "replace", "$t", "$b", "$mt", "$mb")

    rx = r"c[a-z]+\s"
    gc(); _ret, t, b = @timed matchall(rx, str);
    gc(); _mret, mt, mb = @timed matchall(rx, mstr);
    @printf("%20s%20s%20s%20s%20s\n", "matchall", "$t", "$b", "$mt", "$mb")

    gc(); _ret, t, b = @timed begin
        pos = 1
        #fc = 0
        while pos <= length(str)
            res = search(str, rx, pos)
            (res.start == 0) && break
            pos = res.start + length(res)
            #fc += 1
        end
        #println("found $fc matches")
    end
    gc(); _mret, mt, mb = @timed begin
        pos = 1
        #fc = 0
        while pos <= length(mstr)
            res = search(mstr, rx, pos)
            (res.start == 0) && break
            pos = res.start + length(res)
            #fc += 1
        end
        #println("found $fc matches")
    end
    @printf("%20s%20s%20s%20s%20s\n", "search", "$t", "$b", "$mt", "$mb")

    gc(); _ret, t, b = @timed replace(str, rx, "")
    gc(); _mret, mt, mb = @timed replace!(mstr, rx, mk_blank)
    @printf("%20s%20s%20s%20s%20s\n", "replace", "$t", "$b", "$mt", "$mb")
end

warmup()
test()

