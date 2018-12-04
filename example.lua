local log = require 'log'

log.Trace("a trace message")
log.Debug("a debug message")
log.Info("an info message")
log.Warn("a warning")
log.Error("an error")
log.Fatal("a fatal error")

log:Tracef("this is a %sing test", "laugh")

log.colors = false
log.Trace("colorless")

log.colors = true
log:withFields({test="test", example=123}):Fatal("test")

log:withFields({test="test", example=123}):Debug("test12312312")
