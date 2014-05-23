module std.logger.nulllogger;

import std.logger.logger;

/** The $(D NullLogger) will not process any log messages.

In case of a log message with $(D LogLevel.fatal) nothing will happen.
*/
class NullLogger : Logger {
    /** The default constructor for the $(D NullLogger).

    Independend of the parameter this Logger will never log a message.
    
    Params:
      lv = The $(D LogLevel) for the $(D MultiLogger). By default the $(D LogLevel)
      for $(D MultiLogger) is $(D LogLevel.info).
    */
    public this(const LogLevel lv = LogLevel.info) @safe
    {
        super("", lv);
        this.setFatalHandler = delegate() {};
    }

    /** A constructor for the $(D NullLogger).

    Independend of the parameter this Logger will never log a message.
    
    Params:
      name = The name of the logger. Compare to $(D FileLogger.insertLogger).
      lv = The $(D LogLevel) for the $(D MultiLogger). By default the $(D LogLevel)
      for $(D MultiLogger) is $(D LogLevel.info).
    */
    public this(string name, const LogLevel lv = LogLevel.info) @safe
    {
        super(name, lv);
        this.setFatalHandler = delegate() {};
    }

    public override void writeLogMsg(ref LoggerPayload payload) @safe {
    }
}

///
unittest {
    auto nl1 = new NullLogger(LogLevel.all);
    auto nl2 = new NullLogger("NULL", LogLevel.all);
    nl1.info("You will never read this.");
    nl2.fatal("You will never read this, either.");
}
