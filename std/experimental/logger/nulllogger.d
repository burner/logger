// Written in the D programming language.
/**
Source: $(PHOBOSSRC std/experimental/logger/_nulllogger.d)
*/
module std.experimental.logger.nulllogger;

import std.experimental.logger.core;

/** The `NullLogger` will not process any log messages.

In case of a log message with `LogLevel.fatal` nothing will happen.
*/
class NullLogger : Logger
{
	import std.concurrency : Tid;
	import std.datetime.systime : SysTime;
    /** The default constructor for the `NullLogger`.

    Independent of the parameter this Logger will never log a message.

    Params:
      lv = The `LogLevel` for the `NullLogger`. By default the `LogLevel`
      for `NullLogger` is `LogLevel.all`.
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
    import std.experimental.logger.core : LogLevel;

    auto nl1 = new NullLogger(LogLevel.all);
    nl1.info("You will never read this.");
    nl1.fatal("You will never read this, and it will not throw");
}
