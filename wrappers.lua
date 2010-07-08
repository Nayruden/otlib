--[[
    File: Wrapper Functions
    
    This file is to offer a little bit of coherence to our scripts. Since we'll be dealing with all
    sorts of environments and setups, anything we need that might vary is defined as a wrapper stub
    below. All of these functions should be defined for every application implementation.
]]

--- Module: wrappers
module( "wrappers", package.seeall )


--- Group: SQL Wrapper Functions

--[[
    Function: FormatAndEscapeData

    Formats and escapes data from lua to be appropriate for use in SQL. This function must quote
    and escape strings as well as handle nil and numbers. For numbers, you probably want to pass it
    right back as a string. For nil, you probably want to return "NULL".

    Parameters:

        data - The data that can be a *string*, *number*, or *nil*. Any other type is an error
            condition.

    Returns:

        The *string* of the formatted and escaped data.

    Revisions:

        v1.00 - Initial.
]]
function FormatAndEscapeData( data )
    error( "unimplemented", 2 )
end


--[[
    Function: Execute

    Execute given statement on the database. Note that we assume that there is only one database,
    and we're automatically connected to it.

    Parameters:

        database_type - The *database type* to execute this statement on. See 
            <otlib.DatabaseTypes>.
        statement - The *string* to execute on the database. If the statement doesn't execute
            properly, raise an error.
        key_types - An *optional table* indexed by row-key string name with lua string type values
            (IE, "number"). This is here in case you're dealing with a poor SQL implementation and
            need to convert datatypes yourself.

    Returns:

        *Nil* if it wasn't a select operation, a *list table* of selected data otherwise.

    Revisions:

        v1.00 - Initial.
]]
function Execute( database_type, statement, key_types )
    error( "unimplemented", 2 )
end


--[[
    Function: BeginTransaction

    If the SQL implementation allows it, start a transaction. Otherwise, implement this as an empty
    function.

    Revisions:

        v1.00 - Initial.
]]
function BeginTransaction( database_type )
    error( "unimplemented", 2 )
end


--[[
    Function: EndTransaction

    If the SQL implementation allows it, end a transaction. Otherwise, implement this as an empty
    function.

    Revisions:

        v1.00 - Initial.
]]
function EndTransaction( database_type )
    error( "unimplemented", 2 )
end


--[[
    Function: BeginTransaction

    Get the number of affected rows from the last statement executed.
    
    Returns:
    
        The *number* of rows affected.

    Revisions:

        v1.00 - Initial.
]]
function AffectedRows()
    error( "unimplemented", 2 )
end


-- Group: File Wrapper Functions

--[[
    Function: FileExists

    Check to see if a file or folder exists.

    Parameters:

        file_name - The file name *string*.

    Returns:

        A *boolean* indicating whether or not the file or folder exists.

    Revisions:

        v1.00 - Initial.
]]
function FileExists( file_name )
    error( "unimplemented", 2 )
end


--[[
    Function: FileRead

    Read a file.

    Parameters:

        file_name - The file name *string*.

    Returns:

        The *string* of the file contents. Returns an empty string if the file doesn't exists.

    Revisions:

        v1.00 - Initial.
]]
function FileRead( file_name )
    error( "unimplemented", 2 )
end


--[[
    Function: FileWrite

    Write to a file. Should clear the contents of any existing file first.

    Parameters:

        file_name - The file name *string*.
        data - The *string* to write to the file.

    Revisions:

        v1.00 - Initial.
]]
function FileWrite( file_name, data )
    error( "unimplemented", 2 )
end


--[[
    Function: FileDelete

    Delete a file or folder. Should only delete empty directories.

    Parameters:

        file_name - The file name *string*.

    Revisions:

        v1.00 - Initial.
]]
function FileDelete( file_name )
    error( "unimplemented", 2 )
end
