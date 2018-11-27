-- Forward declarations
local newEntry
local logMetatable

local function Level (s)
    return setmetatable({LEVEL = true}, {__tostring = function() return s end})
end

---------- Log Levels ----------
local NoLevel    = Level('no_level') -- Not meant to be used.
local TraceLevel = Level('trace')
local DebugLevel = Level('debug')
local InfoLevel  = Level('info')
local WarnLevel  = Level('warn')
local ErrorLevel = Level('error')
local FatalLevel = Level('fatal')
--------------------------------

local Entry  = {"ENTRY"}
local Logger = {"LOGGER"}

function newEntry (logger)
    local debugInfo = debug.getinfo(2, "Sl")

    local indexTable = {
            Logger  = logger,
            Fields  = {},
            Time    = os.date("%H:%M:%S"),
            Level   = NoLevel,
            Msg     = "",
            LineInf = debugInfo.short_src .. ":" .. debugInfo.currentline,

            print   = function(self, msg)
                self.Msg = msg
                self.Level = InfoLevel
                print(("%s[%-6s%s]%s %s: %s"):format(
                    "",
                    self.Level,
                    self.Time,
                    "",
                    self.LineInf,
                    self.Msg
                ))
            end,
    }

    return setmetatable(Entry, {
        __index = indexTable,
        __newindex = function(entry, key, value)
            if key == 'Level' then
                local value = value or NoLevel
                assert(value.LEVEL, 'Unexpected value for level')
                assert(value ~= NoLevel, 'Cannot set level to nil')

                indexTable.Level = value
            elseif key == 'Msg' then
                assert(type(value) == 'string', 'Expected a string.')

                indexTable.Msg = value
            end
        end,
    })
end

logMetatable = {
    __index = {
        TraceLevel = TraceLevel,
        DebugLevel = DebugLevel,
        InfoLevel  = InfoLevel,
        WarnLevel  = WarnLevel,
        ErrorLevel = ErrorLevel,
        FatalLevel = FatalLevel,

        newEntry = newEntry,
    },
}

return setmetatable({}, logMetatable)
