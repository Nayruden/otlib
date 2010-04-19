--- File: Initialization
--- Initialization of OTLib console mod occurs here

--- Module: otlib.console
module( "otlib.console", package.seeall )

-- TODO, more automated
dofile "init.lua"
dofile "utils.lua"
dofile "prototype.lua"
dofile "access.lua"
dofile "debug.lua"

function DoTests()
    local tests = { "utils", "access" }
    
    for i, test in ipairs( tests ) do
        print( "performing " .. test .. " tests..." )
        local status, err = pcall( dofile, "tests/test_" .. test .. ".lua" )
        if not status then
            print( "Failure: " .. err )
        else
            print( "Success!" )
        end
        print() -- Empty line
    end
end