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
    _mstr = MutableUTF8String(copy("abcdef ΑΒΓΔΕΖΗΘ αβγδεζηθ".data))
    l = length(_mstr)
    lowercase!(_mstr);
    @assert _mstr == "abcdef αβγδεζηθ αβγδεζηθ"
    #println(_mstr)
    uppercase!(_mstr);
    @assert _mstr == "ABCDEF ΑΒΓΔΕΖΗΘ ΑΒΓΔΕΖΗΘ"
    #println(_mstr)

    reverse!(_mstr);
    lcfirst!(_mstr);
    @assert _mstr[1] == 'θ'
    ucfirst!(_mstr);
    @assert _mstr[1] == 'Θ'

    @assert _mstr[end] == 'A'
    @assert length(_mstr) == l
    bl = length(_mstr.data)
    _mstr[end] = 'Δ'    
    @assert _mstr[end] == 'Δ'
    @assert length(_mstr) == l
    @assert length(_mstr.data) > bl
    bl = length(_mstr.data)
    @assert _mstr[end-1] == 'B'
    _mstr[end-1] = 'β'
    @assert _mstr[end-2] == 'β'
    @assert _mstr == "ΘΗΖΕΔΓΒΑ ΘΗΖΕΔΓΒΑ FEDCβΔ"
end

function test_set_get()
    ms = MutableUTF8String("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
    @assert ms[1] == 'L'
    @assert ms[1:10] == "Lorem ipsu"
    @assert ms[2:10] == "orem ipsu"
    @assert typeof(ms[1:10]) == UTF8String
    ms[1] = 'X'
    @assert ms[1:10] == "Xorem ipsu"
    ms[1:10] = 'X'
    @assert ms[1:10] == "X"^10
#    ms[1:10] = "Lorem ipsu"
#    @assert ms[1:10] == "Lorem ipsu"
#
#    replace!(ms, "Lorem", "O RUM")
#    @assert ms[1:5] == "O RUM"
#    replace!(ms, r"O RUM", "Lorem")
#    @assert ms[1:10] == "Lorem ipsu"
#
#    s = replace(ms, "Lorem", "O RUM")
#    @assert ms[1:5] != "O RUM"
#    @assert beginswith(s, "O RUM")
#end

#function test_time()
#    master_str = makestr();
#
#    str = utf8(master_str);
#    mstr = MutableUTF8String(str);
#    @printf("%25s%30s%40s\n", "", "string", "mutable string")
#    @printf("%25s%30s%40s\n", "length", "$(length(str))", "$(length(mstr))")
#    @printf("%25s%20s%20s%20s%20s\n", "", "time", "bytes", "time", "bytes")
#
#    gc(); _ret, t, b = @timed str = lowercase(str);
#    gc(); _mret, mt, mb = @timed lowercase!(mstr);
#    @printf("%25s%20s%20s%20s%20s\n", "lowercase", "$t", "$b", "$mt", "$mb")
#
#    gc(); _ret, t, b = @timed str = reverse(str);
#    gc(); _mret, mt, mb = @timed reverse!(mstr);
#    @printf("%25s%20s%20s%20s%20s\n", "reverse", "$t", "$b", "$mt", "$mb")
#
#end

warmup()
#test_set_get()
#test_time()

