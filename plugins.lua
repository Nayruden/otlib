--- File: Plugins

--- Module: otlib
module( "otlib", package.seeall )

local plugins = {}

--- Group: Plugin Management


--[[
    Function: GetPlugins
    
    Returns:

        A *table* of the plugins, indexed by plugin name.

    Revisions:

        v1.00 - Initial.
]]
function GetPlugins()
    return plugins
end


--[[
    Function: InitPlugins
    
    Intended to be called only once by the application-specific implementation after running all
    plugin files. Initializes the plugins.

    Revisions:

        v1.00 - Initial.
]]
function InitPlugins()
    for plugin_name, plugin in pairs( plugins ) do
        plugin:Init()
        plugin:Start()
    end
end

local Plugin

--[[
    Function: CreatePlugin
    
    Creates a plugin by name. It's safe to call this function multiple times, it will return the
    'old' plugin table on successive calls.

    Parameters:

        name - The *string* name of the plugin. Try to keep it short.
        description - The *string* description of the plugin. What does it do?
        author - The *string* author of the plugin.

    Returns:

        The plugin *table*. You should stick any information you want to persist across plugin 
        reloads in this table since the same table will be kept across reloads. Any functions being
        called by commands also need to be put in this table.

    Revisions:

        v1.00 - Initial.
]]
function CreatePlugin( name, description, author )
    CheckArg( 1, "CreatePlugin", "string", name )
    CheckArg( 2, "CreatePlugin", "string", description )
    CheckArg( 3, "CreatePlugin", "string", author )
    
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

--- Object: otlib.Plugin
Plugin = object:Clone()


--[[
    Function: SetVersion
    
    Set the version and version suffix of the plugin.

    Parameters:

        version - The *number* that represents the version of the plugin.
        version_suffix - The *optional string* that represents the version suffix of the plugin. 
            IE, "Alpha".

    Returns:

        *Self*.

    Revisions:

        v1.00 - Initial.
]]
function Plugin:SetVersion( version, version_suffix )
    CheckArg( 1, "Plugin:SetVersion", "number", version )
    CheckArg( 2, "Plugin:SetVersion", {"nil", "string"}, version_suffix )
    
    self.version = version
    self.version_suffix = version_suffix
    
    return self
end


--[[
    Function: Init
    
    Override this function if you want to run some functionality when the plugin initializes. This
    function is called only once. There's no need to call the base implementation if overridden.

    Revisions:

        v1.00 - Initial.
]]
function Plugin:Init()
    -- Empty implementation
end


--[[
    Function: Start
    
    Start the plugin. This makes sure we're all hooked up to whatever we need to be.

    Revisions:

        v1.00 - Initial.
]]
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


--[[
    Function: Stop
    
    Stop the plugin.

    Revisions:

        v1.00 - Initial.
]]
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


--[[
    Function: AddCommand
    
    Adds a command on behalf of this plugin.

    Parameters:

        console_command - An *optional string* of the console command to add.
        say_command - An *optional string* of the say command to add.
        callback - The *function* to call if this command is called and passes access tests. The
            callback receives the player calling the command followed by the arguments specified in
            the access object.
        access - The *<otlib.access>* object associated with this command.

    Returns:

        *Self*.

    Revisions:

        v1.00 - Initial.
]]
function Plugin:AddCommand( console_command, say_command, callback, access )
    CheckArg( 1, "Plugin:AddCommand", {"nil", "string"}, console_command )
    CheckArg( 2, "Plugin:AddCommand", {"nil", "string"}, say_command )
    CheckArg( 3, "Plugin:AddCommand", "function", callback )
    -- TODO: check access type?
    if console_command then
        self.console_commands[ console_command ] = { callback=callback, access=access }
    end
    if say_command then
        self.say_commands[ say_command ] = { callback=callback, access=access }
    end
    
    return self
end


--[[
    Function: AddHook
    
    Adds a hook on behalf of this plugin.

    Parameters:

        hook - The application-specific hook id.
        callback - The *function* to call for this hook.
        priority - The priority of the hook. TODO more descriptive.

    Returns:

        *Self*.

    Revisions:

        v1.00 - Initial.
]]
function Plugin:AddHook( hook, callback, priority )
    CheckArg( 2, "Plugin:AddHook", "function", callback )
    table.insert( self.hooks, { hook=hook, callback=callback, priority=priority } )
    
    return self
end
