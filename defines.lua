--- File: Defines
--- Blah.

--- Module: otlib
module( "otlib", package.seeall )

Version = 1.0
VersionSuffix = "Pre-Alpha"

ErrorMessages = {}
ErrorMessages.NotImplemented = "this function has not been implemented"


--[[
    Variables: DatabaseTypes
    
    Flatfile - A plain text, readable text file.
    SQLite - SQLite.
    MySQL - MySQL.
]]
DatabaseTypes = {
    Flatfile = 'Flatfile',
    SQLite = 'SQLite',
    MySQL = 'MySQL',
}
