-- Standard Library Functions
local std_print = print
local debugInfo = debug.getinfo

-- Forward declarations
local newEntry, newLogger, print, setFormatter
local defaultLogger, loggerMetatable, formatters, loggerToFormatter

local function Level (s)
    return setmetatable({LEVEL = true}, {__tostring = function() return s end})
end

---------- Log Levels ----------
local Levels = {
    NoLevel = Level('NO_LEVEL'),
    Trace   = Level('TRACE'),
    Debug   = Level('DEBUG'),
    Info    = Level('INFO'),
    Warn    = Level('WARN'),
    Error   = Level('ERROR'),
    Fatal   = Level('FATAL'),
}
--------------------------------

local Colors = {}
Colors[Levels.NoLevel] = '\27[0m'
Colors[Levels.Trace]   = '\27[0;34m'
Colors[Levels.Debug]   = '\27[0;36m'
Colors[Levels.Info]    = '\27[0;92m'
Colors[Levels.Warn]    = '\27[0;33m'
Colors[Levels.Error]   = '\27[0;91m'
Colors[Levels.Fatal]   = '\27[0;31m'

local msgFuncs = {}
for name, level in next, Levels do
    if level ~= Levels.NoLevel then
        msgFuncs[name] = function(logger, msg)
            local msg = msg
            if type(logger) == 'string' and msg == nil then
                msg = logger
                logger = defaultLogger
            end

            print(newEntry(logger, {
                Msg = msg,
                Level = level,
            }))
        end

        msgFuncs[name..'f'] = function(logger, msg, ...)
            local msg = msg
            if type(logger) == 'string' and msg == nil then
                msg = logger
                logger = defaultLogger
            end
            
            print(newEntry(logger, {
                Msg = msg:format(unpack({...})),
                Level = level,
            }))
        end
    end
end


-- Custom 'types'
local Entry  = {"ENTRY"}
local Logger = {"LOGGER"}

function newLogger(formatter)
    local formatter = formatter or formatters.text
    local logger = setmetatable(Logger, loggerMetatable)
    setFormatter(logger, formatter)

    return logger
end

function newEntry (logger, opts)
    local opts = opts or {}
    local info = debugInfo(3, "Sl")

    local indexTable = {
            Logger  = logger,
            Fields  = opts.Fields or {},
            Time    = opts.Time or os.date(logger.dateFormat),
            Level   = opts.Level or Levels.NoLevel,
            Msg     = opts.Msg or "",
            LineInf = opts.LineInf or info.short_src .. ":" .. info.currentline,
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

function print(entry)
    std_print(loggerToFormatter[entry.Logger](entry))
end

loggerToFormatter = {}
function setFormatter(logger, f)
    if type(f) == 'function' then
        loggerToFormatter[logger] = f
    elseif type(f) == 'string' then
        f = formatters[f:lower()]
        if f == nil then return end
        loggerToFormatter[logger] = f
    end
end

formatters = {}
function formatters.text(entry)
    return ("%s[%-6s%s]%s %s: %s"):format(
        Colors[entry.Level],
        entry.Level,
        entry.Time,
        Colors[Levels.NoLevel],
        entry.LineInf,
        entry.Msg
    )
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

        dateFormat = "%H:%M:%S",

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

    __newindex = function(logger, key, value)
        if key == 'format' then
            setFormatter(logger, value)
        end
    end,
}

defaultLogger = newLogger()
return defaultLogger
