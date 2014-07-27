module std.logger.stdiologger;

import std.stdio;
import core.sync.mutex;
import std.string;
import std.logger.filelogger;

/** This $(D Logger) implementation writes log messages to the systems
standard output. The format of the output is:
$(D FileNameWithoutPath:FunctionNameWithoutModulePath:LineNumber Message).

The $(D StdioLogger) is thread safe, in the sense that the output of the
all $(D StdioLogger) to stdout will not be subject to race conditions. In
other words stdout is locked for writing.
*/
class StdioLogger : FileLogger
{
    @trusted this()
    {
        this("", LogLevel.info);
    }

    /** Default constructor for the $(D StdioLogger) Logger.

    Params:
      lv = The $(D LogLevel) for the $(D StdioLogger). By default the
      $(D LogLevel) for $(D StdioLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto l1 = new StdioLogger;
    auto l2 = new StdioLogger(LogLevel.fatal);
    -------------
    */
    public @safe this(const LogLevel lv = LogLevel.info)
    {
        this("", lv);
    }

    /** A constructor for the $(D StdioLogger) Logger.

    Params:
      name = The name of the logger. Compare to $(D MultiLogger.insertLogger).
      lv = The $(D LogLevel) for the $(D StdioLogger). By default the
      $(D LogLevel) for $(D StdioLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto l1 = new StdioLogger("someName");
    auto l2 = new StdioLogger("someName", LogLevel.fatal);
    -------------
    */
    public this(string name, const LogLevel lv = LogLevel.info) @trusted
    {
        super(stdout, name, lv);
    }
}

unittest
{
    version(std_logger_stdouttest)
    {
        auto s = new StdioLogger();
        s.log("Hello");
    }
}
