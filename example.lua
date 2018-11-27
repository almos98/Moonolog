local log = require 'log'

function printT(t)
    for i, v in next, t do
        print(i,v)
    end
end

log.Trace("a trace message")
log.Debug("a debug message")
log.Info("an info message")
log.Warn("a warning")
log.Error("an error")
log.Fatal("a fatal error")

log:Tracef("this is a %sing test", "laugh")
