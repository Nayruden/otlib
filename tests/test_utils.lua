dofile( "tests/luaunit.lua" )

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

function TestRound()
    AssertEquals( otlib.Round( 41.41 ), 41 )
    AssertEquals( otlib.Round( 41.50, 0 ), 42 )
    AssertEquals( otlib.Round( 41.499999999999, 0 ), 41 )
    AssertEquals( otlib.Round( 414, -1 ), 410 )
    AssertEquals( otlib.Round( 41.4099, 2 ), 41.41 )
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
    
    t = { [1]="one", [2]="two" }
    AssertTablesEqual( t, otlib.Copy( t ) )
    AssertTablesEqual( t, otlib.CopyI( t ) )
end

function TestUnion()
    local t, u = { apple="red", pear="green", kiwi="hairy" }, { apple="green", pear="green", banana="yellow" }
    AssertTablesEqual( otlib.UnionByKey( t, u ), { apple="green", pear="green", kiwi="hairy", banana="yellow" } )
    AssertTablesEqual( otlib.UnionByKeyI( t, u ), {} )
    AssertTablesEqual( otlib.UnionByKey( t, u, true ), { apple="green", pear="green", kiwi="hairy", banana="yellow" } )
end

function TestIntersection()
    local t, u = { apple="red", pear="green", kiwi="hairy" }, { apple="green", pear="green", banana="yellow" }
    AssertTablesEqual( otlib.IntersectionByKey( t, u ), { apple="green", pear="green" } )
    AssertTablesEqual( otlib.IntersectionByKeyI( t, u ), {} )
    AssertTablesEqual( otlib.IntersectionByKey( t, u, true ), { apple="green", pear="green" } )
end

function TestDifference()
    local t, u = { apple="red", pear="green", kiwi="hairy" }, { apple="green", pear="green", banana="yellow" }
    AssertTablesEqual( otlib.DifferenceByKey( t, u ), { kiwi="hairy" } )
    AssertTablesEqual( otlib.DifferenceByKeyI( t, u ), {} )
    AssertTablesEqual( otlib.DifferenceByKey( t, u, true ), { kiwi="hairy" } )
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

LuaUnit:run()
