# Mutable Strings

Note: This package is now deprecated in favor of <https://github.com/quinnj/Strings.jl> (see <https://github.com/tanmaykm/MutableStrings.jl/issues/3>)

Large scale text processing often requires several changes to be made on large string objects. Using immutable strings can result in significant inefficiencies in such cases. Using byte arrays directly prevents us from using the convenient string methods. This package provides Mutable ASCII and UTF8 string types that allow mutating the string data through the familiar string methods.

## Types
- MutableASCIIString: `immutable MutableASCIIString <: DirectIndexString`
- MutableUTF8String: `immutable MutableUTF8String <: String`
- MutableString: `typealias MutableString Union(MutableASCIIString, MutableUTF8String)`

## Methods
All methods on immutable strings can also be applied to a MutableString. Additionally the below methods allow modifications on MutableString objects:

### Case Conversion

- `uppercase!(s::MutableString)` : In-place uppercase conversion
- `lowercase!(s::MutableString)` : In-place lowercase conversion
- `ucfirst!(s::MutableString)` : Convert the first letter to uppercase in-place
- `lcfirst!(s::MutableString)` : Convert the first letter to lowercase in-place


### Search/Replace
The usual `search` methods on String type also applies to MutableStrings. 

`replace!(s::MutableString, pattern, repl::Union(ByteString,Char,Function), limit::Integer=0)`

The above method allows in-place replacement of patterns matching `pattern` with `repl` upto `limit` occurrences. If `limit` is zero, all occurrences are replaced. 

As with search, the `pattern` argument may be a single character, a vector or a set of characters, a string, or a regular expression. 

If `repl` is a ByteString, it replaces the matching region. If it is a Char, it replaces each character of the matching region. If `repl` is a function, it must accept a SubString representing the matching region and return either a Char or a ByteString to be used as the replacement.


### Others

- `setindex!(s::MutableString, x, i0::Real)`
- `setindex!(s::MutableString, r::ByteString,I::Range1{T<:Real})`
- `setindex!(s::MutableString, c::Char, I::Range1{T<:Real})`
- `reverse!(s::MutableString)`
- `map!(f, s::MutableString)`

Parts of a mutable string can be modified as:

````
   s[10] = 'A'
   s[12:14] = "ABC"
````


### Performance

- Most operations on a MutableString are faster than those on an immutable String. 
- Replacing segments of mutable strings with different length replacements is slower than recreating the entire string. 
- MutableStrings are always more memory efficient than immutable Strings. 

<table>
<tr><th> </th><th colspan="2">ASCIIString</th><th colspan="2">MutableASCIIString</th></tr>
<tr><th>function</th><th>time</th><th>bytes</th><th>time</th><th>bytes</th></tr>
<tr><td>case conversion</td><td>0.00499</td><td>700080</td><td>0.00476</td><td>0</td></tr>
<tr><td>reverse</td><td>0.0105</td><td>711384</td><td>0.0010</td><td>0</td></tr>
<tr><td>regex search and blank out matches</td><td>0.00679</td><td>917000</td><td>0.00295</td><td>64</td></tr>
<tr><td>regex search and delete matches</td><td>0.02495</td><td>6144072</td><td>1.01742</td><td>292768</td></tr>
</table>



### Notes
- Significant code has been duplicated from Julia base to specialize the MutableString methods. A proper type-reorganization would eliminate this.
- The hash method on MutableString behaves similar to that on String. This can result in surprises when it is used as a key in collections.
- Since UTF8 has variable character byte lengths, MutableUTF8String also allows replacing segments of the string with arbitrary length replacements, e.g: `s[10] = "ABC"`. This is inconsistent with behavior of MutableASCIIString, and remains to be debated.

