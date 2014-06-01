module std.logger.stdiologger;

import std.stdio;
import std.string;
import std.logger.templatelogger;

/** This $(D Logger) implementation writes log messages to the systems
standard output. The format of the output is:
$(D FileNameWithoutPath:FunctionNameWithoutModulePath:LineNumber Message).
*/
class StdIOLogger : TemplateLogger!(File.LockingTextWriter, defaultFormatter)
{
    static @trusted this()
    {
        this("", LogLevel.info);
        //StdIOLogger.stdioMutex = new Mutex();
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
        super(stdout.lockingTextWriter(), name, lv);
    }

    /** The messages written to $(D stdio) has the format of:
    $(D FileNameWithoutPath:FunctionNameWithoutModulePath:LineNumber Message).
    public override void writeLogMsg(ref LoggerPayload payload) @trusted
    {
        version(DisableStdIOLogging)
        {
        }
        else
        {
            size_t fnIdx = payload.file.lastIndexOf('/');
            fnIdx = fnIdx == -1 ? 0 : fnIdx+1;
            size_t funIdx = payload.funcName.lastIndexOf('.');
            funIdx = funIdx == -1 ? 0 : funIdx+1;
            synchronized(stdioMutex)
            {
                writefln("%s:%s:%s:%u %s",payload.timestamp.toISOExtString(),
                    payload.file[fnIdx .. $], payload.funcName[funIdx .. $],
                    payload.line, payload.msg);
            }
        }
    }
    */

    //private static __gshared Mutex stdioMutex;
}

unittest
{
    version(std_logger_stdouttest)
    {
        auto s = new StdIOLogger();
        s.log();
    }
}
