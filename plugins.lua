--- File: Plugins

--- Module: otlib
module( "otlib", package.seeall )

local plugins = {}

--- Group: Plugin Management

function GetPlugins()
    return plugins
end

function InitPlugins()
    for plugin_name, plugin in pairs( plugins ) do
        plugin:Init()
        plugin:Start()
    end
end

--- Group: Individual Plugin API

local Plugin = object:Clone()

function CreatePlugin( name, description, author )
    local plugin = Plugin:Clone()
    if plugins[ name ] then
        plugin = plugins[ name ]
    else
        assert( PLUGIN_PATH )
        plugin.path = PLUGIN_PATH
    end
    
    plugin.name = name
    plugin.description = description
    plugin.author = author
    plugin.console_commands = {}
    plugin.say_commands = {}
    plugin.hooks = {}
    
    plugins[ name ] = plugin
    
    return plugin
end

function Plugin:SetVersion( version )
    self.version = version
    
    return self
end

function Plugin:Init()
    -- Empty implementation
end

function Plugin:Start()
    for command_name, command_data in pairs( self.console_commands ) do
        wrappers.AddConsoleCommand( command_name, command_data.callback, command_data.access, self )
    end

    for command_name, command_data in pairs( self.say_commands ) do
        wrappers.AddSayCommand( command_name, command_data.callback, command_data.access, self )
    end
    
    self.running = true
    
    -- todo hooks
end

function Plugin:Stop()
    for command_name, command_data in pairs( self.console_commands ) do
        wrappers.RemoveConsoleCommand( command_name )
    end

    for command_name, command_data in pairs( self.say_commands ) do
        wrappers.RemoveSayCommand( command_name )
    end
    
    self.running = nil
    -- todo hooks
end

function Plugin:AddCommand( console_command, say_command, callback, access )
    if console_command then
        self.console_commands[ console_command ] = { callback=callback, access=access }
    end
    if say_command then
        self.say_commands[ say_command ] = { callback=callback, access=access }
    end
    
    return self
end

function Plugin:AddHook( hook, callback, priority )
    table.insert( self.hooks, { hook=hook, callback=callback, priority=priority } )
    
    return self
end
