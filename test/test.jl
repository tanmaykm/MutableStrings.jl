using MutableStrings

const nstr = 10^5
const lstr = 6

function makestr()
    iob = IOBuffer()
    for idx in 1:nstr
        write(iob, randstring(lstr))
        write(iob, ' ')
    end
    takebuf_string(iob)
end

#mk_blank(x::MutableASCIIString, y::Range1{Int64}) = (x.data[y] = uint8(' '))
mk_blank(x) = ""
mk_space(x) = " "

function warmup()
    _mstr = MutableASCIIString(copy("asdsdsf".data))
    l = length(_mstr)
    lowercase!(_mstr);
    uppercase!(_mstr);
    reverse!(_mstr);
    ucfirst!(_mstr);
    lcfirst!(_mstr);
    replace!(_mstr, "abc", mk_blank);
    replace!(_mstr, r"bcd", mk_blank);
    rx = r"c[a-z]+\s"
    search(_mstr, rx)
    search(_mstr, "abc")
    matchall(rx, _mstr)
end

function test_set_get()
    ms = MutableASCIIString("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
    @assert ms[1] == 'L'
    @assert ms[1:10] == "Lorem ipsu"
    @assert ms[2:10] == "orem ipsu"
    @assert typeof(ms[1:10]) == ASCIIString
    ms[1] = 'X'
    @assert ms[1:10] == "Xorem ipsu"
    ms[1:10] = 'X'
    @assert ms[1:10] == "X"^10
    ms[1:10] = "Lorem ipsu"
    @assert ms[1:10] == "Lorem ipsu"

    replace!(ms, "Lorem", "O RUM")
    @assert ms[1:5] == "O RUM"
    replace!(ms, r"O RUM", "Lorem")
    @assert ms[1:10] == "Lorem ipsu"

    s = replace(ms, "Lorem", "O RUM")
    @assert ms[1:5] != "O RUM"
    @assert beginswith(s, "O RUM")
end

function test_time()
    master_str = makestr();

    str = master_str;
    mstr = MutableASCIIString(str);
    @printf("%25s%30s%40s\n", "", "string", "mutable string")
    @printf("%25s%30s%40s\n", "length", "$(length(str))", "$(length(mstr))")
    @printf("%25s%20s%20s%20s%20s\n", "", "time", "bytes", "time", "bytes")

    gc(); _ret, t, b = @timed str = lowercase(str);
    gc(); _mret, mt, mb = @timed lowercase!(mstr);
    @printf("%25s%20s%20s%20s%20s\n", "lowercase", "$t", "$b", "$mt", "$mb")

    gc(); _ret, t, b = @timed str = reverse(str);
    gc(); _mret, mt, mb = @timed reverse!(mstr);
    @printf("%25s%20s%20s%20s%20s\n", "reverse", "$t", "$b", "$mt", "$mb")

    gc(); _ret, t, b = @timed str = replace(str, "ba", "  ");
    gc(); _mret, mt, mb = @timed replace!(mstr, "ba", "  ");
    @printf("%25s%20s%20s%20s%20s\n", "repl spaces", "$t", "$b", "$mt", "$mb")

    gc(); _ret, t, b = @timed str = replace(str, "cd", "c");
    gc(); _mret, mt, mb = @timed replace!(mstr, "cd", "c");
    @printf("%25s%20s%20s%20s%20s\n", "repl str", "$t", "$b", "$mt", "$mb")

    gc(); _ret, t, b = @timed str = replace(str, "cd", 'c');
    gc(); _mret, mt, mb = @timed replace!(mstr, "cd", 'c');
    @printf("%25s%20s%20s%20s%20s\n", "repl char", "$t", "$b", "$mt", "$mb")

    gc(); _ret, t, b = @timed str = replace(str, "ab", "");
    gc(); _mret, mt, mb = @timed replace!(mstr, "ab", "");
    @printf("%25s%20s%20s%20s%20s\n", "repl nothing", "$t", "$b", "$mt", "$mb")

    rx = r"c[a-z]+\s"
    gc(); _ret, t, b = @timed matchall(rx, str);
    gc(); _mret, mt, mb = @timed matchall(rx, mstr);
    @printf("%25s%20s%20s%20s%20s\n", "matchall", "$t", "$b", "$mt", "$mb")

    str = lowercase(master_str);
    mstr = MutableASCIIString(str);
    _cret = _cmret = 0
    gc(); _ret, t, b = @timed begin
        pos = 1
        while pos <= length(str)
            res = search(str, rx, pos)
            (res.start == 0) && break
            pos = res.start + length(res)
            _cret += 1
        end
    end
    gc(); _mret, mt, mb = @timed begin
        pos = 1
        while pos <= length(mstr)
            res = search(mstr, rx, pos)
            (res.start == 0) && break
            pos = res.start + length(res)
            _cmret += 1
        end
    end
    @assert _cret == _cmret
    @printf("%25s%20s%20s%20s%20s\n", "searched $(_cret) times", "$t", "$b", "$mt", "$mb")

    gc(); _ret, t, b = @timed replace(str, rx, "")
    gc(); _mret, mt, mb = @timed replace!(mstr, rx, mk_blank)
    @printf("%25s%20s%20s%20s%20s\n", "repl regex nothing fn", "$t", "$b", "$mt", "$mb")

    rx = Regex(str[1:1] * "[a-z]+\\s")
    gc(); _ret, t, b = @timed replace(str, rx, " ")
    gc(); _mret, mt, mb = @timed replace!(mstr, rx, mk_space)
    @printf("%25s%20s%20s%20s%20s\n", "repl regex space fn", "$t", "$b", "$mt", "$mb")

    str = lowercase(master_str);
    mstr = MutableASCIIString(str);
    l1 = length(mstr)
    rx = Regex(str[1:1] * "[a-z]+\\s")
    gc(); _ret, t, b = @timed replace(str, rx, "")
    gc(); _mret, mt, mb = @timed replace!(mstr, rx, "")
    @assert length(mstr) < l1
    @printf("%25s%20s%20s%20s%20s\n", "repl regex nothing", "$t", "$b", "$mt", "$mb")

    str = lowercase(master_str);
    mstr = MutableASCIIString(str);
    l1 = length(mstr)
    rx = Regex(str[1:1] * "[a-z]+\\s")
    gc(); _ret, t, b = @timed replace(str, rx, " ")
    gc(); _mret, mt, mb = @timed replace!(mstr, rx, " ")
    @assert length(mstr) < l1
    @printf("%25s%20s%20s%20s%20s\n", "repl regex space", "$t", "$b", "$mt", "$mb")

    str = lowercase(master_str);
    mstr = MutableASCIIString(str);
    l1 = length(mstr)
    rx = Regex(str[1:1] * "[a-z]+\\s")
    gc(); _ret, t, b = @timed replace(str, rx, ' ')
    gc(); _mret, mt, mb = @timed replace!(mstr, rx, ' ')
    @assert length(mstr) == l1
    @printf("%25s%20s%20s%20s%20s\n", "repl regex char", "$t", "$b", "$mt", "$mb")
end

warmup()
test_set_get()
test_time()

