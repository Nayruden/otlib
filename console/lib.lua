module( "otlib", package.seeall )

function FilesInDir( dir_path )
    local files = {}
    for file in lfs.dir( dir_path ) do
        if not DataEqualsAnyOf( file, ".", ".." ) then
            table.insert( files, file )
        end
    end
    
    return files
end
