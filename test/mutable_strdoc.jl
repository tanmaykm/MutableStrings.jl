using TextAnalysis
using MutableStrings

const nstr = 10^7
const lstr = 6

function makestr_ascii()
    iob = IOBuffer()
    for idx in 1:nstr
        write(iob, randstring(lstr))
        write(iob, ' ')
    end
    takebuf_string(iob)
end

function makestr_utf8()
    iob = IOBuffer()
    utf8chars = convert(Array{Char,1}, "abcdefΑΒΓΔΕΖΗΘαβγδεζηθ")
    for idx in 1:nstr
        if (idx % 10) == 0
            shuffle!(utf8chars)
            write(iob, convert(UTF8String, utf8chars[1:lstr]))
        else
            write(iob, randstring(lstr))
        end
        write(iob, ' ')
    end
    takebuf_string(iob)
end

function warmup_ascii()
    _mstr = MutableASCIIString("asdsdsf");
    l = length(_mstr)
    lowercase!(_mstr);
    uppercase!(_mstr);
    reverse!(_mstr);
    ucfirst!(_mstr);
    lcfirst!(_mstr);
    replace!(_mstr, "abc", ' ');
    remove_case!(StringDocument("ssdfsdfdsf"));
    TextAnalysis.remove_patterns!(StringDocument("ssdfsdfdsf"), r"abc");
    TextAnalysis.remove_patterns!(StringDocument(MutableASCIIString("ssdfsdfdsf")), r"abc");
    TextAnalysis.stem!(StringDocument("ssdfsdfdsf"));
    TextAnalysis.stem!(StringDocument(MutableASCIIString("ssdfsdfdsf")));
end

function warmup_utf8()
    _mstr = MutableUTF8String("abcdefΑΒΓΔΕΖΗΘαβγδεζηθ");
    l = length(_mstr)
    lowercase!(_mstr);
    uppercase!(_mstr);
    reverse!(_mstr);
    ucfirst!(_mstr);
    lcfirst!(_mstr);
    replace!(_mstr, "abc", ' ');
    remove_case!(StringDocument("abcdefΑΒΓΔΕΖΗΘαβγδεζηθ"));
    TextAnalysis.remove_patterns!(StringDocument("abcdefΑΒΓΔΕΖΗΘαβγδεζηθ"), r"abc");
    TextAnalysis.remove_patterns!(StringDocument(MutableUTF8String("abcdefΑΒΓΔΕΖΗΘαβγδεζηθ")), r"abc");
    TextAnalysis.stem!(StringDocument("abcdefΑΒΓΔΕΖΗΘαβγδεζηθ"));
    TextAnalysis.stem!(StringDocument(MutableUTF8String("abcdefΑΒΓΔΕΖΗΘαβγδεζηθ")));
end

function test_ascii()
    str = makestr_ascii();
    mstr = MutableASCIIString(copy(str.data));

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

    stm = Stemmer("english")
    str = "running skipping " ^ 10^5
    mstr = MutableASCIIString(copy(str.data))
    strdoc = StringDocument(str)
    mstrdoc = StringDocument(mstr)
    gc(); _ret, t, b = @timed TextAnalysis.stem!(stm, strdoc)
    gc(); _mret, mt, mb = @timed TextAnalysis.stem!(stm, mstrdoc)
    @printf("%20s%20s%20s%20s%20s\n", "stem!", "$t", "$b", "$mt", "$mb")
end

function test_utf8()
    str = makestr_utf8();
    mstr = MutableUTF8String(copy(str.data));

    strdoc = StringDocument(str);
    mstrdoc = StringDocument(mstr);

    @printf("%20s%30s%40s\n", "", "string", "mutable string")
    @printf("%20s%30s%40s\n", "length", "$(length(str))", "$(length(mstr))")
    @printf("%20s%20s%20s%20s%20s\n", "", "time", "bytes", "time", "bytes")

    gc(); _ret, t, b = @timed remove_case!(strdoc);
    gc(); _mret, mt, mb = @timed remove_case!(mstrdoc)
    @printf("%20s%20s%20s%20s%20s\n", "remove_case!", "$t", "$b", "$mt", "$mb")
    
    strdoc = StringDocument(str)
    mstr = MutableUTF8String(copy(str.data));
    mstrdoc = StringDocument(mstr)

    gc(); _ret, t, b = @timed prepare!(strdoc, strip_case)
    gc(); _mret, mt, mb = @timed prepare!(mstrdoc, strip_case)
    @printf("%20s%20s%20s%20s%20s\n", "prepare!->strip_case", "$t", "$b", "$mt", "$mb")

    rx = r"a[a-z]+\s"
    gc(); _ret, t, b = @timed TextAnalysis.remove_patterns!(strdoc, rx)
    gc(); _mret, mt, mb = @timed TextAnalysis.remove_patterns!(mstrdoc, rx)
    @printf("%20s%20s%20s%20s%20s\n", "remove_patterns!", "$t", "$b", "$mt", "$mb")

    stm = Stemmer("english")
    str = "running skipping " ^ 10^5
    mstr = MutableUTF8String(copy(str.data))
    strdoc = StringDocument(str)
    mstrdoc = StringDocument(mstr)
    gc(); _ret, t, b = @timed TextAnalysis.stem!(stm, strdoc)
    gc(); _mret, mt, mb = @timed TextAnalysis.stem!(stm, mstrdoc)
    @printf("%20s%20s%20s%20s%20s\n", "stem!", "$t", "$b", "$mt", "$mb")
end

warmup_ascii()
test_ascii()

warmup_utf8()
test_utf8()

