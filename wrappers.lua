--- File: Wrapper Functions
--- Blah.

--- Module: otlib
module( "otlib", package.seeall )

wrappers = {}

DatabaseTypes = {
    Flatfile = 'Flatfile',
    SQLite = 'SQLite',
    MySQL = 'MySQL',
}

function wrappers.FormatAndEscapeData( data )
    error( "unimplemented", 2 )
end

function wrappers.Execute( database_type, statement )
    error( "unimplemented", 2 )
end