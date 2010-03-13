dofile( "../utils.lua" )

local function TableEq( t1, t2 )
    local c1 = 0
    for k, v in pairs( t1 ) do
        c1 = c1 + 1
        if t1[ k ] ~= t2[ k ] then
            return false
        end
    end
    
    for k, v in pairs( t2 ) do
        c1 = c1 - 1
    end
    
    if not c1 == 0 then return false end
    return true
end

local function printt( t )
    print( "---" )
    for k, v in ipairs( t ) do
        print( string.format( "%q", v ) )
    end
    print( "---" )
end

-- Test Explode
t = otlib.Explode( "howdy \they  mother " )
assert( TableEq( t, { "howdy", "hey", "mother", "" } ) )


-- Test Trim
assert( otlib.Trim( " test\t" ) == "test" )


-- Test StripComments
t = otlib.StripComments( "Line 1 # My comment\n#Line with only a comment\nLine 2", "#" )
assert( t == "Line 1 \n\nLine 2" )


-- Test ParseArgs
t = otlib.ParseArgs( "This is a \"Cool sentence to\" make \"split up\"" )
assert( TableEq( t, { "This", "is", "a", "Cool sentence to", "make", "split up" } ) )

t = otlib.ParseArgs( "onearg" )
assert( TableEq( t, { "onearg" } ) )

t = otlib.ParseArgs( "onearg twoarg" )
assert( TableEq( t, { "onearg", "twoarg" } ) )

t = otlib.ParseArgs( "hey\" bob person\"" )
assert( TableEq( t, { "hey", " bob person" } ) )

t = otlib.ParseArgs( "hey\" bob person space\" " )
assert( TableEq( t, { "hey", " bob person space" } ) )

t = otlib.ParseArgs( "hey\" arg2 and stuff" )
assert( TableEq( t, { "hey", " arg2 and stuff" } ) )

-- Test Copy
t = { [1]="hey", blah=67, mango="one" }
assert( TableEq( t, otlib.Copy( t ) ) )
assert( not TableEq( t, otlib.CopyI( t ) ) )

t = { [1]="one", [2]="two" }
assert( TableEq( t, otlib.Copy( t ) ) )
assert( TableEq( t, otlib.CopyI( t ) ) )

-- Test Merge
t, u = { apple=red, pear=green, kiwi=hairy }, { apple=green, pear=green, banana=yellow }
assert( TableEq( otlib.Merge( t, u ), { apple=green, pear=green, kiwi=hairy, banana=yellow } ) )
assert( TableEq( otlib.MergeI( t, u ), {} ) )
assert( TableEq( otlib.Merge( t, u, true ), { apple=green, pear=green, kiwi=hairy, banana=yellow } ) )

-- Test Append
t, u = { "apple", "banana", "kiwi" }, { "orange", "pear" }
assert( TableEq( otlib.Append( t, u ), { "apple", "banana", "kiwi", "orange", "pear" } ) )
assert( TableEq( otlib.AppendI( t, u ), { "apple", "banana", "kiwi", "orange", "pear" } ) )
