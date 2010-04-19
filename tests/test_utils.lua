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
assert( otlib.Trim( "abcd" ) == "abcd" )
assert( otlib.Trim( "" ) == "" )


-- Test StripComments
t = otlib.StripComments( "Line 1 # My comment\n#Line with only a comment\nLine 2", "#" )
assert( t == "Line 1 \n\nLine 2" )


-- Test Round
assert( 41 == otlib.Round( 41.41 ) )
assert( 42 == otlib.Round( 41.50, 0 ) )
assert( 410 == otlib.Round( 414, -1 ) )
assert( 41.41 == otlib.Round( 41.4099, 2 ) )


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
assert( TableEq( t, { "hey", " bob person space", "" } ) )

t = otlib.ParseArgs( "hey\" arg2 and stuff" )
assert( TableEq( t, { "hey", " arg2 and stuff" } ) )

t = otlib.ParseArgs( "{" )
assert( TableEq( t, { "{" } ) )

t = otlib.ParseArgs( "\"arg1\" \"arg2\"" )
assert( TableEq( t, { "arg1", "arg2" } ) )

t = otlib.ParseArgs( "  \"arg1\" " )
assert( TableEq( t, { "arg1" } ) )

t = otlib.ParseArgs( "\"arg1\"" )
assert( TableEq( t, { "arg1" } ) )

t = otlib.ParseArgs( "arg1\"" )
assert( TableEq( t, { "arg1", "" } ) )

-- Test Count
t = { 1, 3, "two", [{}]=4 }
assert( otlib.Count( t ) == 4 )
assert( otlib.Count( {} ) == 0 )

-- Test IsEmpty
assert( otlib.IsEmpty( {} ) == true )
assert( otlib.IsEmpty( { "one" } ) == false )
assert( otlib.IsEmpty( { [{}]="apple" } ) == false )

-- Test Copy
t = { [1]="hey", blah=67, mango="one" }
assert( TableEq( t, otlib.Copy( t ) ) )
assert( not TableEq( t, otlib.CopyI( t ) ) )

t = { [1]="one", [2]="two" }
assert( TableEq( t, otlib.Copy( t ) ) )
assert( TableEq( t, otlib.CopyI( t ) ) )

-- Test Merge
t, u = { apple="red", pear="green", kiwi="hairy" }, { apple="green", pear="green", banana="yellow",}
assert( TableEq( otlib.Union( t, u ), { apple="green", pear="green", kiwi="hairy", banana="yellow" } ) )
assert( TableEq( otlib.UnionI( t, u ), {} ) )
assert( TableEq( otlib.Union( t, u, true ), { apple="green", pear="green", kiwi="hairy", banana="yellow" } ) )

-- Test Intersection
t, u = { apple="red", pear="green", kiwi="hairy" }, { apple="green", pear="green", banana="yellow" }
assert( TableEq( otlib.Intersection( t, u ), { apple="green", pear="green" } ) )
assert( TableEq( otlib.IntersectionI( t, u ), {} ) )
assert( TableEq( otlib.Intersection( t, u, true ), { apple="green", pear="green" } ) )

-- Test Difference
t, u = { apple="red", pear="green", kiwi="hairy" }, { apple="green", pear="green", banana="yellow" }
assert( TableEq( otlib.Difference( t, u ), { kiwi="hairy" } ) )
assert( TableEq( otlib.DifferenceI( t, u ), {} ) )
assert( TableEq( otlib.Difference( t, u, true ), { kiwi="hairy" } ) )

-- Test Append
t, u = { "apple", "banana", "kiwi" }, { "orange", "pear" }
assert( TableEq( otlib.Append( t, u ), { "apple", "banana", "kiwi", "orange", "pear" } ) )

-- Test HasValue
t = { apple="red", pear="green", kiwi="hairy" }
a, b = otlib.HasValue( t, "green" )
assert( a == true and b == "pear" )
a, b = otlib.HasValue( t, "blue" )
assert( a == false and b == nil )

-- Test ToBool
assert( otlib.ToBool( false ) == false )
assert( otlib.ToBool( true ) == true )
assert( otlib.ToBool( 0 ) == false )
assert( otlib.ToBool( "0.0" ) == false )
assert( otlib.ToBool( -1 ) == true )
assert( otlib.ToBool( "-1.0" ) == true )
assert( otlib.ToBool( nil ) == false )
assert( otlib.ToBool( "yes" ) == true )
assert( otlib.ToBool( "y" ) == true )
assert( otlib.ToBool( "t" ) == true )
assert( otlib.ToBool( "true" ) == true )
assert( otlib.ToBool( "n" ) == false )
assert( otlib.ToBool( "no" ) == false )
assert( otlib.ToBool( "false" ) == false )
assert( otlib.ToBool( "f" ) == false )
assert( otlib.ToBool( function() end ) == true ) -- Favor true
