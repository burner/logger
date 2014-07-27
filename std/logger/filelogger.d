module std.logger.filelogger;

import std.stdio;
import std.string;
import std.datetime : SysTime;
import std.concurrency;
public import std.logger.core;

import core.sync.mutex;

/** This $(D Logger) implementation writes log messages to the associated
file. The name of the file has to be passed on construction time. If the file
is already present new log messages will be append at its end.
*/
class FileLogger : Logger
{
    import std.format : formattedWrite;
    /** Default constructor for the $(D StdIOLogger) Logger.

    Params:
      fn = The filename of the output file of the $(D FileLogger).
      lv = The $(D LogLevel) for the $(D FileLogger). By default the
      $(D LogLevel) for $(D FileLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto l1 = new FileLogger;
    auto l2 = new FileLogger("logFile", LogLevel.fatal);
    -------------
    */
    public @trusted this(const string fn, const LogLevel lv = LogLevel.info)
    {
        this(fn, "", lv);
    }

    /** A constructor for the $(D FileLogger) Logger.

    Params:
      fn = The filename of the output file of the $(D FileLogger).
      name = The name of the logger. Compare to $(D FileLogger.insertLogger).
      lv = The $(D LogLevel) for the $(D FileLogger). By default the
      $(D LogLevel) for $(D FileLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto l1 = new FileLogger("logFile", "loggerName");
    auto l2 = new FileLogger("logFile", "loggerName", LogLevel.fatal);
    -------------
    */
    public @trusted this(const string fn, string name,
            const LogLevel lv = LogLevel.info)
    {
        import std.exception : enforce;
        super(name, lv);
        this.filename = fn;
        this.file_.open(this.filename, "a");
        enforce(this.file.isOpen, "Unable to open file: \"" ~ this.filename ~
            "\" for logging.");
        this.filePtr = &this.file_;
        this.mutex = cast(shared Mutex)new Mutex;
    }

    /** A constructor for the $(D FileLogger) Logger.

    Params:
      file = The file used for logging.
      name = The name of the logger. Compare to $(D FileLogger.insertLogger).
      lv = The $(D LogLevel) for the $(D FileLogger). By default the
      $(D LogLevel) for $(D FileLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto l1 = new FileLogger("logFile", "loggerName");
    auto l2 = new FileLogger("logFile", "loggerName", LogLevel.fatal);
    -------------
    */
    public @trusted this(ref File file, string name,
            const LogLevel lv = LogLevel.info)
    {
        super(name, lv);
        this.filePtr = &file;
        this.mutex = cast(shared Mutex)new Mutex;
    }

    /** The file written to is accessible by this method.*/
    public @property ref File file() @trusted
    {
        return this.file_;
    }

    public override void logHeader(string file, int line, string funcName,
        string prettyFuncName, string moduleName, LogLevel logLevel,
        Tid threadId, SysTime timestamp)
        @trusted
    {
        version(DisableLogging)
        {
        }
        else
        {
            ptrdiff_t fnIdx = file.lastIndexOf('/') + 1;
            ptrdiff_t funIdx = funcName.lastIndexOf('.') + 1;

            auto time = timestamp.toISOExtString();
            size_t timeLen = time.length;
            ptrdiff_t timeIdx = time.lastIndexOf('.');

            if (timeIdx - timeLen > 5)
            {
                time = time[0 .. timeIdx+5];
            }

            timeIdx+=5;

            auto mu = cast()(this.mutex);
            mu.lock();
            formattedWrite(this.filePtr.lockingTextWriter(), "%*s:%s:%s:%u ",
                timeIdx, time, file[fnIdx .. $], funcName[funIdx .. $], line);
        }
    }

    /** Logs a part of the log message. */
    public override void logMsgPart(const(char)[] msg)
    {
        version(DisableLogging)
        {
        }
        else
        {
            formattedWrite(this.filePtr.lockingTextWriter(), "%s", msg);
        }
    }

    /** Signals that the message has been written and no more calls to
    $(D logMsgPart) follow. */
    public override void finishLogMsg()
    {
        version(DisableLogging)
        {
        }
        else
        {
            auto mu = cast()this.mutex;
            scope(exit) mu.unlock();
            this.filePtr.lockingTextWriter().put("\n");
            this.filePtr.flush();
        }
    }
    private shared Mutex mutex;
    private File file_;
    private File* filePtr;
    private string filename;
}

unittest
{
    import std.file : remove;
    import std.array : empty;
    import std.string : indexOf;

    string filename = randomString(32) ~ ".tempLogFile";
    auto l = new FileLogger(filename);

    scope(exit)
    {
        remove(filename);
    }

    string notWritten = "this should not be written to file";
    string written = "this should be written to file";

    l.logLevel = LogLevel.critical;
    l.logl(LogLevel.warning, notWritten);
    l.logl(LogLevel.critical, written);
    destroy(l);

    auto file = File(filename, "r");
    string readLine = file.readln();
    assert(readLine.indexOf(written) != -1, readLine);
    readLine = file.readln();
    assert(readLine.indexOf(notWritten) == -1, readLine);
}
