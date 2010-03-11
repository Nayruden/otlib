--- File: Debugging Tools

--- Module: otlib
module( "otlib", package.seeall )

local function VardumpHelper( value, depth, key, done )
    io.write( string.rep( "  ", depth ) )
    
    if key ~= nil then
        local t = type( key )
        if t == "string" then
            io.write( string.format( "%q", key ) )
        else
            io.write( tostring( key ) )
        end
        io.write( " = " )
    end
    
    local t = type( value )    
    if t == "table" and not done[ value ] then
        done[ value ] = true
        io.write( string.format( "(table: array size=%i, total size=%i)\n", #value, Count(value) ) )
        for k, v in pairs( value ) do
            VardumpHelper( v, depth+1, k, done )
        end
    elseif t == "string" then
        io.write( string.format( "%q", value ), "\n" )
    else
        io.write( tostring( value ), "\n" )
    end
end


--[[
    Function: Vardump

    Prints useful information about variables.

    Parameters:

        ... - Accepts any number of parameters of *any type* and prints them one by one.

    Example:

        :Vardump( { "foo", apple="green", floor=41, shopping={ "milk", "cookies" } } )

        prints...

        :(table: array size=1, total size=4)
        :  1 = "foo"
        :  "apple" = "green"
        :  "floor" = 41
        :  "shopping" = (table: array size=2, total size=2)
        :    1 = "milk"
        :    2 = "cookies"
        
    Notes:
    
        * A string will always be surrounded by quotes and a number will always stand by itself.
            This is to make it easier to identify numbers stored as strings.
        * Array size and total size are shown in the table header. Array size is the result of the
            pound operator (#) on the table, total size is the result of counting each value by
            iterating over the table with pairs. Array size is useful debug information when 
            iterating over a table with ipairs.

    Revisions:

        v1.0 - Initial
]]
function Vardump( ... )
    local t = { ... }
    for i=1, select( "#", ... ) do
        VardumpHelper( t[ i ], 0, nil, {} )
    end
end
