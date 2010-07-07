--- File: Do Tests
--- Run this file to run the OTLib test suite.

dofile( "init.lua" )
dofile( "utils.lua" )
dofile( "table_utils.lua" )
dofile( "prototype.lua" )
dofile( "access.lua" )
dofile( "debug.lua" )
dofile( "parameters.lua" )
dofile( "wrappers.lua" )
dofile( "simpledata.lua" )
dofile( "tests/luaunit.lua" )



function DoTests()
    local tests = { "utils", "access", "simpledata" }
    
    for i=1, #tests do
        dofile( "tests/test_" .. tests[ i ] .. ".lua" )
    end
    LuaUnit:run()
end
DoTests()
