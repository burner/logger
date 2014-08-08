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
    /** A constructor for the $(D FileLogger) Logger.

    Params:
      fn = The filename of the output file of the $(D FileLogger).
      lv = The $(D LogLevel) for the $(D FileLogger). By default the
      $(D LogLevel) for $(D FileLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto l1 = new FileLogger("logFile", "loggerName");
    auto l2 = new FileLogger("logFile", "loggerName", LogLevel.fatal);
    -------------
    */
    @trusted this(const string fn, const LogLevel lv = LogLevel.info)
    {
        import std.exception : enforce;
        super(lv);
        this.filename = fn;
        this.file_.open(this.filename, "a");
        enforce(this.file.isOpen, "Unable to open file: \"" ~ this.filename ~
            "\" for logging.");
        this.filePtr_ = &this.file_;
        this.mutex = new Mutex;
    }

    /** A constructor for the $(D FileLogger) Logger.

    Params:
      file = The file used for logging.
      lv = The $(D LogLevel) for the $(D FileLogger). By default the
      $(D LogLevel) for $(D FileLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto file = File("logFile.log", "w");
    auto l1 = new FileLogger(file, "LoggerName");
    auto l2 = new FileLogger(file, "LoggerName", LogLevel.fatal);
    -------------
    */
    this(ref File file, const LogLevel lv = LogLevel.info)
    {
        super(lv);
        this.filePtr_ = &file;
        this.mutex = new Mutex;
    }

    /** The file written to is accessible by this method.*/
    @property File* filePtr()
    {
        return this.filePtr_;
    }

    @property File file()
    {
        return this.file_;
    }

    override void logHeader(string file, int line, string funcName,
        string prettyFuncName, string moduleName, LogLevel logLevel,
        Tid threadId, SysTime timestamp)
        @trusted
    {
        ptrdiff_t fnIdx = file.lastIndexOf('/') + 1;
        ptrdiff_t funIdx = funcName.lastIndexOf('.') + 1;

        auto mu = this.mutex;
        mu.lock();
        auto lt = this.filePtr_.lockingTextWriter();
        systimeToISOString(lt, timestamp);
        formattedWrite(lt, ":%s:%s:%u ", file[fnIdx .. $],
            funcName[funIdx .. $], line);
    }

    /** Logs a part of the log message. */
    override void logMsgPart(const(char)[] msg)
    {
        formattedWrite(this.filePtr.lockingTextWriter(), "%s", msg);
    }

    /** Signals that the message has been written and no more calls to
    $(D logMsgPart) follow. */
    override void finishLogMsg()
    {
        static if (isLoggingActive())
        {
            auto mu = this.mutex;
            scope(exit) mu.unlock();
            this.filePtr_.lockingTextWriter().put("\n");
            this.filePtr_.flush();
        }
    }

    override void writeLogMsg(ref LogEntry payload)
    {
        this.logHeader(payload.file, payload.line, payload.funcName,
            payload.prettyFuncName, payload.moduleName, payload.logLevel,
            payload.threadId, payload.timestamp);
        this.logMsgPart(payload.msg);
        this.finishLogMsg();
    }

    private Mutex mutex;
    private File file_;
    private File* filePtr_;
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
    l.log(LogLevel.warning, notWritten);
    l.log(LogLevel.critical, written);
    destroy(l);

    auto file = File(filename, "r");
    string readLine = file.readln();
    assert(readLine.indexOf(written) != -1, readLine);
    readLine = file.readln();
    assert(readLine.indexOf(notWritten) == -1, readLine);
}

unittest
{
    import std.file : remove;
    import std.array : empty;
    import std.string : indexOf;

    string filename = randomString(32) ~ ".tempLogFile";
    auto file = File(filename, "w");
    auto l = new FileLogger(file);

    scope(exit)
    {
        remove(filename);
    }

    string notWritten = "this should not be written to file";
    string written = "this should be written to file";

    l.logLevel = LogLevel.critical;
    l.log(LogLevel.warning, notWritten);
    l.log(LogLevel.critical, written);
    file.close();

    file = File(filename, "r");
    string readLine = file.readln();
    assert(readLine.indexOf(written) != -1, readLine);
    readLine = file.readln();
    assert(readLine.indexOf(notWritten) == -1, readLine);
}

unittest
{
    auto dl = defaultLogger;
    assert(dl !is null);
    assert(dl.logLevel == LogLevel.all);
    assert(globalLogLevel == LogLevel.all);
}
