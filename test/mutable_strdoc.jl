using TextAnalysis
using MutableStrings

const nstr = 10^7
const lstr = 6

function makestr()
    iob = IOBuffer()
    for idx in 1:nstr
        write(iob, randstring(lstr))
        write(iob, ' ')
    end
    takebuf_string(iob)
end

mk_blank(x::Array{Uint8,1}, y::Range1) = (x[y] = uint8(' '))

function warmup()
    _mstr = MutableASCIIString("asdsdsf");
    l = length(_mstr)
    lowercase!(_mstr);
    uppercase!(_mstr);
    reverse!(_mstr);
    ucfirst!(_mstr);
    lcfirst!(_mstr);
    replace!(_mstr, "abc", mk_blank);
    remove_case!(StringDocument("ssdfsdfdsf"));
    TextAnalysis.remove_patterns!(StringDocument("ssdfsdfdsf"), r"abc");
    TextAnalysis.remove_patterns!(StringDocument(MutableASCIIString("ssdfsdfdsf")), r"abc");
end

function test()
    str = makestr();
    mstr = MutableASCIIString(copy(str.data));
    println("strlen: $(length(str))")

    strdoc = StringDocument(str);
    mstrdoc = StringDocument(mstr);

    @printf("%20s%30s%40s\n", "", "string", "mutable string")
    @printf("%20s%30s%40s\n", "length", "$(length(str))", "$(length(mstr))")
    @printf("%20s%20s%20s%20s%20s\n", "", "time", "bytes", "time", "bytes")

    gc(); _ret, t, b = @timed remove_case!(strdoc);
    gc(); _mret, mt, mb = @timed remove_case!(mstrdoc)
    @printf("%20s%20s%20s%20s%20s\n", "remove_case!", "$t", "$b", "$mt", "$mb")
    
    strdoc = StringDocument(str)
    mstr = MutableASCIIString(copy(str.data));
    mstrdoc = StringDocument(mstr)

    gc(); _ret, t, b = @timed prepare!(strdoc, strip_case)
    gc(); _mret, mt, mb = @timed prepare!(mstrdoc, strip_case)
    @printf("%20s%20s%20s%20s%20s\n", "prepare!->strip_case", "$t", "$b", "$mt", "$mb")

    rx = r"a[a-z]+\s"
    gc(); _ret, t, b = @timed TextAnalysis.remove_patterns!(strdoc, rx)
    gc(); _mret, mt, mb = @timed TextAnalysis.remove_patterns!(mstrdoc, rx)
    @printf("%20s%20s%20s%20s%20s\n", "remove_patterns!", "$t", "$b", "$mt", "$mb")
end

warmup()
test()

