--- File: Utilities

--- Module: otlib
module( "otlib", package.seeall )


--[[
    Function: Explode

    Split a string by a string.

    Parameters:

        str - The input *string* to explode.
        separator - An *optional string* to specify what to split on. Defaults to _%s+_.
        plain - An *optional boolean* that turns off pattern matching facilities if true. This
            should make it faster and allows you to specify strings that would otherwise need to be
            escaped. Defaults to _false_.
        limit - An *optional number* that if set, the returned table will contain a maximum of
            limit elements with the last element containing the rest of str. Defaults to
            _no limit_.

    Returns:

        A *table* containing the exploded str.

    Example:

        :Explode( "p1 p2 p3" )

        returns...

        :{ "p1", "p2", "p3" }

    Revisions:

        v1.0 - Initial
]]
function Explode( str, separator, plain, limit )
    separator = separator or "%s+"
    local t = {}
    local curpos = 1

    while true do -- We have a break in the loop
        local newpos, endpos = str:find( separator, curpos, plain ) -- Find the next separator in the string
        if newpos == nil or (limit and #t == limit - 1) then -- If no more separators or we hit our limit...
            table.insert( t, str:sub( curpos ) ) -- Save what's left in our string.
            break
        else -- If found then..
            table.insert( t, str:sub( curpos, newpos - 1 ) ) -- Save it in our table.
            curpos = endpos + 1 -- Save just after where we found it for searching next time.
        end
    end

    return t
end


--[[
    Function: Trim

    Trims leading and tailing whitespace from a string.

    Parameters:

        str - The *string* to trim.

    Returns:

        The stripped *string*.

    Revisions:

        v1.0 - Initial
]]
function Trim( str )
    -- Surrounded in paranthesis to return only the first argument
    return (str:gsub( "^%s*(.-)%s*$", "%1" ))
end


--[[
    Function: ParseArgs

    This is similar to <Explode> with ( str, "%s+" ) except that it will not split up words within
    quotation marks.

    Parameters:

        args - The input *string* to split from.

    Returns:

        1 - A *table* containing the individual arguments.
        2 - A *boolean* stating whether or not mismatched quotes were found.

    Example:

        :ParseArgs( "This is a \"Cool sentence to\" make \"split up\"" )

        returns...

        :{ "This", "is", "a", "Cool sentence to", "make", "split up" }

    Notes:

        * Mismatched quotes will result in having the last quote grouping the remaining input into
            one argument.
        * Arguments outside of quotes are trimmed (via <Trim>), while what's inside quotes is not
            trimmed at all.

    Revisions:

        v1.0 - Initial
]]
function ParseArgs( args )
    local argv = {}
    local curpos = 1 -- Our current position within the string
    local in_quote = false -- Is the text we're currently processing in a quote?
    local args_len = args:len()

    while curpos < args_len do
        local quotepos = args:find( "\"", curpos, true )

        -- The string up to the quote, the whole string if no quote was found
        local prefix = args:sub( curpos, (quotepos or 0) - 1 )
        if not in_quote then
            local t = Explode( Trim( prefix ) )
            AppendI( argv, t, true )
        else
            table.insert( argv, prefix )
        end

        -- If a quote was found, reduce our position and note our state
        if quotepos ~= nil then
            curpos = quotepos + 1
            in_quote = not in_quote
        else -- Otherwise we've processed the whole string now
            break
        end
    end

    return argv, in_quote
end

function Count( t )
    local c = 0
    for k, v in pairs( t ) do
        c = c+1
    end
    return c
end

local function CopyWith( iterator, t )
    local c = {}
    for k, v in iterator( t ) do
        c[ k ] = v
    end
    
    return c
end


--[[
    Function: Copy

    Make a shallow copy of a table. A shallow copy means that any subtables will still refer to the
    same table.

    Parameters:

        t - The *table* to make a copy of.

    Returns:

        The copied *table*.

    Revisions:

        v1.0 - Initial
]]
function Copy( t )
    return CopyWith( pairs, t )
end


--[[
    Function: CopyI

    Exactly the same as <Copy> except that it uses ipairs instead of pairs. In general, this means
    that it only copies numeric keys.
]]
function CopyI( t )
    return CopyWith( ipairs, t )
end

local function InPlaceHelper( iterator, table_a, in_place )
    if in_place then
        return table_a
    else
        return CopyWith( iterator, table_a )
    end
end

local function MergeWith( iterator, table_a, table_b, in_place )
    table_a = InPlaceHelper( iterator, table_a, in_place )

    for k, v in iterator( table_b ) do
        table_a[ k ] = v
    end

    return table_a
end


--[[
    Function: Merge

    Merges two tables by key. If both tables have values on the same key, table_b takes precedence.

    Parameters:

        table_a - The first *table* in the merge. If in_place is true, table_b is merged to this
            table.
        table_b - The second *table* in the merge.
        in_place - A *boolean* specifying whether or not this should be an in place merge to
            table_a. Defaults to _false_.

    Example:

        :Merge( { apple=red, pear=green, kiwi=hairy },
        :       { apple=green, pear=green, banana=yellow } )

        returns...

        :{ apple=green, pear=green, kiwi=hairy, banana=yellow }

    Returns:

        The merged *table*. Returns table_a if in_place is true, a new table otherwise.

    Revisions:

        v1.0 - Initial
]]
function Merge( table_a, table_b, in_place )
    return MergeWith( pairs, table_a, table_b, in_place )
end


--[[
    Function: MergeI

    Exactly the same as <Merge> except that it uses ipairs instead of pairs. In general, this means
    that it only merges on numeric keys.
]]
function MergeI( table_a, table_b, in_place )
    return MergeWith( ipairs, table_a, table_b, in_place )
end

local function AppendWith( iterator, table_a, table_b, in_place )
    local table_a = InPlaceHelper( iterator, table_a, in_place )

    for k, v in iterator( table_b ) do
        if type( k ) == "number" then
            table.insert( table_a, v )
        end
    end

    return table_a
end


--[[
    Function: Append

    Appends values with numeric keys from one table to another.

    Parameters:

        table_a - The first *table* in the append. If in_place is true, table_b is appended to this
            table. Values in this table will not change.
        table_b - The second *table* in the append.
        in_place - A *boolean* specifying whether or not this should be an in place append to
            table_a. Defaults to _false_.

    Returns:

        The *table* result of appending table_b to table_a. Returns table_a if in_place is true, a
            new table otherwise.

    Example:

        :Append( { "apple", "banana", "kiwi" },
        :        { "orange", "pear" } )

        returns...

        :{ "apple", "banana", "kiwi", "orange", "pear" }

    Revisions:

        v1.0 - Initial
]]
function Append( table_a, table_b, in_place )
    return AppendWith( pairs, table_a, table_b, in_place )
end


--[[
    Function: AppendI

    Exactly the same as <Append> except that it uses ipairs instead of pairs. In general, this
    means that it only appends on numeric keys.
]]
function AppendI( table_a, table_b, in_place )
    return AppendWith( ipairs, table_a, table_b, in_place )
end
