module( "TestUtils", package.seeall )

function TestExplode()
    AssertTablesEqual( otlib.Explode( "howdy \they  mother " ), { "howdy", "hey", "mother", "" } )
    AssertTablesEqual( otlib.Explode( "line1\n\nline3", "\n", true ), { "line1", "", "line3" } )
    AssertTablesEqual( otlib.Explode( "line1\n+\n+line3", "\n+", true ), { "line1", "", "line3" } )
    AssertTablesEqual( otlib.Explode( "line1\n+\n+line3", "\n+", true, 2 ), { "line1", "\n+line3" } )
end

function TestTrim()
    AssertEquals( otlib.Trim( " test\t" ), "test" )
    AssertEquals( otlib.Trim( " test" ), "test" )
    AssertEquals( otlib.Trim( "test\t" ), "test" )
    AssertEquals( otlib.Trim( "abcd" ), "abcd" )
    AssertEquals( otlib.Trim( "" ), "" )
end

function TestStripComments()
    local data = "Line 1 # My comment\n#Line with only a comment\nLine 2"
    AssertEquals( otlib.StripComments( data, "#"), "Line 1 \n\nLine 2" )
end

function TestParseArgs()
    local t = otlib.ParseArgs( 'This is a "Cool sentence to" make "split up"' )
    AssertTablesEqual( t, { "This", "is", "a", "Cool sentence to", "make", "split up" } )

    t = otlib.ParseArgs( "onearg" )
    AssertTablesEqual( t, { "onearg" } )

    t = otlib.ParseArgs( "onearg twoarg" )
    AssertTablesEqual( t, { "onearg", "twoarg" } )

    t = otlib.ParseArgs( 'hey" bob person"' )
    AssertTablesEqual( t, { "hey", " bob person" } )

    t = otlib.ParseArgs( 'hey" bob person space" ' )
    AssertTablesEqual( t, { "hey", " bob person space" } )

    t = otlib.ParseArgs( 'hey" arg2 and stuff' )
    AssertTablesEqual( t, { "hey", " arg2 and stuff" } )

    t = otlib.ParseArgs( "{" )
    AssertTablesEqual( t, { "{" } )

    t = otlib.ParseArgs( '"arg1" "arg2"' )
    AssertTablesEqual( t, { "arg1", "arg2" } )

    t = otlib.ParseArgs( '  "arg1" ' )
    AssertTablesEqual( t, { "arg1" } )

    t = otlib.ParseArgs( '"arg1"' )
    AssertTablesEqual( t, { "arg1" } )

    t = otlib.ParseArgs( 'arg1"' )
    AssertTablesEqual( t, { "arg1", "" } )

    t = otlib.ParseArgs( 'this "is a"bad way"to make" a sentence' )
    AssertTablesEqual( t, { "this", "is a", "bad", "way", "to make", "a", "sentence" } )
end


function TestEditDistance()
    AssertEquals( otlib.EditDistance( "Tuesday", "Teusday" ), 1 )
    AssertEquals( otlib.EditDistance( "kitten", "sitting" ), 3 )
end

function TestRound()
    AssertEquals( otlib.Round( 41.41 ), 41 )
    AssertEquals( otlib.Round( 41.50, 0 ), 42 )
    AssertEquals( otlib.Round( 41.499999999999, 0 ), 41 )
    AssertEquals( otlib.Round( 414, -1 ), 410 )
    AssertEquals( otlib.Round( 41.4099, 2 ), 41.41 )
end

function TestToBool()
    AssertEquals( otlib.ToBool( false ), false )
    AssertEquals( otlib.ToBool( true ), true )
    AssertEquals( otlib.ToBool( 0 ), false )
    AssertEquals( otlib.ToBool( "0.0" ), false )
    AssertEquals( otlib.ToBool( -1 ), true )
    AssertEquals( otlib.ToBool( "-1.0" ), true )
    AssertEquals( otlib.ToBool( nil ), false )
    AssertEquals( otlib.ToBool( "yes" ), true )
    AssertEquals( otlib.ToBool( "y" ), true )
    AssertEquals( otlib.ToBool( "t" ), true )
    AssertEquals( otlib.ToBool( "true" ), true )
    AssertEquals( otlib.ToBool( "n" ), false )
    AssertEquals( otlib.ToBool( "no" ), false )
    AssertEquals( otlib.ToBool( "false" ), false )
    AssertEquals( otlib.ToBool( "f" ), false )
    AssertEquals( otlib.ToBool( function() end ), true ) -- Favor true
end

function TestStoredExpression()
    local ex = otlib.StoredExpression()
    my_list = { "milk", "bread", "cookies", "eggs" }
    ex( otlib.HasValue( my_list, "cookies" ) )
    AssertEquals( ex[ 1 ], true )
    AssertEquals( ex[ 2 ], 3 )
    AssertEquals( ex.n, 2 )
    AssertTablesEqual( { ex.unpack() }, { true, 3 } )
end

function TestCount()
    AssertEquals( otlib.Count( { 1, 3, "two", [{}]=4 } ), 4 )
    AssertEquals( otlib.Count( {} ), 0 )
end

function TestIsEmpty()
    AssertEquals( otlib.IsEmpty( {} ), true )
    AssertEquals( otlib.IsEmpty( { "one" } ), false )
    AssertEquals( otlib.IsEmpty( { [{}]="apple" } ), false )
end

function TestCopy()
    local t = { [1]="hey", blah=67, mango="one" }
    AssertTablesEqual( otlib.Copy( t ), t )
    AssertTablesEqual( otlib.CopyI( t ), { "hey" } )
    
    t = { "one", "two" }
    AssertTablesEqual( t, otlib.Copy( t ) )
    AssertTablesEqual( t, otlib.CopyI( t ) )
end

local function InPlaceTester( desired, fn, ... )
    args = { ... }
    first = args[ 1 ]
    table.insert( args, false )
    local new = fn( unpack( args ) )
    AssertTablesEqual( new, desired )
    AssertNotEquals( new, first )
    
    args[ #args ] = true
    new = fn( unpack( args ) )
    AssertTablesEqual( new, desired )
    AssertEquals( new, first )
end

function TestRemoveDuplicateValues()
    InPlaceTester( { "apple", "pear", "kiwi", "banana" }, otlib.RemoveDuplicateValues, { "apple", "pear", "kiwi", "apple", "banana", "pear", "pear" } )
    InPlaceTester( {}, otlib.RemoveDuplicateValues, {} )
    InPlaceTester( { "bob" }, otlib.RemoveDuplicateValues, { "bob" } )
end

function TestUnion()
    -- By Key
    local t, u = { apple="red", pear="green", kiwi="hairy" }, { apple="green", pear="green", banana="yellow" }
    local desired = { apple="green", pear="green", kiwi="hairy", banana="yellow" }
    
    AssertTablesEqual( otlib.UnionByKeyI( t, u ), {} )
    InPlaceTester( desired, otlib.UnionByKey, t, u )
    
    -- Better test of UnionByKeyI
    t, u = { "apple", "pear", "kiwi" }, { "pear", "apple", "banana" }
    desired = { "pear", "apple", "banana" }
    InPlaceTester( desired, otlib.UnionByKeyI, t, u )
    
    -- By Value
    t = { "apple", "pear", "kiwi" }
    desired = { "apple", "pear", "kiwi", "banana" }
    InPlaceTester( desired, otlib.UnionByValue, t, u )
    
    t, u = { "apple", "pear", "kiwi", "pear" }, { "pear", "apple", "banana", "apple" }
    desired = { "apple", "pear", "kiwi", "banana" }
    InPlaceTester( desired, otlib.UnionByValue, t, u )
end

function TestIntersection()
    -- By Key
    local t, u = { apple="red", pear="green", kiwi="hairy" }, { apple="green", pear="green", banana="yellow" }
    local desired = { apple="green", pear="green" }
    
    AssertTablesEqual( otlib.IntersectionByKeyI( t, u ), {} )
    InPlaceTester( desired, otlib.IntersectionByKey, t, u )
    
    -- Better test of IntersectionByKeyI
    t, u = { "apple", "pear", "kiwi" }, { "pear", "apple" }
    desired = { "pear", "apple" }
    InPlaceTester( desired, otlib.IntersectionByKeyI, t, u )
    
    -- By Value
    t, u = { "apple", "pear", "kiwi" }, { "pear", "apple", "banana" }
    desired = { "apple", "pear" }
    InPlaceTester( desired, otlib.IntersectionByValue, t, u )
    
    t, u = { "apple", "pear", "kiwi", "pear" }, { "pear", "apple", "banana", "apple" }
    InPlaceTester( desired, otlib.IntersectionByValue, t, u )
end

function TestDifference()
    -- By Key
    local t, u = { apple="red", pear="green", kiwi="hairy" }, { apple="green", pear="green", banana="yellow" }
    local desired = { kiwi="hairy" }
    
    AssertTablesEqual( otlib.DifferenceByKeyI( t, u ), {} )
    InPlaceTester( desired, otlib.DifferenceByKey, t, u )

    -- Better test of DifferenceByKeyI
    t, u = { "apple", "pear", "kiwi" }, { "pear", "apple" }
    desired = { [3]="kiwi" }
    InPlaceTester( desired, otlib.DifferenceByKeyI, t, u )
    
    -- By Value
    t = { "apple", "pear", "kiwi" }
    desired = { "kiwi" }
    InPlaceTester( desired, otlib.DifferenceByValue, t, u )
    
    t, u = { "apple", "pear", "kiwi", "pear" }, { "pear", "apple", "banana", "apple" }
    InPlaceTester( desired, otlib.DifferenceByValue, t, u )
end

function TestSetFromList()
    AssertTablesEqual( otlib.SetFromList( { "apple", "banana", "kiwi", "pear" } ), { apple=true, banana=true, kiwi=true, pear=true } )
end

function TestAppend()
    local t, u = { "apple", "banana", "kiwi" }, { "orange", "pear" }
    AssertTablesEqual( otlib.Append( t, u ), { "apple", "banana", "kiwi", "orange", "pear" } )
end

function TestHasValue()
    t = { apple="red", pear="green", kiwi="hairy" }
    a, b = otlib.HasValue( t, "green" )
    AssertEquals( a, true )
    AssertEquals( b, "pear" )
    
    a, b = otlib.HasValue( t, "blue" )
    AssertEquals( a, false )
    AssertEquals( b, nil )
end
