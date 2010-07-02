--- File: Table Utilities
--- Utility functions that deal specifically with tables.

--- Module: otlib
module( "otlib", package.seeall )


--[[
    Topic: A Discussion On fori
    
    We define fori as the following type of loop where t is the table you're iterating over:
    :for i=1, #t do body end
    
    fori is much faster than pairs when you're iterating over a table with only numeric keys. The 
    catch is that it must be sequential numeric keys starting at 1. Even with this restriction, it
    is still very much worthwhile to use fori to iterate over the table instead of pairs if you 
    have a table that meets the requirements to use fori.
    
    Because of all this, OTLib lets you make a choice between using pairs or fori on anything
    that would make sense to have the choice. Any function that has the same name as another
    function but is just suffixed with the character "I" uses fori where the function that is not
    suffixed uses pairs as its iterator. For example, <Copy> and <CopyI>. One should use <CopyI>
    instead of <Copy> whenever the table being copied is known to be a list-like table with
    sequential numeric keys starting at 1.
    
    A quirk with a simple fori iteration is that you might pick up "gaps" in the table where the
    keys are not all sequential, but continues on with a later key anyways. Ideally, you shouldn't
    be passing around data like that unless you have a really good reason, but to partially combat
    this issue our code that uses fori on tables generally looks like the following:
    
    :for i=1, #t do
    :    if t[ i ] ~= nil then
    :        body
    :    end
    :end
    
    This prevents us from working with empty slots in the table. However, keep in mind that the way
    Lua implements tables means that if you have gaps in your table, a fori loop might not pick up
    all that data you want it to.
]]


--[[
    Function: Count

    Counts the number of elements in a table using pairs.

    Parameters:

        t - The *table* to count.

    Returns:

        The *number* of elements in the table.
        
    Example:
    
        :Count( { "apple", "pear", done=true, banana="yellow" } )
        
        returns...
        
        :4
        
    Notes:
    
        * This is slow and should be avoided if at all possible.
        * Use the '#' operator instead of this if the table only contains numeric indices or if you
            you only care about the numeric indices.
        * Use <IsEmpty> instead of this if you only want to see if a hash table has any values.
        * Complexity is O( n ), where n is the number of values in t.

    Revisions:

        v1.00 - Initial.
]]
function Count( t )
    local c = 0
    for k, v in pairs( t ) do
        c = c+1
    end
    
    return c
end


--[[
    Function: IsEmpty
    
    Checks if a table contains any values on any type of key.
    
    Parameters:
        
        t - The *table* to check.
        
    Returns:
    
        A *boolean*, true if the table t has one or more values, false otherwise.
        
    Notes:
        
        * This is much faster than <Count> for checking if a table has any elements, but you should
            still use the '#' operator instead of this if you only care about numeric indices.
        * Complexity is O( 1 ).
        
    Revisions:

        v1.00 - Initial.
]]
function IsEmpty( t )
    return next( t ) == nil
end


--[[
    Function: Copy

    Make a shallow copy of a table. A shallow copy means that any subtables will still refer to the
    same table.

    Parameters:

        t - The *table* to make a copy of.

    Returns:

        The copied *table*.
        
    Notes:
        
        * Complexity is O( Count( t ) ).

    Revisions:

        v1.00 - Initial.
]]
function Copy( t )
    local c = {}
    for k, v in pairs( t ) do
        c[ k ] = v
    end
    
    return c
end


--[[
    Function: CopyI

    Exactly the same as <Copy> except that it uses fori instead of pairs. In general, this means
    that it only copies numeric keys. See <A Discussion On fori>.
]]
function CopyI( t )
    local c = {}
    for i=1, #t do
        c[ i ] = t[ i ]
    end
    
    return c
end

local function InPlaceHelper( t, in_place )
    if in_place then
        return t
    else
        return Copy( t )
    end
end

local function InPlaceHelperI( t, in_place )
    if in_place then
        return t
    else
        return CopyI( t )
    end
end


--[[
    Function: RemoveDuplicateValues

    Removes any duplicate values from a list.

    Parameters:

        list - The *list table* to remove duplciates from.
        in_place - An *optional boolean* specifying whether or not the deletions should be done in 
            place to table_a. Defaults to _false_.

    Returns:

        The *list table* with duplicates removed. Returns t if in_place is true, a new table
            otherwise.
            
    Example:
    
        :RemoveDuplicateValues( { "apple", "pear", "kiwi", "apple", "banana", "pear", "pear" } )
        
        returns...
        
        :{ "apple", "pear", "kiwi", "banana" }
        
    Notes:
        
        * This function operates over numeric indices. See <A Discussion On fori>.
        * Complexity is around O( #t * log( #t ) ).
        * Duplicates are removed after the first value occurs. See example above.

    Revisions:

        v1.00 - Initial.
]]
function RemoveDuplicateValues( list, in_place )
    list = InPlaceHelperI( list, in_place )
    
    local i = 1
    local v = list[ i ]
    while v ~= nil do
        for j=1, i-1 do
            if list[ j ] == v then
                table.remove( list, i )
                i = i - 1 -- Since we removed it and it will be incremented below otherwise
                break
            end
        end
        i = i + 1
        v = list[ i ]
    end
    
    return list
end


--[[
    Function: UnionByKey

    Merges two tables by key.

    Parameters:

        table_a - The first *table* in the union. If in_place is true, all operations occur on 
            this table, if in_place is false, all operations occur on a copy of the table.
        table_b - The second *table* in the union.
        in_place - An *optional boolean* specifying whether or not this should be an in place union
            to table_a. Defaults to _false_.

    Returns:

        The union *table*. Returns table_a if in_place is true, a new table otherwise.
        
    Example:

        :UnionByKey( { apple="red", pear="green", kiwi="hairy" },
        :       { apple="green", pear="green", banana="yellow" } )

        returns...

        :{ apple="green", pear="green", kiwi="hairy", banana="yellow" }
        
    Notes:
    
        * If both tables have values on the same key, table_b takes precedence.
        * Complexity is O( Count( table_b ) ).

    Revisions:

        v1.00 - Initial.
]]
function UnionByKey( table_a, table_b, in_place )
    table_a = InPlaceHelper( table_a, in_place )

    for k, v in pairs( table_b ) do
        table_a[ k ] = v
    end

    return table_a
end


--[[
    Function: UnionByKeyI

    Exactly the same as <UnionByKey> except that it uses fori instead of pairs. In general, this
    means that it only merges on numeric keys. See <A Discussion On fori>.
]]
function UnionByKeyI( table_a, table_b, in_place )
    table_a = InPlaceHelperI( table_a, in_place )

    for i=1, #table_b do
        if table_b[ i ] ~= nil then
            table_a[ i ] = table_b[ i ]
        end
    end

    return table_a
end


--[[
    Function: UnionByValue

    Gets the union of two lists by value. If a value occurs once in list_a and once in list_b, the
    result of the union will only occur one instance of that value as well.

    Parameters:

        list_a - The first *list table* in the union. If in_place is true, all operations occur on
            this table, if in_place is false, all operations occur on a copy of the table.
        list_b - The second *list table* in the union.
        in_place - An *optional boolean* specifying whether or not this should be an in place union to
            table_a. Defaults to _false_.

    Returns:

        The union *list table*. Returns table_a if in_place is true, a new table otherwise.
        
    Example:

        :UnionByValue( { "apple", "pear", "kiwi" }, { "pear", "apple", "banana" } )

        returns...

        :{ "apple", "pear", "kiwi", "banana" }
        
    Notes:

        * This function operates over numeric indices. See <A Discussion On fori>.
        * The elements that in the returned table are in the same order they were in 
            table_a and then table_b. See example above.
        * This function properly handles duplicate values in either list. All values will be
            unique in the resulting list.
        * Complexity is O( #table_a * #table_b ), so you might want to consider using <SetFromList>
            combined with <UnionByKey> for large tables or if you plan on doing this often.        

    Revisions:

        v1.00 - Initial.
]]
function UnionByValue( list_a, list_b, in_place )
    list_a = RemoveDuplicateValues( list_a, in_place )
    
    local i = 1
    local v = list_b[ i ]
    while v ~= nil do
        if not HasValueI( list_a, v ) then
            table.insert( list_a, v )
        end
        i = i + 1
        v = list_b[ i ]
    end
    
    return list_a
end


--[[
    Function: IntersectionByKey

    Gets the intersection of two tables by key.

    Parameters:

        table_a - The first *table* in the intersection. If in_place is true, all operations occur 
            on this table, if in_place is false, all operations occur on a copy of the table.
        table_b - The second *table* in the interesection.
        in_place - An *optional boolean* specifying whether or not this should be an in place 
            intersection to table_a. Defaults to _false_.

    Returns:

        The intersection *table*. Returns table_a if in_place is true, a new table otherwise.
        
    Example:

        :IntersectionByKey( { apple="red", pear="green", kiwi="hairy" },
        :       { apple="green", pear="green", banana="yellow" } )

        returns...

        :{ apple="green", pear="green" }
        
    Notes:
        
        * If both tables have values on the same key, table_b takes precedence.
        * Complexity is O( Count( table_a ) ).

    Revisions:

        v1.00 - Initial.
]]
function IntersectionByKey( table_a, table_b, in_place )
    local result
    if not in_place then
        result = {}
    else
        result = table_a
    end
    
    -- Now just fill in each value with whatever the value in table_k is. This takes care of both
    -- elimination and making table b take precedence when both tables have a value on key k.
    for k, v in pairs( table_a ) do
        result[ k ] = table_b[ k ]
    end
    
    return result
end


--[[
    Function: IntersectionByKeyI

    Exactly the same as <IntersectionByKey> except that it uses fori instead of pairs. In 
    general, this means that it only merges on numeric keys. See <A Discussion On fori>.
]]
function IntersectionByKeyI( table_a, table_b, in_place )
    local result
    if not in_place then
        result = {}
    else
        result = table_a
    end
    
    -- Now just fill in each value with whatever the value in table_k is. This takes care of both
    -- elimination and making table b take precedence when both tables have a value on key k.
    for i=1, #table_a do
        if table_a[ i ] ~= nil then
            result[ i ] = table_b[ i ]
        end
    end
    
    return result
end


--[[
    Function: IntersectionByValue

    Gets the intersection of two lists by value.

    Parameters:

        list_a - The first *list table* in the intersection. If in_place is true, all operations 
            occur on this table, if in_place is false, all operations occur on a copy of the table.
        list_b - The second *list table* in the interesection.
        in_place - An *optional boolean* specifying whether or not this should be an in place 
            intersection to table_a. Defaults to _false_.

    Returns:

        The intersection *list table*. Returns table_a if in_place is true, a new table otherwise.
        
    Example:

        :IntersectionByValue( { "apple", "pear", "kiwi" }, { "pear", "apple", "banana" } )

        returns...

        :{ "apple", "pear" }
        
    Notes:

        * This function operates over numeric indices. See <A Discussion On fori>.
        * The elements that are left in the returned table are in the same order they were in 
            table_a. See example above.
        * This function properly handles duplicate values in either list. All values will be
            unique in the resulting list.
        * Complexity is O( #table_a * #table_b ), so you might want to consider using <SetFromList>
            combined with <IntersectionByKey> for large tables or if you plan on doing this often.

    Revisions:

        v1.00 - Initial.
]]
function IntersectionByValue( list_a, list_b, in_place )
    list_a = RemoveDuplicateValues( list_a, in_place )
    
    local i = 1
    local v = list_a[ i ]
    while v ~= nil do
        if HasValueI( list_b, v ) then
            i = i + 1            
        else
            table.remove( list_a, i )
        end
        v = list_a[ i ]
    end
    
    return list_a
end


--[[
    Function: DifferenceByKey

    Gets the difference of two tables by key. Difference is defined as all the keys in table A that
    are not in table B.

    Parameters:

        table_a - The first *table* in the difference. If in_place is true, all operations occur
            on this table, if in_place is false, all operations occur on a copy of the table.
        table_b - The second *table* in the difference.
        in_place - An *optional boolean* specifying whether or not this should be an in place 
            difference operation on table_a. Defaults to _false_.

    Returns:

        The difference *table*. Returns table_a if in_place is true, a new table otherwise.
        
    Example:

        :DifferenceByKey( { apple="red", pear="green", kiwi="hairy" },
        :            { apple="green", pear="green", banana="yellow" } )

        returns...

        :{ kiwi="hairy" }
        
    Notes:

        * Complexity is O( Count( table_a ) ).

    Revisions:

        v1.00 - Initial.
]]
function DifferenceByKey( table_a, table_b, in_place )
    table_a = InPlaceHelper( table_a, in_place )
    
    for k, v in pairs( table_b ) do
        table_a[ k ] = nil
    end
    
    return table_a
end


--[[
    Function: DifferenceByKeyI

    Exactly the same as <DifferenceByKey> except that it uses fori instead of pairs. In general,
    this means that it only performs the difference on numeric keys. See <A Discussion On fori>.
]]
function DifferenceByKeyI( table_a, table_b, in_place )
    table_a = InPlaceHelperI( table_a, in_place )
    
    for i=1, #table_b do
        if table_b[ i ] ~= nil then
            table_a[ i ] = nil
        end
    end
    
    return table_a
end


--[[
    Function: DifferenceByValue

    Gets the difference of two lists by value.

    Parameters:

        list_a - The first *list table* in the difference. If in_place is true, all operations 
            occur on this table, if in_place is false, all operations occur on a copy of the table.
        list_b - The second *list table* in the difference.
        in_place - An *optional boolean* specifying whether or not this should be an in place 
            difference operation on table_a. Defaults to _false_.
            
    Returns:

        The difference *list table*. Returns table_a if in_place is true, a new table otherwise.
        
    Example:

        :DifferenceByValue( { "apple", "pear", "kiwi" }, { "pear", "apple", "banana" } )

        returns...

        :{ "kiwi" }

        
    Notes:

        * This function operates over numeric indices. See <A Discussion On fori>.
        * The elements that are left in the returned table are in the same order they were in 
            table_a. See example above.
        * This function properly handles duplicate values in either list. All values will be
            unique in the resulting list.
        * Complexity is O( #table_a * #table_b ), so you might want to consider using <SetFromList>
            combined with <DifferenceByKey> for large tables or if you plan on doing this often.

    Revisions:

        v1.00 - Initial.
]]
function DifferenceByValue( list_a, list_b, in_place )
    list_a = InPlaceHelper( list_a, in_place )
    
    local i = 1
    local v = list_b[ i ]
    local has_value, index_value
    while v ~= nil do
        has_value, index_value = HasValueI( list_a, v )
        while has_value do
            table.remove( list_a, index_value )
            has_value, index_value = HasValueI( list_a, v )
        end
        i = i + 1
        v = list_b[ i ]
    end
    
    return list_a
end


--[[
    Function: SetFromList
    
    Creates a set from a list. A list is defined as a table with all numeric keys in sequential
    order (such as {"red", "yellow", "green"}). A set is defined as a table that only uses the
    boolean value true for keys that exist in the table. This function takes the values from the
    list and makes them the keys in a set, all with the value of 'true'. Note that you lose
    ordering and duplicates in the list during this conversion, but gain ease of testing for a 
    value's existence in the table (test whether the value of a key is true or nil).
    
    Parameters:
    
        list - The *table* representing the list.
        
    Returns:
    
        The *table* representing the set.
        
    Example:

        :SetFromList( { "apple", "banana", "kiwi", "pear" } )

        returns...

        :{ apple=true, banana=true, kiwi=true, pear=true }
        
    Notes:

        * This function uses fori during the conversion process. See <A Discussion On fori>.
        * Complexity is O( #list )
        
    Revisions:

        v1.00 - Initial.
]]
function SetFromList( list )
    local result = {}
    
    for i=1, #list do
        if list[ i ] ~= nil then
            result[ list[ i ] ] = true
        end
    end
    
    return result
end


--[[
    Function: Append

    Appends values with numeric keys from one table to another.

    Parameters:

        list_a - The first *list table* in the append. If in_place is true, table_b is appended to this
            table. Values in this table will not change.
        list_b - The second *list table* in the append.
        in_place - An *optional boolean* specifying whether or not this should be an in place append to
            table_a. Defaults to _false_.

    Returns:

        The *table* result of appending table_b to table_a. Returns table_a if in_place is true, a
            new table otherwise.

    Example:

        :Append( { "apple", "banana", "kiwi" },
        :        { "orange", "pear" } )

        returns...

        :{ "apple", "banana", "kiwi", "orange", "pear" }
        
    Notes:

        * This function uses fori. See <A Discussion On fori>.
        * Complexity is O( #list_b )

    Revisions:

        v1.00 - Initial.
]]
function Append( list_a, list_b, in_place )
    local list_a = InPlaceHelper( list_a, in_place )

    for i=1, #list_b do
        if list_b[ i ] ~= nil then
            table.insert( list_a, list_b[ i ] )
        end
    end

    return list_a
end


--[[
    Function: HasValue

    Checks for the presence of a value in a table.

    Parameters:

        t - The *table* to check for the value's presence within.
        value - *Any type*, the value to check for within t.
        
    Returns:

        1 - A *boolean*. True if the table has the value, false otherwise.
        2 - A value of *any type*. The first key the value was found under if it was found, nil 
            otherwise.

    Example:

        :HasValue( { apple="red", pear="green", kiwi="hairy" }, "green" )

        returns...

        :true, "pear"

    Revisions:

        v1.00 - Initial.
]]
function HasValue( t, value )
    for k, v in pairs( t ) do
        if v == value then
            return true, k
        end
    end
    
    return false, nil
end


--[[
    Function: HasValueI

    Exactly the same as <HasValue> except that it uses fori instead of pairs. In general, 
    this means that it only merges on numeric keys. See <A Discussion On fori>.
]]
function HasValueI( t, value )
    for i=1, #t do
        if t[ i ] == value then
            return true, i
        end
    end
    
    return false, nil
end
