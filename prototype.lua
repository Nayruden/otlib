--- File: Prototype Inheritance
--- See <http://en.wikipedia.org/wiki/Prototype_based_programming> for detailed information about
--- prototype inheritance.

--- Module: otlib
module( "otlib", package.seeall )


--[[
    Function: Clone
    
    Creates a clone of an object.
    
    Parameters:
    
        base - The *table* to clone from.
        clone - An *optional table* to set as a clone, this value is what is returned. Defaults to 
            an _empty table_.
            
    Returns:
    
        The *table* from the parameter clone.
        
    Revisions:

        v1.00 - Initial.
]]
function Clone( base, clone )
    clone = clone or {}
	local mt = getmetatable( clone ) or {}
    mt.__index = base
    setmetatable( clone, mt )
    return clone
end


--[[
    Function: Parent
    
    Gets the parent of a clone.
    
    Parameters:
    
        clone - The *table* clone that you want to know about.
            
    Returns:
    
        A *table or nil* specifying the parent, nil if no parent.
        
    Revisions:

        v1.00 - Initial.
]]
function Parent( clone )
    local mt = getmetatable( clone )
    return mt and mt.__index
end


--[[
    Function: IsA
    
    Check if a clone is inherited from another.
    
    Parameters:
    
        clone - The *table* clone that you want to know about.
        base - The *table* clone to check against.
            
    Returns:
    
        A *boolean* specifying whether or not clone is inherited from base.
        
    Notes:
    
        * Returns true if the tables are equal to each other (since a derived class IS A derived 
            class, it makes sense).
        
    Revisions:

        v1.00 - Initial.
]]
function IsA( clone, base )
    if clone == base then 
        return true
    end
    
    local mt = getmetatable( clone )
    while mt ~= nil and mt.__index ~= nil do
        local index = mt.__index
        if index == base then 
            return true
        end
        mt = getmetatable( index )
    end
    
    return false
end


--[[
    Object: otlib.object
    
    Merely serves as a convenient wrapper and root prototype.
]]
object = Clone( table, { Clone = Clone, IsA = IsA, Parent=Parent } )
--[[
    Functions: otlib.object
    
        Clone - Exactly the same as <otlib.Clone>.
        IsA - Exactly the same as <otlib.IsA>.
        Parent - Exactly the same as <otlib.Parent>.
]]
