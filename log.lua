-- Standard Library Functions
local std_print = print
local debugInfo = debug.getinfo

-- Forward declarations
local newEntry, newLogger, print, setFormatter, withFields
local defaultLogger, loggerMetatable, formatters

-- Custom 'types'
local Entry  = {"ENTRY"}
local Logger = {"LOGGER"}

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
    local function resolveArguments(arg1, arg2)
        if arg1 == Entry then
            return nil, arg2, arg1
        elseif type(arg1) == 'string' and arg2 == nil then
            return defaultLogger, arg1
        end
        return arg1, arg2
    end

    if level ~= Levels.NoLevel then
        msgFuncs[name] = function(logger, msg)
            local logger, msg, entry = resolveArguments(logger,msg)
            entry = entry or newEntry(logger, {})

            entry.Msg = msg
            entry.Level = level
            print(entry)
        end

        msgFuncs[name..'f'] = function(logger, msg, ...)
            local logger, msg = resolveArguments(logger,msg)

            print(newEntry(logger, {
                Msg = msg:format(unpack({...})),
                Level = level,
            }))
        end
    end
end

function newLogger()
    return setmetatable(Logger, loggerMetatable)
end

function newEntry (logger, opts)
    local opts = opts or {}
    local info = debugInfo(opts.n or 3, "Sl")

    local indexTable = {
            Logger  = logger,
            Fields  = opts.Fields or {},
            Time    = opts.Time or os.date(logger.dateFormat),
            Level   = opts.Level or Levels.NoLevel,
            Msg     = opts.Msg or "",
            LineInf = opts.LineInf or info.short_src .. ":" .. info.currentline,

            Trace   = msgFuncs.Trace,
            Debug   = msgFuncs.Debug,
            Info    = msgFuncs.Info,
            Warn    = msgFuncs.Warn,
            Warning = msgFuncs.Warning,
            Error   = msgFuncs.Error,
            Fatal   = msgFuncs.Fatal,
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

function withFields(logger, fields )
    return newEntry(logger, {n = 2, Fields = fields})
end

function print(entry)
    std_print(entry.Logger.formatter(entry))
end

local function getTerminalColumns(offset)
    subtract = subtract or 0
    local handle = io.popen("tput cols")
    local result = handle:read("*a")
    
    handle:close()
    return math.min(tonumber(result) - offset, 99)
end

formatters = {}
function formatters.text(entry) 
    local levelColor = Colors[entry.Level]
    local noColor = Colors[Levels.NoLevel]
    local colorCount = 1

    local footer = ""
    if entry.Fields ~= {} then
        std_print("Field evaluating")
        for key, value in next, entry.Fields do
            footer = footer .. ("%s%s%s=%s "):format(
                entry.Logger.colors and levelColor or "",
                key,
                entry.Logger.colors and noColor or "",
                tostring(value)
            )
            colorCount = colorCount + 1
        end
    end

    local header = ("%s[%-6s%s]%s %s:"):format(
        entry.Logger.colors and levelColor or "",
        entry.Level,
        entry.Time,
        entry.Logger.colors and noColor or "",
        entry.LineInf
    )

    local offset = entry.Logger.colors and (#levelColor + #noColor) * colorCount or 0
    offset = offset + #header
    local body = ("%%-%ds"):format(getTerminalColumns(offset)):format(entry.Msg)
    return ("%s %s %s"):format(header, body, footer)
end

local function set(t, k, v)
    getmetatable(t).__index[k] = v
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
        formatter = formatters.text,
        colors  = true,

        new         = newLogger,
        withFields  = withFields,

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
        if key == 'formatter' then
            if type(value) == 'string' then
                value = formatters[value:lower()]
            end

            if type(value) == 'function' then
                set(logger, key. value)
            end
        elseif key == 'colors' then
            if type(value) == 'boolean' then
                set(logger, key, value)
            end
        end
    end,
}

defaultLogger = newLogger()
return defaultLogger
