--- File: Utilities
--- Table specific utilities are in the file <Table Utilities>.

--- Module: otlib
module( "otlib", package.seeall )


--- Group: String Utilities
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
        
    Notes:
    
        * If separator is the empty string (""), this function throws an error.

    Revisions:

        v1.00 - Initial.
]]
function Explode( str, separator, plain, limit )
    if separator == "" then 
        return error( "empty separator passed, would result in an infinite loop", 2 )
    end
    
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
        
    Notes:
    
        * This is 'trim6' from <http://lua-users.org/wiki/StringTrim>.

    Revisions:

        v1.00 - Initial.
]]
function Trim( str )
    return str:match( "^()%s*$" ) and '' or str:match( "^%s*(.*%S)" )
end


--[[
    Function: LTrim
    
    Exactly like <Trim> except it only trims the left side. Taken from 
    <http://lua-users.org/wiki/CommonFunctions>
    
    Revisions:
    
        v1.00 - Initial.
]]
function LTrim( str )
    return (str:gsub( "^%s*", '' ))
end


--[[
    Function: RTrim
    
    Exactly like <Trim> except it only trims the right side. Taken from 
    <http://lua-users.org/wiki/CommonFunctions>
    
    Revisions:
    
        v1.00 - Initial.
]]
function RTrim( str )
    local n = #str
    while n > 0 and str:find( "^%s", n ) do 
        n = n - 1
    end
    return str:sub( 1, n )
end


--[[
    Function: Escape

    Makes a string safe for pattern usage, like in string.gsub(). Basically replaces all keywords 
    with % and the keyword.

    Parameters:

        str - The string to make pattern safe.

    Returns:

        The pattern safe string.
]]
function Escape( str )
    -- Surrounded in paranthesis to return only the first argument
    return (str:gsub( "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1" ))
end


--[[
    Function: StripComments

    Strips comments from a string.

    Parameters:

        str - The input *string* to strip from.
        line_comment - The *string* of the comment to remove from str. Removes whenever it finds
            this text until the end of the line.

    Returns:

        A *string* of str with the comments removed.

    Example:

        :StripComments( "Line 1 # My comment\n#Line with only a comment\nLine 2", "#" )

        returns...

        :"Line 1 \n\nLine 2"
        
    Notes:

        * Only handles line comments, no block comments.
        * Does not parse the document, so it will remove even from inside quotation marks if it 
            finds line_comment inside them.

    Revisions:

        v1.00 - Initial.
]]
function StripComments( str, line_comment )
    -- Surrounded in paranthesis to return only the first argument
    return (str:gsub( Escape( line_comment ) .. "[^\r\n]*", "" ))
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

        :ParseArgs( 'This is a "Cool sentence to" make "split up"' )

        returns...

        :{ "This", "is", "a", "Cool sentence to", "make", "split up" }

    Notes:

        * Mismatched quotes will result in having the last quote grouping the remaining input into
            one argument.
        * Arguments outside of quotes are trimmed (via <Trim>), while what's inside quotes is not
            trimmed at all.

    Revisions:

        v1.00 - Initial.
]]
function ParseArgs( args )
    local argv = {}
    local curpos = 1 -- Our current position within the string
    local in_quote = false -- Is the text we're currently processing in a quote?
    local args_len = args:len()

    while curpos <= args_len or in_quote do
        local quotepos = args:find( '"', curpos, true )

        -- The string up to the quote, the whole string if no quote was found
        local prefix = args:sub( curpos, (quotepos or 0) - 1 )
        if not in_quote then
            local trimmed = Trim( prefix )
            if trimmed ~= "" then -- Something to be had from this...
                local t = Explode( Trim( prefix ) )
                Append( argv, t, true )
            end
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


--[[
    Function: EditDistance

    Finds the edit distance between two strings or tables. Edit distance is the minimum number of
    edits needed to transform one string or table into the other.
    
    Parameters:
    
        s - A *string* or *table*.
        t - Another *string* or *table* to compare against s.
        lim - An *optional number* to limit the function to a maximum edit distance. If specified
            and the function detects that the edit distance is going to be larger than limit, limit
            is returned immediately.
            
    Returns:
    
        A *number* specifying the minimum edits it takes to transform s into t or vice versa. Will
            not return a higher number than lim, if specified.
            
    Example:

        :EditDistance( "Tuesday", "Teusday" ) -- One transposition.
        :EditDistance( "kitten", "sitting" ) -- Two substitutions and a deletion.

        returns...

        :1
        :3
            
    Notes:
    
        * Complexity is O( (#t+1) * (#s+1) ) when lim isn't specified.
        * This function can be used to compare array-like tables as easily as strings.
        * The algorithm used is Damerau-Levenshtein distance, which calculates edit distance based
            off number of subsitutions, additions, deletions, and transpositions.
        * Source code for this function is based off the Wikipedia article for the algorithm
            <http://en.wikipedia.org/w/index.php?title=Damerau%E2%80%93Levenshtein_distance&oldid=351641537>.
        * This function is case sensitive when comparing strings.
        * If this function is being used several times a second, you should be taking advantage of
            the lim parameter.
        * Using this function to compare against a dictionary of 250,000 words took about 0.6
            seconds on my machine for the word "Teusday", around 10 seconds for very poorly 
            spelled words. Both tests used lim.
            
    Revisions:

        v1.00 - Initial.
]]
function EditDistance( s, t, lim )
    local s_len, t_len = #s, #t -- Calculate the sizes of the strings or arrays
    if lim and math.abs( s_len - t_len ) >= lim then -- If sizes differ by lim, we can stop here
        return lim
    end
    
    -- Convert string arguments to arrays of ints (ASCII values)
    if type( s ) == "string" then
        s = { string.byte( s, 1, s_len ) }
    end
    
    if type( t ) == "string" then
        t = { string.byte( t, 1, t_len ) }
    end
    
    local min = math.min -- Localize for performance
    local num_columns = t_len + 1 -- We use this a lot
    
    local d = {} -- (s_len+1) * (t_len+1) is going to be the size of this array
    -- This is technically a 2D array, but we're treating it as 1D. Remember that 2D access in the
    -- form my_2d_array[ i, j ] can be converted to my_1d_array[ i * num_columns + j ], where
    -- num_columns is the number of columns you had in the 2D array assuming row-major order and
    -- that row and column indices start at 0 (we're starting at 0).
    
    for i=0, s_len do
        d[ i * num_columns ] = i -- Initialize cost of deletion
    end
    for j=0, t_len do
        d[ j ] = j -- Initialize cost of insertion
    end
    
    for i=1, s_len do
        local i_pos = i * num_columns
        local best = lim -- Check to make sure something in this row will be below the limit
        for j=1, t_len do
            local add_cost = (s[ i ] ~= t[ j ] and 1 or 0)
            local val = min(
                d[ i_pos - num_columns + j ] + 1,                               -- Cost of deletion
                d[ i_pos + j - 1 ] + 1,                                         -- Cost of insertion
                d[ i_pos - num_columns + j - 1 ] + add_cost                     -- Cost of substitution, it might not cost anything if it's the same
            )
            d[ i_pos + j ] = val
            
            -- Is this eligible for tranposition?
            if i > 1 and j > 1 and s[ i ] == t[ j - 1 ] and s[ i - 1 ] == t[ j ] then
                d[ i_pos + j ] = min(
                    val,                                                        -- Current cost
                    d[ i_pos - num_columns - num_columns + j - 2 ] + add_cost   -- Cost of transposition
                )
            end
            
            if lim and val < best then
                best = val
            end
        end
        
        if lim and best >= lim then
            return lim
        end
    end
    
    return d[ #d ]
end


--[[
    Function: SplitCommentHeader
    
    Splits a comment header in a string. A comment header is defined as a block in a string where
    every non-blank line starts with a certain prefix, until a non-blank line is reached that
    doesn't start with the prefix.
    
    Parameters:
    
        str - The *string* to split the comment from.
        comment_prefix - The *optional string* comment prefix. Defaults to _";"_.
        
    Returns:
    
        1 - The comment header.
        2 - Everything after the comment header.
        
    Example:

        :SplitCommentHeader( ";Comment 1\n;Comment 2\nData 1\nData 2" )

        returns...

        :";Comment 1\n;Comment 2", "Data 1\nData2"
        
    Revisions:

        v1.00 - Initial.
]]
function SplitCommentHeader( str, comment_prefix )
    comment_prefix = comment_prefix or ";"
    comment_prefix_length = comment_prefix:len()
    local lines = Explode( str, "\n", true )
    local end_comment_line = 0
    -- for _, line in ipairs( lines ) do
    for i=1, #lines do
        local trimmed = Trim( lines[ i ] )
        if trimmed == "" or trimmed:sub( 1, comment_prefix_length ) == comment_prefix then
            end_comment_line = end_comment_line + 1
        else
            break
        end
    end
    
    local comment = RTrim( table.concat( lines, "\n", 1, end_comment_line ) )
    local not_comment = LTrim( table.concat( lines, "\n", end_comment_line + 1 ) )
    return comment, not_comment
end


--- Group: Numeric Utilities

--[[
    Function: Round

    Rounds a number to a given decimal place.

    Parameters:

        num - The *number* to round.
        places - The *optional number* of places to round to. 0 rounds to the nearest whole number,
            1 rounds to the nearest tenth, 2 rounds to the nearest thousandth, etc. Negative 
            numbers round into the non-fractional places; -1 rounds to the nearest tens, -2 rounds 
            to the nearest hundreds, etc. Defaults to _0_.

    Returns:

        The rounded *number*.
        
    Notes:
    
        * This is adapted from the ideas at <http://lua-users.org/wiki/SimpleRound>.

    Revisions:

        v1.00 - Initial.
]]
function Round( num, places )
    if places and places ~= 0 then
        local mult = 10 ^ places
        return math.floor( num * mult + 0.5 ) / mult
    else
        return math.floor( num + 0.5 )
    end
end


--- Group: Other Utilities
--- Things that don't fit in any other category.

--[[
    Function: ToBool

    Converts a boolean, nil, string, or number to a boolean value.

    Parameters:

        value - The *boolean, nil, string, or number* to convert.

    Returns:

        The converted *boolean* value.
        
    Notes:
    
        * This function favors returning true if it's not quite sure what to do.
        * 0, strings equating to 0, nil, false, "f", "false", "no", and "n" will all return false.

    Revisions:

        v1.00 - Initial.
]]
function ToBool( value )
    if type( value ) == "boolean" then 
        return value
    elseif value == nil then 
        return false
    elseif tonumber( value ) ~= nil then
        if tonumber( value ) == 0 then
            return false
        else
            return true
        end
    elseif type( value ) == "string" then
        value = value:lower()
        if value == "f" or value == "false" or value == "no" or value == "n" then
            return false
        else
            return true
        end
    end
    
    -- Shouldn't get here with the constraints on type, but just in case...
    return true
end

-- This is used for stored expression, below
local function call( self, ... )
    self.__index = { unpack = function() return unpack( self.__index, 1, self.n ) end, n = select( "#", ... ), ... }
    return ...
end


--[[
    Function: StoredExpression

    Creates an object that will store an expression.

    Returns:

        A *table* that can be called and accepts any number of arguments, then stores and returns 
            the arguments as given. You can access the arguments in the table by index, or retrieve
            the total number of aruments from field 'n'.
            
        A function 'unpack' is also defined for the returned table which returns each argument just
            like regular unpack does.
        
    Example:

        :ex = StoredExpression()
        :my_list = { "milk", "bread", "cookies", "eggs" }
        :if ex( HasValue( my_list, "cookies" ) ) then
        :   print( "cookies are item #" .. ex[ 2 ] .. " on my list" )
        :end
        :print( "there were " .. ex.n .. " variables passed back from HasValue" )

        prints...

        :cookies are item #3 on my list
        :there were 2 variables passed back from HasValue
        
    Notes:
    
        * This comes from <http://lua-users.org/wiki/StatementsInExpressions>. See this URL for a
            more detailed discussion on stored expressions.

    Revisions:

        v1.00 - Initial.
]]
function StoredExpression()
    local self = { __call = call }
    return setmetatable( self, self )
end


--[[
    Function: DataEqualsAnyOf

    Checks to see if an argument equals any of the other arguments passed in.
    
    Parameters:
    
        data - The data to test equality against.
        ... - All the other arguments, which get tested against data in successive order until a
            match is found or until we run out of arguments.

    Returns:

        A *boolean* stating whether or not any of the other arguments equaled the data argument.
        
    Example:
    
        This is a conveinence function so that instead of writing this...
        
        :if a == b or a == c or a == d then ... end
        
        You can write this...

        :if DataEqualsAnyOf( a, b, c, d ) then ... end

    Revisions:

        v1.00 - Initial.
]]
function DataEqualsAnyOf( data, ... )
    local argv = { ... }
    for i=1, select( "#", ... ) do
        if data == argv[ i ] then return true end
    end
    
    return false
end
