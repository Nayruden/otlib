--- File: Debugging Tools

--- Module: otlib
module( "otlib", package.seeall )

local function VardumpHelper( value, depth, key, done )
    local str = string.rep( "  ", depth )
    
    if key ~= nil then
        local t = type( key )
        if t == "string" then
            str = str .. string.format( "%q", key )
        else
            str = str .. tostring( key )
        end
        str = str .. " = "
    end
    
    local t = type( value )    
    if t == "table" and not done[ value ] then
        done[ value ] = true
        str = str .. string.format( "(table: array size=%i, total values=%i)\n", #value, Count(value) )
        for k, v in pairs( value ) do
            str = str .. VardumpHelper( v, depth+1, k, done )
        end
    elseif t == "string" then
        str = str .. string.format( "%q\n", value )
    else
        str = str .. tostring( value ) .. "\n"
    end
    
    return str
end


--[[
    Function: Vardump

    Returns useful, readable information about variables.

    Parameters:

        ... - Accepts any number of parameters of *any type* and prints them one by one.
        
    Returns:
    
        A readable *string* serialization of the data passed in.

    Example:

        :Vardump( { "foo", apple="green", floor=41, shopping={ "milk", "cookies" } } )

        returns the string...

        :(table: array size=1, total values=4)
        :  1 = "foo"
        :  "apple" = "green"
        :  "floor" = 41
        :  "shopping" = (table: array size=2, total values=2)
        :    1 = "milk"
        :    2 = "cookies"
        
    Notes:
    
        * A string will always be surrounded by quotes and a number will always stand by itself.
            This is to make it easier to identify numbers stored as strings.
        * Array size and total size are shown in the table header. Array size is the result of the
            pound operator (#) on the table, total size is the result of <Count>. Array size is 
            useful debug information when iterating over a table with ipairs.

    Revisions:

        v1.00 - Initial.
]]
function Vardump( ... )
    local str = ""
    local t = { ... }
    for i=1, select( "#", ... ) do
        str = str .. VardumpHelper( t[ i ], 0, nil, {} )
    end
    
    return str:sub( 1, -2 ) -- Remove last newline
end


--[[
    Function: ThrowBadArg

    "Throws" an error similar to the lua standard error of "bad argument #x to <fn_name> (<type> 
    expected, got <type>)".

    Parameters:

        argnum - The *optional argument number* that was bad.
        fn_name - The *optional string* of the function name being called.
        expected - The *optional string or list table* of the type(s) you expected.
        data - *Optional and any type*, the actual data you got.
        throw_level - The *optional number* of how many levels up to throw the error. Defaults to _3_.

    Returns:

        *Never returns, throws an error.*
        
    Revisions:
    
        v1.00 - Initial.
]]
function ThrowBadArg( argnum, fn_name, expected, data, throw_level )
    if expected and type( expected ) == "string" then
        expected = { expected }
    end
    
    local str = "bad argument"
    if argnum then
        str = str .. " #" .. tostring( argnum ) 
    end 
    if fn_name then
        str = str .. " to " .. fn_name
    end
    if expected or data then
        str = str .. " ("
        if expected then
            str = str .. table.concat( expected, " or " ) .. " expected"
        end
        if expected and data then
            str = str .. ", "
        end
        if data then
            str = str .. "got " .. type( data )
        end
        str = str .. ")"
    end
    
    error( str, throw_level or 3 )
end


--[[
    Function: CheckArg

    Used to check to see if a function argument matches what is expected. If it doesn't, call
    <ThrowBadArg>. This function is primarily useful at the beginning of a function definition to
    ensure that the correct type of data was passed in.

    Parameters:

        argnum - The *optional argument number* that was bad.
        fn_name - The *optional string* of the function name being called.
        expected - The *optional string or list table* of the type(s) you expected.
        data - *Optional and any type*, the actual data you got.
        throw_level - The *optional number* of how many levels up to throw the error. Defaults to _4_.

    Returns:

        *Never returns* if the data is bad since it throws an error. Otherwise returns *true*.
        
    Revisions:
    
        v1.00 - Initial.
]]
function CheckArg( argnum, fn_name, expected, data, throw_level )
    local is_str = type( expected ) == "string"
    if (is_str and type( data ) == expected) or (not is_str and (HasValueI( expected, type( data ) ))) then
        return true
    else
        return ThrowBadArg( argnum, fn_name, expected, data, throw_level or 4 )
    end
end
