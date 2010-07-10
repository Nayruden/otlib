local PLUGIN = otlib.CreatePlugin( "Plugin Management", "This plugin lets you manage your plugins", "Nayruden" )

function PLUGIN:PluginList( user )
    for dummy, plugin in pairs( otlib.GetPlugins() ) do
        print( ("%s - %s by %s (%s)"):format( plugin.name, plugin.description, plugin.author, plugin.running and "running" or "stopped" ) )
    end
end
local list_access = otlib.access:Register( "plugin_list", otlib.GetGroup( "admin" ) )
PLUGIN:AddCommand( "plugin_list", nil, PLUGIN.PluginList, list_access )

function PLUGIN:PluginStop( user, plugin_name )
    plugin_name = plugin_name:lower()
    for dummy, plugin in pairs( otlib.GetPlugins() ) do
        if plugin.name:lower() == plugin_name then
            plugin:Stop()
            return
        end
    end
    
    print( plugin_name .. " not found" )
end
local stop_access = otlib.access:Register( "plugin_stop", otlib.GetGroup( "admin" ) )
stop_access:AddParam( otlib.StringParam():TakesRestOfLine( true ) )
PLUGIN:AddCommand( "plugin_stop", nil, PLUGIN.PluginStop, stop_access )

function PLUGIN:PluginStart( user, plugin_name )
    plugin_name = plugin_name:lower()
    for dummy, plugin in pairs( otlib.GetPlugins() ) do
        if plugin.name:lower() == plugin_name then
            plugin:Stop()
            dofile( plugin.path ) -- Reload
            plugin:Start()
            return
        end
    end
    
    print( plugin_name .. " not found" )
end
local start_access = otlib.access:Register( "plugin_start", otlib.GetGroup( "admin" ) )
start_access:AddParam( otlib.StringParam():TakesRestOfLine( true ) )
PLUGIN:AddCommand( "plugin_start", nil, PLUGIN.PluginStart, start_access )
