local std_print = print

-- Forward declarations
local newEntry, newLogger, print, printf
local loggerMetatable

local function Level (s)
    return setmetatable({LEVEL = true}, {__tostring = function() return s end})
end

---------- Log Levels ----------
local Levels = {
    NoLevel = Level('NO_LEVEL'), -- Not meant to be used.
    Trace   = Level('TRACE'),
    Debug   = Level('DEBUG'),
    Info    = Level('INFO'),
    Warn    = Level('WARN'),
    Error   = Level('ERROR'),
    Fatal   = Level('FATAL'),
}
--------------------------------

local Entry  = {"ENTRY"}
local Logger = {"LOGGER"}

function newLogger()
    return setmetatable(Logger, loggerMetatable)
end

function newEntry (opts)
    local opts = opts or {}
    local debugInfo = debug.getinfo(opts.n or 3, "Sl")

    local indexTable = {
            Fields  = opts.Fields or {},
            Time    = opts.Time or os.date("%H:%M:%S"),
            Level   = opts.Level or Levels.NoLevel,
            Msg     = opts.Msg or "",
            LineInf = opts.LineInf or debugInfo.short_src .. ":" .. debugInfo.currentline,
    }

    return setmetatable(Entry, {
        __index = indexTable,
        __newindex = function(entry, key, value)
            if key == 'Level' then
                local value = value or Levels.NoLevel
                assert(value.LEVEL, 'Unexpected value for level')
                assert(value ~= Levels.NoLevel, 'Cannot set level to nil')

                indexTable.Level = value
            elseif key == 'Msg' then
                assert(type(value) == 'string', 'Expected a string.')

                indexTable.Msg = value
            end
        end,
    })
end

function print(logger, entry)
    std_print(("%s[%-6s%s]%s %s: %s"):format(
        "",
        entry.Level,
        entry.Time,
        "",
        entry.LineInf,
        entry.Msg
    ))
end

local msgFuncs = {}
for name, level in next, Levels do
    if level ~= Levels.NoLevel then
        msgFuncs[name] = function(logger, msg)
            print(logger, newEntry({
                Msg = msg,
                Level = level,
            }))
        end

        msgFuncs[name..'f'] = function(logger, msg, ...)
            print(logger, newEntry({
                Msg = msg:format(unpack({...})),
                Level = level,
            }))
        end
    end
end

-- This table is manually written to make the API clear.
loggerMetatable = {
    __index = {
        TraceLevel = Levels.Trace,
        DebugLevel = Levels.Debug,
        InfoLevel  = Levels.Info,
        WarnLevel  = Levels.Warn,
        ErrorLevel = Levels.Error,
        FatalLevel = Levels.Fatal,

        new     = newLogger,
        
        Trace   = msgFuncs.Trace,
        Debug   = msgFuncs.Debug,
        Info    = msgFuncs.Info,
        Warn    = msgFuncs.Warn,
        Warning = msgFuncs.Warning,
        Error   = msgFuncs.Error,
        Fatal   = msgFuncs.Fatal,

        Tracef  = msgFuncs.Tracef,
        Debugf  = msgFuncs.Debugf,
        Infof   = msgFuncs.Infof,
        Warnf   = msgFuncs.Warnf,
        Warningf= msgFuncs.Warnf,
        Errorf  = msgFuncs.Errorf,
        Fatalf  = msgFuncs.Fatalf,
    },
}

return newLogger()
