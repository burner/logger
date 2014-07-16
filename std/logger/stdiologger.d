module std.logger.stdiologger;

import std.stdio;
import core.sync.mutex;
import std.string;
import std.logger.templatelogger;

private struct StdioOutputRange {
	static __gshared Mutex mu;

	void put(T)(ref T t) {
		mu.lock();
		scope(exit) mu.unlock();
		write(t);
	}

	static StdioOutputRange opCall() {
		StdioOutputRange ret;
		StdioOutputRange.mu =  new Mutex();
		return ret;
	}
}

/** This $(D Logger) implementation writes log messages to the systems
standard output. The format of the output is:
$(D FileNameWithoutPath:FunctionNameWithoutModulePath:LineNumber Message).

The $(D StdIOLogger) is thread safe, in the sense that the output of the
all $(D StdIOLogger) to stdout will not be subject to race conditions. In
other words stdout is locked for writing.
*/
class StdIOLogger : TemplateLogger!(StdioOutputRange, defaultFormatter, 
    (a) => true)
{
    static @trusted this()
    {
        this("", LogLevel.info);
    }

    /** Default constructor for the $(D StdIOLogger) Logger.

    Params:
      lv = The $(D LogLevel) for the $(D StdIOLogger). By default the
      $(D LogLevel) for $(D StdIOLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto l1 = new StdIOLogger;
    auto l2 = new StdIOLogger(LogLevel.fatal);
    -------------
    */
    public @safe this(const LogLevel lv = LogLevel.info)
    {
        this("", lv);
    }

    /** A constructor for the $(D StdIOLogger) Logger.

    Params:
      name = The name of the logger. Compare to $(D MultiLogger.insertLogger).
      lv = The $(D LogLevel) for the $(D StdIOLogger). By default the
      $(D LogLevel) for $(D StdIOLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto l1 = new StdIOLogger("someName");
    auto l2 = new StdIOLogger("someName", LogLevel.fatal);
    -------------
    */
    public this(string name, const LogLevel lv = LogLevel.info) @trusted
    {
        super(StdioOutputRange(), name, lv);
    }
}

unittest
{
    version(std_logger_stdouttest)
    {
        auto s = new StdIOLogger();
        s.log("Hello");
    }
}
