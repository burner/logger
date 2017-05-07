///
module std.experimental.logger.nulllogger;

import std.experimental.logger.core;

/** The $(D NullLogger) will not process any log messages.

In case of a log message with $(D LogLevel.fatal) nothing will happen.
*/
class NullLogger : Logger
{
    import std.concurrency : Tid;
	import std.datetime : SysTime;
    /** The default constructor for the $(D NullLogger).

    Independent of the parameter this Logger will never log a message.

    Params:
      lv = The $(D LogLevel) for the $(D NullLogger). By default the $(D LogLevel)
      for $(D NullLogger) is $(D LogLevel.all).
    */
    this(const LogLevel lv = LogLevel.all) @safe
    {
        super(lv);
        this.fatalHandler = delegate() {};
    }

    override void beginLogMsg(string file, int line, string funcName,
        string prettyFuncName, string moduleName, LogLevel logLevel,
        Tid threadId, SysTime timestamp, Logger logger)
        @safe
    {
    }

    /** Logs a part of the log message. */
    override void logMsgPart(const(char)[] msg) @safe
    {
    }

    /** Signals that the message has been written and no more calls to
    $(D logMsgPart) follow. */
    override void finishLogMsg() @safe
    {
    }
}

///
@safe unittest
{
    import std.experimental.logger.nulllogger : LogLevel;

    auto nl1 = new NullLogger(LogLevel.all);
    nl1.info("You will never read this.");
    nl1.fatal("You will never read this, either and it will not throw");
}
