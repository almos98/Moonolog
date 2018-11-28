# Moonolog
My solution to logging in Lua, inspired by [Logrus](https://github.com/sirupsen/logrus).
I do not plan to implement Logrus or all of its features in Lua, but rather a similar API.

#### Level Logging

There are six logging levels: Trace, Debug, Info, Warning, Error and Fatal.
```lua
  log.Trace("a trace message")
  log.Debug("a debug message")
  log.Info("an info message")
  log.Warn("a warning")
  log.Error("an error, will not exit program")
  log.Fatal("a fatal error, will call os.exit(1)")
```

Each message function also has a printf variant: Tracef, Debugf, Infof, Warningf, Errorf, Fatalf.
