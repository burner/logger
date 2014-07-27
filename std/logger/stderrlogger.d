module std.logger.stderrlogger;

import std.stdio;
import core.sync.mutex;
import std.string;
import std.logger.filelogger;

/** This $(D Logger) implementation writes log messages to the systems
standard error. The format of the output is:
$(D FileNameWithoutPath:FunctionNameWithoutModulePath:LineNumber Message).

The $(D StderrLogger) is thread safe, in the sense that the output of the
all $(D StderrLogger) to stdout will not be subject to race conditions. In
other words stdout is locked for writing.
*/
class StderrLogger : FileLogger
{
    @trusted this()
    {
        this("", LogLevel.info);
    }

    /** Default constructor for the $(D StderrLogger) Logger.

    Params:
      lv = The $(D LogLevel) for the $(D StderrLogger). By default the
      $(D LogLevel) for $(D StderrLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto l1 = new StderrLogger;
    auto l2 = new StderrLogger(LogLevel.fatal);
    -------------
    */
    public @safe this(const LogLevel lv = LogLevel.info)
    {
        this("", lv);
    }

    /** A constructor for the $(D StderrLogger) Logger.

    Params:
      name = The name of the logger. Compare to $(D MultiLogger.insertLogger).
      lv = The $(D LogLevel) for the $(D StderrLogger). By default the
      $(D LogLevel) for $(D StderrLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto l1 = new StderrLogger("someName");
    auto l2 = new StderrLogger("someName", LogLevel.fatal);
    -------------
    */
    public this(string name, const LogLevel lv = LogLevel.info) @trusted
    {
        super(stdout, name, lv);
    }
}

unittest
{
    version(std_logger_stderrtest)
    {
        auto s = new StderrLogger();
        s.log("Hello");
    }
}
