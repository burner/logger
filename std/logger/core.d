/**
Implements logging facilities.

Message logging is a common approach to expose runtime information of a
program. Logging should be easy, but also flexible and powerful, therefore
$(D D) provides a standard interface for logging.

The easiest way to create a log message is to write
$(D import std.logger; log("I am here");) this will print a message to the
$(D stdout) device.  The message will contain the filename, the linenumber, the
name of the surrounding function, the time and the message.

Copyright: Copyright Robert "burner" Schadek 2013 --
License: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
Authors: $(WEB http://www.svs.informatik.uni-oldenburg.de/60865.html, Robert burner Schadek)

-------------
log("Logging to the stdlog with its default LogLevel");
logf(LogLevel.info, 5 < 6, "%s to the stdlog with its LogLevel.info", "Logging");
info("Logging to the stdlog with its info LogLevel");
warning(5 < 6, "Logging to the stdlog with its LogLevel.warning if 5 is less than 6");
error("Logging to the stdlog with its error LogLevel");
errorf("Logging %s the stdlog %s its error LogLevel", "to", "with");
critical("Logging to the"," stdlog with its error LogLevel");
fatal("Logging to the stdlog with its fatal LogLevel");

auto fLogger = new FileLogger("NameOfTheLogFile");
fLogger.log("Logging to the fileLogger with its default LogLevel");
fLogger.info("Logging to the fileLogger with its default LogLevel");
fLogger.warning(5 < 6, "Logging to the fileLogger with its LogLevel.warning if 5 is less than 6");
fLogger.warningf(5 < 6, "Logging to the fileLogger with its LogLevel.warning if %s is %s than 6", 5, "less");
fLogger.critical("Logging to the fileLogger with its info LogLevel");
fLogger.log(LogLevel.trace, 5 < 6, "Logging to the fileLogger"," with its default LogLevel if 5 is less than 6");
fLogger.fatal("Logging to the fileLogger with its warning LogLevel");
-------------

Top-level calls to logging-related functions go to the default $(D Logger)
object called $(D stdlog).
$(LI $(D log))
$(LI $(D trace))
$(LI $(D info))
$(LI $(D warning))
$(LI $(D critical))
$(LI $(D fatal))
The default $(D Logger) will by default log to $(D stdout) and has a default
$(D LogLevel) of $(D LogLevel.all). The default Logger can be accessed by
using a property call $(D stdlog). This property a reference to the
current default $(D Logger). This reference can be used to assign a new
default $(D Logger).
-------------
stdlog = new FileLogger("New_Default_Log_File.log");
-------------

Additional $(D Logger) can be created by creating a new instance of the
required $(D Logger). These $(D Logger) have the same methodes as the
$(D stdlog).

The $(D LogLevel) of an log call can be defined in two ways. The first is by
calling $(D logl) and passing the $(D LogLevel) explicit. Notice the
additional $(B l) after log. The $(D LogLevel) is to be passed as first
argument to the function. The second way of setting the $(D LogLevel) of a
log call, is by calling either $(D trace), $(D info), $(D warning),
$(D critical), or $(D fatal). The log call will than have the respective
$(D LogLevel).

Conditional logging can be achived be appending a $(B c) to the function
identifier and passing a $(D bool) as first argument to the function.
If conditional logging is used the condition must be $(D true) in order to
have the log message logged.

In order to combine a explicit $(D LogLevel) passing with conditional logging
call the function or method $(D loglc). The first required argument to the
call then becomes the $(D LogLevel) and the second argument is the $(D bool).

Messages are logged if the $(D LogLevel) of the log message is greater than or
equal to than the $(D LogLevel) of the used $(D Logger) and additionally if the
$(D LogLevel) of the log message is greater equal to the global $(D LogLevel).
The global $(D LogLevel) is accessible by using $(D globalLogLevel).
To assign the $(D LogLevel) of a $(D Logger) use the $(D logLevel) property of
the logger.

If $(D printf)-style logging is needed add a $(B f) to the logging call, such as
$(D myLogger.infof("Hello %s", "world");) or $(fatalf("errno %d", 1337))
The additional $(B f) enables $(D printf)-style logging for call combinations of
explicit $(D LogLevel) and conditional logging functions and methods. The
$(B f) is always to be placed last.

To customize the logger behavior, create a new $(D class) that inherits from
the abstract $(D Logger) $(D class), and implements the $(D writeLogMsg)
method.
-------------
class MyCustomLogger : Logger {
    this(string newName, LogLevel lv) @safe
    {
        super(newName, lv);
    }

    override void writeLogMsg(ref LogEntry payload)
    {
        // log message in my custom way
    }
}

auto logger = new MyCustomLogger();
logger.log("Awesome log message");
-------------

Even though the idea behind this logging module is to provide a common
interface and easy extensibility certain specific Logger are already
implemented.

$(LI StdioLogger = This $(D Logger) logs data to $(D stdout).)
$(LI FileLogger = This $(D Logger) logs data to files.)
$(LI MulitLogger = This $(D Logger) logs data to multiple $(D Logger).)
$(LI NullLogger = This $(D Logger) will never do anything.)
$(LI TemplateLogger = This $(D Logger) can be used to create simple custom
$(D Logger).)

In order to disable logging at compile time, pass $(D DisableLogging) as a
version argument to the $(D D) compiler.
*/
module std.logger.core;

import std.array;
import std.stdio;
import std.conv;
import std.datetime;
import std.string;
import std.range;
import std.traits;
import std.exception;
import std.concurrency;
import std.format;

import std.logger.multilogger;
import std.logger.filelogger;
import std.logger.nulllogger;

pure bool isLoggingActive(LogLevel ll)() @safe nothrow
{
    static assert(__ctfe);
    version (DisableLogging)
    {
        return false;
    }
    else
    {
        static if (ll == LogLevel.trace)
        {
            version (DisableTrace) return false;
        }
        else static if (ll == LogLevel.info)
        {
            version (DisableInfo) return false;
        }
        else static if (ll == LogLevel.warning)
        {
            version (DisableWarning) return false;
        }
        else static if (ll == LogLevel.error)
        {
            version (DisableError) return false;
        }
        else static if (ll == LogLevel.critical)
        {
            version (DisableCritical) return false;
        }
        else static if (ll == LogLevel.fatal)
        {
            version (DisableFatal) return false;
        }
        return true;
    }
}

pure bool isLoggingActive()() @safe nothrow
{
    return isLoggingActive!(LogLevel.all)();
}

pure bool isLoggingEnabled()(LogLevel ll) @safe nothrow
{
    switch (ll)
    {
        case LogLevel.trace:
            version (DisableTrace) return false;
            else break;
        case LogLevel.info:
            version (DisableInfo) return false;
            else break;
        case LogLevel.warning:
            version (DisableWarning) return false;
            else break;
        case LogLevel.critical:
            version (DisableCritical) return false;
            else break;
        case LogLevel.fatal:
            version (DisableFatal) return false;
            else break;
        default: break;
    }

    return true;
}

/* This function formates a $(D SysTime) into an $(D OutputRange).

The $(D SysTime) is formatted simular to
$(LREF std.datatime.DateTime.toISOExtString) expect the fractional second part.
The sub second part is the upper three digest of the microsecond.
*/
void systimeToISOString(OutputRange)(OutputRange o, const ref SysTime time)
    if(isOutputRange!(OutputRange,string))
{
    auto fsec = time.fracSec.usecs / 1000;

    formattedWrite(o, "%04d-%02d-%02dT%02d:%02d:%02d.%03d",
        time.year, time.month, time.day, time.hour, time.minute, time.second,
        fsec);
}

/** This function logs data.

In order for the data to be processed the $(D LogLevel) of the log call must
be greater or equal to the $(D LogLevel) of the $(D stdlog) and the
$(D defaultLogLevel) additionally the condition passed must be $(D true).

Params:
ll = The $(D LogLevel) used by this log call.
condition = The condition must be $(D true) for the data to be logged.
args = The data that should be logged.

Examples:
--------------------
log(LogLevel.warning, true, "Hello World", 3.1415);
--------------------
*/
void log(int line = __LINE__, string file = __FILE__,
    string funcName = __FUNCTION__,
    string prettyFuncName = __PRETTY_FUNCTION__,
    string moduleName = __MODULE__, A...)(const LogLevel ll,
    lazy bool condition, lazy A args)
{
    static if (isLoggingActive())
    {
        if (isLoggingEnabled(ll)
                && ll >= globalLogLevel
                && ll >= stdlog.logLevel
                && globalLogLevel != LogLevel.off
                && stdlog.logLevel != LogLevel.off
                && condition)
        {
            stdlog.log!(line, file, funcName,prettyFuncName, moduleName)
                (ll, args);
        }
    }
}

/** This function logs data.

In order for the data to be processed the $(D LogLevel) of the log call must
be greater or equal to the $(D LogLevel) of the $(D stdlog).

Params:
ll = The $(D LogLevel) used by this log call.
args = The data that should be logged.

Examples:
--------------------
log(LogLevel.warning, "Hello World", 3.1415);
--------------------
*/
void log(int line = __LINE__, string file = __FILE__,
    string funcName = __FUNCTION__,
    string prettyFuncName = __PRETTY_FUNCTION__,
    string moduleName = __MODULE__, A...)(const LogLevel ll,
        lazy A args) @trusted
    if (args.length == 0 || (args.length > 0 && !is(Unqual!(A[0]) : bool)))
{
    static if (isLoggingActive())
    {
        if (isLoggingEnabled(ll)
                && ll >= globalLogLevel
                && ll >= stdlog.logLevel
                && globalLogLevel != LogLevel.off
                && stdlog.logLevel != LogLevel.off )
        {
            stdlog.log!(line, file, funcName,prettyFuncName, moduleName)
                (ll, args);
        }
    }
}

/** This function logs data.

In order for the data to be processed the $(D LogLevel) of the
$(D stdlog) must be greater or equal to the $(D defaultLogLevel)
add the condition passed must be $(D true).

Params:
condition = The condition must be $(D true) for the data to be logged.
args = The data that should be logged.

Examples:
--------------------
log(true, "Hello World", 3.1415);
--------------------
*/
void log(int line = __LINE__, string file = __FILE__,
    string funcName = __FUNCTION__,
    string prettyFuncName = __PRETTY_FUNCTION__,
    string moduleName = __MODULE__, A...)(lazy bool condition, lazy A args)
    @trusted
{
    static if (isLoggingActive())
    {
        if (isLoggingEnabled(stdlog.logLevel)
                && stdlog.logLevel >= globalLogLevel
                && globalLogLevel != LogLevel.off
                && stdlog.logLevel != LogLevel.off
                && condition)
        {
            stdlog.log!(line, file, funcName,prettyFuncName, moduleName)
                (args);
        }
    }
}

/** This function logs data.

In order for the data to be processed the $(D LogLevel) of the
$(D stdlog) must be greater or equal to the $(D defaultLogLevel).

Params:
args = The data that should be logged.

Examples:
--------------------
log("Hello World", 3.1415);
--------------------
*/
void log(int line = __LINE__, string file = __FILE__,
    string funcName = __FUNCTION__,
    string prettyFuncName = __PRETTY_FUNCTION__,
    string moduleName = __MODULE__, A...)(lazy A args)
    @trusted
    if (args.length == 0 ||
        (args.length > 0 && !is(Unqual!(A[0]) : bool)
         && !is(Unqual!(A[0]) == LogLevel)))
{
    static if (isLoggingActive())
    {
        if (isLoggingEnabled(stdlog.logLevel)
                && stdlog.logLevel >= globalLogLevel
                && globalLogLevel != LogLevel.off
                && stdlog.logLevel != LogLevel.off)
        {
            stdlog.log!(line, file, funcName,prettyFuncName,
                moduleName)(args);
        }
    }
}

/** This function logs data in a $(D printf)-style manner.

In order for the data to be processed the $(D LogLevel) of the log call must
be greater or equal to the $(D LogLevel) of the $(D stdlog) and the
$(D defaultLogLevel) additionally the condition passed must be $(D true).

Params:
ll = The $(D LogLevel) used by this log call.
condition = The condition must be $(D true) for the data to be logged.
msg = The $(D printf)-style string.
args = The data that should be logged.

Examples:
--------------------
logf(LogLevel.warning, true, "Hello World %f", 3.1415);
--------------------
*/
void logf(int line = __LINE__, string file = __FILE__,
    string funcName = __FUNCTION__,
    string prettyFuncName = __PRETTY_FUNCTION__,
    string moduleName = __MODULE__, A...)(const LogLevel ll,
    lazy bool condition, lazy string msg, lazy A args)
{
    static if (isLoggingActive())
    {
        if (isLoggingEnabled(ll)
                && ll >= globalLogLevel
                && ll >= stdlog.logLevel
                && globalLogLevel != LogLevel.off
                && stdlog.logLevel != LogLevel.off
                && condition)
        {
            stdlog.logf!(line, file, funcName,prettyFuncName, moduleName)
                (ll, msg, args);
        }
    }
}

/** This function logs data in a $(D printf)-style manner.

In order for the data to be processed the $(D LogLevel) of the log call must
be greater or equal to the $(D LogLevel) of the $(D stdlog) and the
$(D defaultLogLevel).

Params:
ll = The $(D LogLevel) used by this log call.
msg = The $(D printf)-style string.
args = The data that should be logged.

Examples:
--------------------
logf(LogLevel.warning, true, "Hello World %f", 3.1415);
--------------------
*/
void logf(int line = __LINE__, string file = __FILE__,
    string funcName = __FUNCTION__,
    string prettyFuncName = __PRETTY_FUNCTION__,
    string moduleName = __MODULE__, A...)(const LogLevel ll, lazy string msg,
        lazy A args) @trusted
    if (args.length == 0 || (args.length > 0 && !is(Unqual!(A[0]) : bool)))
{
    static if (isLoggingActive())
    {
        if (isLoggingEnabled(ll)
                && ll >= globalLogLevel
                && ll >= stdlog.logLevel
                && globalLogLevel != LogLevel.off
                && stdlog.logLevel != LogLevel.off )
        {
            stdlog.logf!(line, file, funcName,prettyFuncName, moduleName)
                (ll, msg, args);
        }
    }
}

/** This function logs data in a $(D printf)-style manner.

In order for the data to be processed the $(D LogLevel) of the log call must
be greater or equal to the $(D defaultLogLevel) additionally the condition
passed must be $(D true).

Params:
condition = The condition must be $(D true) for the data to be logged.
msg = The $(D printf)-style string.
args = The data that should be logged.

Examples:
--------------------
logf(true, "Hello World %f", 3.1415);
--------------------
*/
void logf(int line = __LINE__, string file = __FILE__,
    string funcName = __FUNCTION__,
    string prettyFuncName = __PRETTY_FUNCTION__,
    string moduleName = __MODULE__, A...)(lazy bool condition,
        lazy string msg, lazy A args)
    @trusted
{
    static if (isLoggingActive())
    {
        if (isLoggingEnabled(stdlog.logLevel)
                && stdlog.logLevel >= globalLogLevel
                && globalLogLevel != LogLevel.off
                && stdlog.logLevel != LogLevel.off
                && condition)
        {
            stdlog.logf!(line, file, funcName,prettyFuncName, moduleName)
                (msg, args);
        }
    }
}

/** This function logs data in a $(D printf)-style manner.

In order for the data to be processed the $(D LogLevel) of the log call must
be greater or equal to the $(D defaultLogLevel).

Params:
msg = The $(D printf)-style string.
args = The data that should be logged.

Examples:
--------------------
logf("Hello World %f", 3.1415);
--------------------
*/
void logf(int line = __LINE__, string file = __FILE__,
    string funcName = __FUNCTION__,
    string prettyFuncName = __PRETTY_FUNCTION__,
    string moduleName = __MODULE__, A...)(lazy string msg, lazy A args)
    @trusted
{
    static if (isLoggingActive())
    {
        if (isLoggingEnabled(stdlog.logLevel)
                && stdlog.logLevel >= globalLogLevel
                && globalLogLevel != LogLevel.off
                && stdlog.logLevel != LogLevel.off)
        {
            stdlog.logf!(line, file, funcName,prettyFuncName,
                moduleName)(msg, args);
        }
    }
}

///
template defaultLogFunction(LogLevel ll)
{
    /** This function logs data to the $(D stdlog).

    In order for the resulting log message to be logged the $(D LogLevel) must
    be greater or equal than the $(D LogLevel) of the $(D stdlog) and
    must be greater or equal than the global $(D LogLevel).

    Params:
    args = The data that should be logged.

    Examples:
    --------------------
    trace(1337, "is number");
    info(1337, "is number");
    error(1337, "is number");
    critical(1337, "is number");
    fatal(1337, "is number");
    --------------------
    */
    void defaultLogFunction(int line = __LINE__,
        string file = __FILE__, string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(lazy A args) @trusted
        if (args.length > 0 && !is(Unqual!(A[0]) : bool))
    {
        static if (isLoggingActive!ll)
        {
            if (isLoggingEnabled(ll)
                    && ll >= stdlog.logLevel
                    && stdlog.logLevel >= globalLogLevel
                    && globalLogLevel != LogLevel.off
                    && stdlog.logLevel != LogLevel.off)
            {
                stdlog.memLogFunctions!(ll).logImpl!(line, file,
                       funcName, prettyFuncName, moduleName)(args);
            }
        }
    }

    /** This function logs data to the $(D stdlog) depending on a condition.

    In order for the resulting log message to be logged the $(D LogLevel) must
    be greater or equal than the $(D LogLevel) of the $(D stdlog) and
    must be greater or equal than the global $(D LogLevel) additionally the
    condition passed must be $(D true).

    Params:
    condition = The condition must be $(D true) for the data to be logged.
    args = The data that should be logged.

    Examples:
    --------------------
    trace(true, 1337, "is number");
    info(false, 1337, "is number");
    error(true, 1337, "is number");
    critical(false, 1337, "is number");
    fatal(true, 1337, "is number");
    --------------------
    */
    void defaultLogFunction(int line = __LINE__,
        string file = __FILE__, string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(lazy bool condition, lazy A args)
        @trusted
    {
        static if (isLoggingActive!ll)
        {
            if (isLoggingEnabled(ll)
                    && ll >= stdlog.logLevel
                    && stdlog.logLevel >= globalLogLevel
                    && globalLogLevel != LogLevel.off
                    && stdlog.logLevel != LogLevel.off
                    && condition)
            {
                stdlog.memLogFunctions!(ll).logImpl!(line, file,
                       funcName, prettyFuncName, moduleName)(args);
            }
        }
    }
}

// Ditto
alias trace = defaultLogFunction!(LogLevel.trace);
// Ditto
alias info = defaultLogFunction!(LogLevel.info);
// Ditto
alias warning = defaultLogFunction!(LogLevel.warning);
// Ditto
alias error = defaultLogFunction!(LogLevel.error);
// Ditto
alias critical = defaultLogFunction!(LogLevel.critical);
// Ditto
alias fatal = defaultLogFunction!(LogLevel.fatal);

///
template defaultLogFunctionf(LogLevel ll)
{
    /** This function logs data to the $(D stdlog) in a $(D printf)-style
    manner.

    In order for the resulting log message to be logged the $(D LogLevel) must
    be greater or equal than the $(D LogLevel) of the $(D stdlog) and
    must be greater or equal than the global $(D LogLevel).

    Params:
    msg = The $(D printf)-style string.
    args = The data that should be logged.

    Examples:
    --------------------
    trace("is number %d", 1);
    info("is number %d", 2);
    error("is number %d", 3);
    critical("is number %d", 4);
    fatal("is number %d", 5);
    --------------------
    */
    void defaultLogFunctionf(int line = __LINE__,
        string file = __FILE__, string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(lazy string msg, lazy A args)
        @trusted
    {
        static if (isLoggingActive!ll)
        {
            if (isLoggingEnabled(ll)
                    && ll >= stdlog.logLevel
                    && stdlog.logLevel >= globalLogLevel
                    && globalLogLevel != LogLevel.off
                    && stdlog.logLevel != LogLevel.off)
            {
                stdlog.memLogFunctions!(ll).logImplf!(line, file,
                       funcName, prettyFuncName, moduleName)(msg, args);
            }
        }
    }

    /** This function logs data to the $(D stdlog) in a $(D printf)-style
    manner.

    In order for the resulting log message to be logged the $(D LogLevel) must
    be greater or equal than the $(D LogLevel) of the $(D stdlog) and
    must be greater or equal than the global $(D LogLevel).

    Params:
     condition = The condition must be $(D true) for the data to be logged.
    msg = The $(D printf)-style string.
    args = The data that should be logged.

    Examples:
    --------------------
    trace("is number %d", 1);
    info("is number %d", 2);
    error("is number %d", 3);
    critical("is number %d", 4);
    fatal("is number %d", 5);
    --------------------
    */
    void defaultLogFunctionf(int line = __LINE__,
        string file = __FILE__, string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(lazy bool condition,
            lazy string msg, lazy A args) @trusted
    {
        static if (isLoggingActive!ll)
        {
            if (isLoggingEnabled(ll)
                    && ll >= stdlog.logLevel
                    && stdlog.logLevel >= globalLogLevel
                    && globalLogLevel != LogLevel.off
                    && stdlog.logLevel != LogLevel.off
                    && condition)
            {
                stdlog.memLogFunctions!(ll).logImplf!(line, file,
                       funcName, prettyFuncName, moduleName)(msg, args);
            }
        }
    }
}

/// Ditto
alias tracef = defaultLogFunctionf!(LogLevel.trace);
/// Ditto
alias infof = defaultLogFunctionf!(LogLevel.info);
/// Ditto
alias warningf = defaultLogFunctionf!(LogLevel.warning);
/// Ditto
alias errorf = defaultLogFunctionf!(LogLevel.error);
/// Ditto
alias criticalf = defaultLogFunctionf!(LogLevel.critical);
/// Ditto
alias fatalf = defaultLogFunctionf!(LogLevel.fatal);

private struct MsgRange
{
    private Logger log;

    this(Logger log)
    {
        this.log = log;
    }

    void put(const(char)[] msg)
    {
        log.logMsgPart(msg);
    }
}

private void formatString(A...)(MsgRange oRange, A args)
{
    import std.format : formattedWrite;

    foreach (arg; args)
    {
        std.format.formattedWrite!(MsgRange,char)(oRange, "%s", arg);
    }
}

/**
There are eight usable logging level. These level are $(I all), $(I trace),
$(I info), $(I warning), $(I error), $(I critical), $(I fatal), and $(I off).
If a log function with $(D LogLevel.fatal) is called the shutdown handler of
that logger is called.
*/
enum LogLevel : ubyte
{
    all = 1, /** Lowest possible assignable $(D LogLevel). */
    trace = 32, /** $(D LogLevel) for tracing the execution of the program. */
    info = 64, /** This level is used to display information about the
                program. */
    warning = 96, /** warnings about the program should be displayed with this
                   level. */
    error = 128, /** Information about errors should be logged with this
                   level.*/
    critical = 160, /** Messages that inform about critical errors should be
                    logged with this level. */
    fatal = 192,   /** Log messages that describe fatal errors should use this
                  level. */
    off = ubyte.max /** Highest possible $(D LogLevel). */
}

/** This class is the base of every logger. In order to create a new kind of
logger a deriving class needs to implement the $(D writeLogMsg) method.
*/
abstract class Logger
{
    /** LogEntry is a aggregation combining all information associated
    with a log message. This aggregation will be passed to the method
    writeLogMsg.
    */
    protected struct LogEntry
    {
        /// the filename the log function was called from
        string file;
        /// the line number the log function was called from
        int line;
        /// the name of the function the log function was called from
        string funcName;
        /// the pretty formatted name of the function the log function was
        /// called from
        string prettyFuncName;
        /// the name of the module the log message is coming from
        string moduleName;
        /// the $(D LogLevel) associated with the log message
        LogLevel logLevel;
        /// thread id of the log message
        Tid threadId;
        /// the time the message was logged.
        SysTime timestamp;
        /// the message of the log message
        string msg;
    }

    /** This constructor takes a name of type $(D string), and a $(D LogLevel).

    Every subclass of $(D Logger) has to call this constructor from there
    constructor. It sets the $(D LogLevel), the name of the $(D Logger), and
    creates a fatal handler. The fatal handler will throw an $(D Error) if a
    log call is made with a $(D LogLevel) $(D LogLevel.fatal).
    */
    this(LogLevel lv) @safe
    {
        this.logLevel = lv;
        this.fatalHandler = delegate() {
            throw new Error("A fatal log message was logged");
        };

        this.msgAppender = appender!string();
    }

    /** A custom logger needs to implement this method.
    Params:
        payload = All information associated with call to log function.
    */
    void writeLogMsg(ref LogEntry payload);

    /* The default implementation will use an $(D std.array.appender)
    internally to construct the message string. This means dynamic,
    GC memory allocation. A logger can avoid this allocation by
    reimplementing $(D logHeader), $(D logMsgPart) and $(D finishLogMsg).
    $(D logHeader) is always called first, followed by any number of calls
    to $(D logMsgPart) and one call to $(D finishLogMsg).
    */
    protected void logHeader(string file, int line, string funcName,
        string prettyFuncName, string moduleName, LogLevel logLevel,
        Tid threadId, SysTime timestamp)
        @trusted
    {
        static if (isLoggingActive())
        {
            header = LogEntry(file, line, funcName, prettyFuncName,
                moduleName, logLevel, threadId, timestamp, null);
        }
    }

    /** Logs a part of the log message. */
    protected void logMsgPart(const(char)[] msg)
    {
        static if (isLoggingActive())
        {
            msgAppender.put(msg);
        }
    }

    /** Signals that the message has been written and no more calls to
    $(D logMsgPart) follow. */
    protected void finishLogMsg()
    {
        static if (isLoggingActive())
        {
            header.msg = msgAppender.data;
            this.writeLogMsg(header);
            msgAppender = appender!string();
        }
    }

    /** The $(D LogLevel) determines if the log call are processed or dropped
    by the $(D Logger). In order for the log call to be processed the
    $(D LogLevel) of the log call must be greater or equal to the $(D LogLevel)
    of the $(D logger).
    */
    @property final LogLevel logLevel() const pure nothrow @safe
    {
        return this.logLevel_;
    }

    /// Ditto
    @property final void logLevel(const LogLevel lv) pure nothrow @safe
    {
        this.logLevel_ = lv;
    }

    /** This methods sets the $(D delegate) called in case of a log message
    with $(D LogLevel.fatal) gets logged.

    By default an $(D Error) will be thrown.
    */
    final void setFatalHandler(void delegate() dg) @safe {
        this.fatalHandler = dg;
    }

    ///
    template memLogFunctions(LogLevel ll)
    {
        /** This function logs data to the used $(D Logger).

        In order for the resulting log message to be logged the $(D LogLevel)
        must be greater or equal than the $(D LogLevel) of the used $(D Logger)
        and must be greater or equal than the global $(D LogLevel).

        Params:
        args = The data that should be logged.

        Examples:
        --------------------
        auto s = new FileLogger(stdout);
        s.trace(1337, "is number");
        s.info(1337, "is number");
        s.error(1337, "is number");
        s.critical(1337, "is number");
        s.fatal(1337, "is number");
        --------------------
        */
        void logImpl(int line = __LINE__,
            string file = __FILE__, string funcName = __FUNCTION__,
            string prettyFuncName = __PRETTY_FUNCTION__,
            string moduleName = __MODULE__, A...)(lazy A args) @trusted
            if (args.length == 0 || (args.length > 0 && !is(A[0] : bool)))
        {
            static if(isLoggingActive!ll)
            {
                if (isLoggingEnabled(ll)
                        && ll >= this.logLevel_
                        && ll >= globalLogLevel
                        && globalLogLevel != LogLevel.off
                        && this.logLevel_ != LogLevel.off)
                {
                    this.logHeader(file, line, funcName, prettyFuncName,
                        moduleName, ll, thisTid, Clock.currTime);

                    auto writer = MsgRange(this);
                    formatString(writer, args);

                    this.finishLogMsg();

                    static if (ll == LogLevel.fatal)
                        fatalHandler();
                }
            }
        }

        /** This function logs data to the used $(D Logger) depending on a
        condition.

        In order for the resulting log message to be logged the $(D LogLevel) must
        be greater or equal than the $(D LogLevel) of the used $(D Logger) and
        must be greater or equal than the global $(D LogLevel) additionally the
        condition passed must be $(D true).

        Params:
        condition = The condition must be $(D true) for the data to be logged.
        args = The data that should be logged.

        Examples:
        --------------------
        auto s = new FileLogger(stdout);
        s.trace(true, 1337, "is number");
        s.info(false, 1337, "is number");
        s.error(true, 1337, "is number");
        s.critical(false, 1337, "is number");
        s.fatal(true, 1337, "is number");
        --------------------
        */
        void logImpl(int line = __LINE__,
            string file = __FILE__, string funcName = __FUNCTION__,
            string prettyFuncName = __PRETTY_FUNCTION__,
            string moduleName = __MODULE__, A...)(lazy bool condition,
                lazy A args) @trusted
        {
            static if(isLoggingActive!ll)
            {
                if (isLoggingEnabled(ll)
                        && ll >= this.logLevel_
                        && ll >= globalLogLevel
                        && globalLogLevel != LogLevel.off
                        && this.logLevel_ != LogLevel.off
                        && condition)
                {
                    this.logHeader(file, line, funcName, prettyFuncName,
                        moduleName, ll, thisTid, Clock.currTime);

                    auto writer = MsgRange(this);
                    formatString(writer, args);

                    this.finishLogMsg();

                    static if (ll == LogLevel.fatal)
                        fatalHandler();
                }
            }
        }

        /** This function logs data to the used $(D Logger) in a
        $(D printf)-style manner.

        In order for the resulting log message to be logged the $(D LogLevel)
        must be greater or equal than the $(D LogLevel) of the used $(D Logger)
           and must be greater or equal than the global $(D LogLevel)
        additionally the passed condition must be $(D true).

        Params:
         condition = The condition must be $(D true) for the data to be logged.
        msg = The $(D printf)-style string.
        args = The data that should be logged.

        Examples:
        --------------------
        auto s = new FileLogger(stderr);
        s.trace("is number %d", 1);
        s.info("is number %d", 2);
        s.error("is number %d", 3);
        s.critical("is number %d", 4);
        s.fatal("is number %d", 5);
        --------------------
        */
        void logImplf(int line = __LINE__,
            string file = __FILE__, string funcName = __FUNCTION__,
            string prettyFuncName = __PRETTY_FUNCTION__,
            string moduleName = __MODULE__, A...)(lazy bool condition,
                lazy string msg, lazy A args) @trusted
        {
            static if (isLoggingActive!ll)
            {
                if (isLoggingEnabled(ll)
                        && ll >= this.logLevel_
                        && ll >= globalLogLevel
                        && globalLogLevel != LogLevel.off
                        && this.logLevel_ != LogLevel.off
                        && condition)
                {
                    this.logHeader(file, line, funcName, prettyFuncName,
                        moduleName, ll, thisTid, Clock.currTime);

                    auto writer = MsgRange(this);
                    formattedWrite(writer, msg, args);

                    this.finishLogMsg();

                    static if (ll == LogLevel.fatal)
                        fatalHandler();
                }
            }
        }

        /** This function logs data to the used $(D Logger) in a
        $(D printf)-style manner.

        In order for the resulting log message to be logged the $(D LogLevel) must
        be greater or equal than the $(D LogLevel) of the used $(D Logger) and
        must be greater or equal than the global $(D LogLevel).

        Params:
        msg = The $(D printf)-style string.
        args = The data that should be logged.

        Examples:
        --------------------
        auto s = new FileLogger(stderr);
        s.trace("is number %d", 1);
        s.info("is number %d", 2);
        s.error("is number %d", 3);
        s.critical("is number %d", 4);
        s.fatal("is number %d", 5);
        --------------------
        */
        void logImplf(int line = __LINE__,
            string file = __FILE__, string funcName = __FUNCTION__,
            string prettyFuncName = __PRETTY_FUNCTION__,
            string moduleName = __MODULE__, A...)(lazy string msg, lazy A args)
            @trusted
        {
            static if (isLoggingActive!ll)
            {
                if (isLoggingEnabled(ll)
                        && ll >= this.logLevel_
                        && ll >= globalLogLevel
                        && globalLogLevel != LogLevel.off
                        && this.logLevel_ != LogLevel.off)
                {
                    this.logHeader(file, line, funcName, prettyFuncName,
                        moduleName, ll, thisTid, Clock.currTime);

                    auto writer = MsgRange(this);
                    formattedWrite(writer, msg, args);

                    this.finishLogMsg();

                    static if (ll == LogLevel.fatal)
                        fatalHandler();
                }
            }
        }
    }

    /// Ditto
    alias trace = memLogFunctions!(LogLevel.trace).logImpl;
    /// Ditto
    alias tracef = memLogFunctions!(LogLevel.trace).logImplf;
    /// Ditto
    alias info = memLogFunctions!(LogLevel.info).logImpl;
    /// Ditto
    alias infof = memLogFunctions!(LogLevel.info).logImplf;
    /// Ditto
    alias warning = memLogFunctions!(LogLevel.warning).logImpl;
    /// Ditto
    alias warningf = memLogFunctions!(LogLevel.warning).logImplf;
    /// Ditto
    alias error = memLogFunctions!(LogLevel.error).logImpl;
    /// Ditto
    alias errorf = memLogFunctions!(LogLevel.error).logImplf;
    /// Ditto
    alias critical = memLogFunctions!(LogLevel.critical).logImpl;
    /// Ditto
    alias criticalf = memLogFunctions!(LogLevel.critical).logImplf;
    /// Ditto
    alias fatal = memLogFunctions!(LogLevel.fatal).logImpl;
    /// Ditto
    alias fatalf = memLogFunctions!(LogLevel.fatal).logImplf;

    /** This method logs data with the $(D LogLevel) of the used $(D Logger).

    This method takes a $(D bool) as first argument. In order for the
    data to be processed the $(D bool) must be $(D true) and the $(D LogLevel)
    of the Logger must be greater or equal to the global $(D LogLevel).

    Params:
    args = The data that should be logged.
    condition = The condition must be $(D true) for the data to be logged.
    args = The data that is to be logged.

    Returns: The logger used by the logging function as reference.

    Examples:
    --------------------
    auto l = new StdioLogger();
    l.log(1337);
    --------------------
    */
    void log(int line = __LINE__, string file = __FILE__,
        string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(const LogLevel ll,
        lazy bool condition, lazy A args) @trusted
    {
        static if (isLoggingActive())
        {
            if (isLoggingEnabled(ll)
                    && ll >= this.logLevel_
                    && ll >= globalLogLevel
                    && globalLogLevel != LogLevel.off
                    && this.logLevel_ != LogLevel.off
                    && condition)
            {
                this.logHeader(file, line, funcName, prettyFuncName,
                    moduleName, ll, thisTid, Clock.currTime);

                auto writer = MsgRange(this);
                formatString(writer, args);

                this.finishLogMsg();
            }
        }
    }

    void log(int line = __LINE__, string file = __FILE__,
        string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(const LogLevel ll,
            lazy A args) @trusted
        if (args.length == 0 || (args.length > 0 && !is(Unqual!(A[0]) : bool)))
    {
        static if (isLoggingActive())
        {
            if (isLoggingEnabled(ll)
                    && ll >= this.logLevel_
                    && ll >= globalLogLevel
                    && globalLogLevel != LogLevel.off
                    && this.logLevel_ != LogLevel.off )
            {
                this.logHeader(file, line, funcName, prettyFuncName,
                    moduleName, ll, thisTid, Clock.currTime);

                auto writer = MsgRange(this);
                formatString(writer, args);

                this.finishLogMsg();
            }
        }
    }

    void log(int line = __LINE__, string file = __FILE__,
        string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(lazy bool condition, lazy A args)
        @trusted
    {
        static if (isLoggingActive())
        {
            if (isLoggingEnabled(this.logLevel_)
                    && this.logLevel_ >= globalLogLevel
                    && globalLogLevel != LogLevel.off
                    && this.logLevel_ != LogLevel.off
                    && condition)
            {
                this.logHeader(file, line, funcName, prettyFuncName,
                    moduleName, this.logLevel_, thisTid, Clock.currTime);

                auto writer = MsgRange(this);
                formatString(writer, args);

                this.finishLogMsg();
            }
        }
    }

    void log(int line = __LINE__, string file = __FILE__,
        string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(lazy A args)
        @trusted
        if (args.length == 0 ||
                (args.length > 0 && !is(Unqual!(A[0]) : bool)
                 && !is(Unqual!(A[0]) == LogLevel)))
    {
        static if (isLoggingActive())
        {
            if (isLoggingEnabled(this.logLevel_)
                    && this.logLevel_ >= globalLogLevel
                    && globalLogLevel != LogLevel.off
                    && this.logLevel_ != LogLevel.off)
            {
                this.logHeader(file, line, funcName, prettyFuncName,
                    moduleName, this.logLevel_, thisTid, Clock.currTime);

                auto writer = MsgRange(this);
                formatString(writer, args);

                this.finishLogMsg();
            }
        }
    }

    void logf(int line = __LINE__, string file = __FILE__,
        string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(const LogLevel ll,
        lazy bool condition, lazy string msg, lazy A args) @trusted
    {
        static if (isLoggingActive())
        {
            if (isLoggingEnabled(ll)
                    && ll >= this.logLevel_
                    && ll >= globalLogLevel
                    && globalLogLevel != LogLevel.off
                    && this.logLevel_ != LogLevel.off
                    && condition)
            {
                this.logHeader(file, line, funcName, prettyFuncName,
                    moduleName, ll, thisTid, Clock.currTime);

                auto writer = MsgRange(this);
                formattedWrite(writer, msg, args);

                this.finishLogMsg();
            }
        }
    }

    void logf(int line = __LINE__, string file = __FILE__,
        string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(const LogLevel ll,
            lazy string msg, lazy A args) @trusted
        if (args.length == 0 || (args.length > 0 && !is(Unqual!(A[0]) : bool)))
    {
        static if (isLoggingActive())
        {
            if (isLoggingEnabled(ll)
                    && ll >= this.logLevel_
                    && ll >= globalLogLevel
                    && globalLogLevel != LogLevel.off
                    && this.logLevel_ != LogLevel.off )
            {
                this.logHeader(file, line, funcName, prettyFuncName,
                    moduleName, ll, thisTid, Clock.currTime);

                auto writer = MsgRange(this);
                formattedWrite(writer, msg, args);

                this.finishLogMsg();
            }
        }
    }

    void logf(int line = __LINE__, string file = __FILE__,
        string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(lazy bool condition,
            lazy string msg, lazy A args) @trusted
    {
        static if (isLoggingActive())
        {
            if (isLoggingEnabled(this.logLevel_)
                    && this.logLevel_ >= globalLogLevel
                    && globalLogLevel != LogLevel.off
                    && this.logLevel_ != LogLevel.off
                    && condition)
            {
                this.logHeader(file, line, funcName, prettyFuncName,
                    moduleName, this.logLevel_, thisTid, Clock.currTime);

                auto writer = MsgRange(this);
                formattedWrite(writer, msg, args);

                this.finishLogMsg();
            }
        }
    }

    /** This method logs data in a $(D printf)-style manner.

    In order for the data to be processed the $(D LogLevel) of the Logger
    must be greater or equal to the global $(D LogLevel).

    Params:
    msg = The format string used for this log call.
    args = The data that should be logged.

    Returns: The logger used by the logging function as reference.

    Examples:
    --------------------
    auto l = new FileLogger(stdout);
    l.logf("Hello World %f", 3.1415);
    --------------------
    */
    void logf(int line = __LINE__, string file = __FILE__,
        string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(lazy string msg, lazy A args)
        @trusted
    {
        static if (isLoggingActive())
        {
            if (isLoggingEnabled(this.logLevel_)
                    && this.logLevel_ >= globalLogLevel
                    && globalLogLevel != LogLevel.off
                    && this.logLevel_ != LogLevel.off)
            {
                this.logHeader(file, line, funcName, prettyFuncName,
                    moduleName, this.logLevel_, thisTid, Clock.currTime);

                auto writer = MsgRange(this);
                formattedWrite(writer, msg, args);

                this.finishLogMsg();
            }
        }
    }

    private LogLevel logLevel_ = LogLevel.info;
    private void delegate() fatalHandler;
    protected Appender!string msgAppender;
    protected LogEntry header;
}

/** This method returns the default $(D Logger).

The Logger is returned as a reference. This means it can be reassigned,
thus changing the $(D stdlog).

Example:
-------------
stdlog = new StdioLogger;
-------------
The example sets a new $(D StdioLogger) as new $(D stdlog).
*/
@property ref Logger stdlog() @trusted
{
    static __gshared Logger logger;
    if (logger is null)
    {
        logger = new FileLogger(stderr, globalLogLevel());
    }
    return logger;
}

private ref LogLevel globalLogLevelImpl() @trusted
{
    static __gshared LogLevel ll = LogLevel.all;
    return ll;
}

/** This method returns the global $(D LogLevel). */
@property LogLevel globalLogLevel() @trusted
{
    return globalLogLevelImpl();
}

/** This method sets the global $(D LogLevel).

Every log message with a $(D LogLevel) lower as the global $(D LogLevel)
will be discarded before it reaches $(D writeLogMessage) method.
*/
@property void globalLogLevel(LogLevel ll) @trusted
{
    if (stdlog !is null)
    {
        stdlog.logLevel = ll;
    }
    globalLogLevelImpl() = ll;
}

version (unittest)
{
    import std.array;
    import std.ascii;
    import std.random;

    @trusted string randomString(size_t upto)
    {
        auto app = Appender!string();
        foreach(_ ; 0 .. upto)
            app.put(letters[uniform(0, letters.length)]);
        return app.data;
    }
}

@safe unittest
{
    LogLevel ll = globalLogLevel;
    globalLogLevel = LogLevel.fatal;
    assert(globalLogLevel == LogLevel.fatal);
    globalLogLevel = ll;
}

version (unittest)
{
    class TestLogger : Logger
    {
        int line = -1;
        string file = null;
        string func = null;
        string prettyFunc = null;
        string msg = null;
        LogLevel lvl;

        this(const LogLevel lv = LogLevel.info) @safe
        {
            super(lv);
        }

        override void writeLogMsg(ref LogEntry payload) @safe
        {
            this.line = payload.line;
            this.file = payload.file;
            this.func = payload.funcName;
            this.prettyFunc = payload.prettyFuncName;
            this.lvl = payload.logLevel;
            this.msg = payload.msg;
        }
    }

    void testFuncNames(Logger logger) {
        string s = "I'm here";
        logger.log(s);
    }
}

unittest
{
    auto tl1 = new TestLogger();
    testFuncNames(tl1);
    assert(tl1.func == "std.logger.core.testFuncNames", tl1.func);
    assert(tl1.prettyFunc ==
        "void std.logger.core.testFuncNames(Logger logger)", tl1.prettyFunc);
    assert(tl1.msg == "I'm here", tl1.msg);
}

@safe unittest
{
    auto oldunspecificLogger = stdlog;
    LogLevel oldLogLevel = globalLogLevel;
    scope(exit)
    {
        stdlog = oldunspecificLogger;
        globalLogLevel = oldLogLevel;
    }

    stdlog = new TestLogger();

    auto ll = [LogLevel.trace, LogLevel.info, LogLevel.warning,
         LogLevel.error, LogLevel.critical, LogLevel.fatal, LogLevel.off];

}

unittest
{
    auto tl1 = new TestLogger;
    auto tl2 = new TestLogger;

    auto ml = new MultiLogger();
    ml.insertLogger("one", tl1);
    ml.insertLogger("two", tl2);
    assertThrown!Exception(ml.insertLogger("one", tl1));

    string msg = "Hello Logger World";
    ml.log(msg);
    int lineNumber = __LINE__ - 1;
    assert(tl1.msg == msg);
    assert(tl1.line == lineNumber);
    assert(tl2.msg == msg);
    assert(tl2.line == lineNumber);

    ml.removeLogger("one");
    ml.removeLogger("two");
    assertThrown!Exception(ml.removeLogger("one"));
}

@safe unittest
{
    bool errorThrown = false;
    auto tl = new TestLogger;
    auto dele = delegate() {
        errorThrown = true;
    };
    tl.setFatalHandler(dele);
    tl.fatal();
    assert(errorThrown);
}

@safe unittest
{
    auto l = new TestLogger(LogLevel.info);
    string msg = "Hello Logger World";
    l.log(msg);
    int lineNumber = __LINE__ - 1;
    assert(l.msg == msg);
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    l.log(true, msg);
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg);
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    l.log(false, msg);
    assert(l.msg == msg);
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    msg = "%s Another message";
    l.logf(msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    l.logf(true, msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    l.logf(false, msg, "Yet");
    int nLineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    l.logf(LogLevel.fatal, msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    l.logf(LogLevel.fatal, true, msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    l.logf(LogLevel.fatal, false, msg, "Yet");
    nLineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    auto oldunspecificLogger = stdlog;

    assert(oldunspecificLogger.logLevel == LogLevel.all,
         to!string(oldunspecificLogger.logLevel));

    assert(l.logLevel == LogLevel.info);
    stdlog = l;
    assert(globalLogLevel == LogLevel.all,
            to!string(globalLogLevel));

    scope(exit)
    {
        stdlog = oldunspecificLogger;
    }

    assert(stdlog.logLevel == LogLevel.info);
    assert(globalLogLevel == LogLevel.all);

    msg = "Another message";
    log(msg);
    lineNumber = __LINE__ - 1;
    assert(l.logLevel == LogLevel.info);
    assert(l.line == lineNumber, to!string(l.line));
    assert(l.msg == msg, l.msg);

    log(true, msg);
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg);
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    log(false, msg);
    assert(l.msg == msg);
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    msg = "%s Another message";
    logf(msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    logf(true, msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    logf(false, msg, "Yet");
    nLineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    msg = "%s Another message";
    logf(LogLevel.fatal, msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    logf(LogLevel.fatal, true, msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    logf(LogLevel.fatal, false, msg, "Yet");
    nLineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);
}

unittest // default logger
{
    import std.file;
    string name = randomString(32);
    string filename = randomString(32) ~ ".tempLogFile";
    FileLogger l = new FileLogger(filename);
    auto oldunspecificLogger = stdlog;
    stdlog = l;

    scope(exit)
    {
        remove(filename);
        stdlog = oldunspecificLogger;
        globalLogLevel = LogLevel.all;
    }

    string notWritten = "this should not be written to file";
    string written = "this should be written to file";

    globalLogLevel = LogLevel.critical;
    assert(l.logLevel == LogLevel.critical);

    log(LogLevel.warning, notWritten);
    log(LogLevel.critical, written);

    l.file.flush();
    l.file.close();

    auto file = File(filename, "r");
    assert(!file.eof);

    string readLine = file.readln();
    assert(readLine.indexOf(written) != -1, readLine);
    assert(readLine.indexOf(notWritten) == -1, readLine);
    file.close();
}

unittest
{
    import std.file;
    import core.memory;
    string name = randomString(32);
    string filename = randomString(32) ~ ".tempLogFile";
    auto oldunspecificLogger = stdlog;

    scope(exit)
    {
        remove(filename);
        stdlog = oldunspecificLogger;
        globalLogLevel = LogLevel.all;
    }

    string notWritten = "this should not be written to file";
    string written = "this should be written to file";

    auto l = new FileLogger(filename);
    stdlog = l;
    stdlog.logLevel = LogLevel.critical;

    log(LogLevel.error, false, notWritten);
    log(LogLevel.critical, true, written);
    destroy(l);

    auto file = File(filename, "r");
    auto readLine = file.readln();
    assert(!readLine.empty, readLine);
    assert(readLine.indexOf(written) != -1);
    assert(readLine.indexOf(notWritten) == -1);
    file.close();
}

@safe unittest
{
    auto tl = new TestLogger(LogLevel.all);
    int l = __LINE__;
    tl.info("a");
    assert(tl.line == l+1);
    assert(tl.msg == "a");
    assert(tl.logLevel == LogLevel.all);
    assert(globalLogLevel == LogLevel.all);
    l = __LINE__;
    tl.trace("b");
    assert(tl.msg == "b", tl.msg);
    assert(tl.line == l+1, to!string(tl.line));
}

//pragma(msg, buildLogFunction(true, false, true, LogLevel.unspecific, true));

// testing possible log conditions
@safe unittest
{
    auto oldunspecificLogger = stdlog;

    auto mem = new TestLogger;
    stdlog = mem;

    scope(exit)
    {
        stdlog = oldunspecificLogger;
        globalLogLevel = LogLevel.all;
    }

    int value = 0;
    foreach(gll; [LogLevel.all, LogLevel.trace,
            LogLevel.info, LogLevel.warning, LogLevel.error,
            LogLevel.critical, LogLevel.fatal, LogLevel.off])
    {

        globalLogLevel = gll;

        foreach(ll; [LogLevel.all, LogLevel.trace,
                LogLevel.info, LogLevel.warning, LogLevel.error,
                LogLevel.critical, LogLevel.fatal, LogLevel.off])
        {

            mem.logLevel = ll;

            foreach(cond; [true, false])
            {
                foreach(condValue; [true, false])
                {
                    foreach(memOrG; [true, false])
                    {
                        foreach(prntf; [true, false])
                        {
                            foreach(ll2; [LogLevel.all, LogLevel.trace,
                                    LogLevel.info, LogLevel.warning,
                                    LogLevel.error, LogLevel.critical,
                                    LogLevel.fatal, LogLevel.off])
                            {
                                int lineCall;
                                mem.msg = "-1";
                                if (memOrG)
                                {
                                    if (prntf)
                                    {
                                        if (cond)
                                        {
                                            mem.logf(ll2, condValue, "%s",
                                                value);
                                            lineCall = __LINE__;
                                        }
                                        else
                                        {
                                            mem.logf(ll2, "%s", value);
                                            lineCall = __LINE__;
                                        }
                                    }
                                    else
                                    {
                                        if (cond)
                                        {
                                            mem.log(ll2, condValue,
                                                to!string(value));
                                            lineCall = __LINE__;
                                        }
                                        else
                                        {
                                            mem.log(ll2, to!string(value));
                                            lineCall = __LINE__;
                                        }
                                    }
                                }
                                else
                                {
                                    if (prntf)
                                    {
                                        if (cond)
                                        {
                                            logf(ll2, condValue, "%s", value);
                                            lineCall = __LINE__;
                                        }
                                        else
                                        {
                                            logf(ll2, "%s", value);
                                            lineCall = __LINE__;
                                        }
                                    }
                                    else
                                    {
                                        if (cond)
                                        {
                                            log(ll2, condValue,
                                                to!string(value));
                                            lineCall = __LINE__;
                                        }
                                        else
                                        {
                                            log(ll2, to!string(value));
                                            lineCall = __LINE__;
                                        }
                                    }
                                }

                                string valueStr = to!string(value);
                                ++value;

                                bool gllOff = (gll != LogLevel.off);
                                bool llOff = (ll != LogLevel.off);
                                bool condFalse = (cond ? condValue : true);
                                bool ll2VSgll = (ll2 >= gll);
                                bool ll2VSll = (ll2 >= ll);

                                bool shouldLog = gllOff && llOff && condFalse
                                    && ll2VSgll && ll2VSll;

                                /*
                                writefln(
                                    "go(%b) ll2o(%b) c(%b) lg(%b) ll(%b) s(%b)"
                                    , gll != LogLevel.off, ll2 != LogLevel.off,
                                    cond ? condValue : true,
                                    ll2 >= gll, ll2 >= ll, shouldLog);
                                */


                                if (shouldLog)
                                {
                                    assert(mem.msg == valueStr, format(
                                        "lineCall(%d) gll(%u) ll(%u) ll2(%u) " ~
                                        "cond(%b) condValue(%b)" ~
                                        " memOrG(%b) shouldLog(%b) %s == %s" ~
                                        " %b %b %b %b %b",
                                        lineCall, gll, ll, ll2, cond,
                                        condValue, memOrG, shouldLog, mem.msg,
                                        valueStr, gllOff, llOff, condFalse,
                                        ll2VSgll, ll2VSll
                                    ));
                                }
                                else
                                {
                                    assert(mem.msg != valueStr, format(
                                        "lineCall(%d) gll(%u) ll(%u) ll2(%u) " ~
                                        " cond(%b)condValue(%b)  memOrG(%b) " ~
                                        "shouldLog(%b) %s != %s", gll,
                                        lineCall, ll, ll2, cond, condValue,
                                        memOrG, shouldLog, mem.msg, valueStr
                                    ));
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// testing more possible log conditions
@safe unittest
{
    auto mem = new TestLogger;
    auto oldunspecificLogger = stdlog;

    stdlog = mem;
    scope(exit)
    {
        stdlog = oldunspecificLogger;
        globalLogLevel = LogLevel.all;
    }

    foreach(gll; [LogLevel.all, LogLevel.trace,
            LogLevel.info, LogLevel.warning, LogLevel.error,
            LogLevel.critical, LogLevel.fatal, LogLevel.off])
    {

        globalLogLevel = gll;

        foreach(ll; [LogLevel.all, LogLevel.trace,
                LogLevel.info, LogLevel.warning, LogLevel.error,
                LogLevel.critical, LogLevel.fatal, LogLevel.off])
        {
            mem.logLevel = ll;

            foreach(cond; [true, false])
            {
                assert(globalLogLevel == gll);
                assert(mem.logLevel == ll);

                bool gllVSll = LogLevel.trace >= globalLogLevel;
                bool llVSgll = ll >= globalLogLevel;
                bool lVSll = LogLevel.trace >= ll;
                bool gllOff = globalLogLevel != LogLevel.off;
                bool llOff = mem.logLevel != LogLevel.off;

                bool test = llVSgll && gllVSll && lVSll && gllOff && llOff && cond;

                mem.line = -1;
                /*
                writefln("gll(%3u) ll(%3u) cond(%b) test(%b)",
                    gll, ll, cond, test);
                writefln("%b %b %b %b %b %b test2(%b)", llVSgll, gllVSll, lVSll,
                    gllOff, llOff, cond, test2);
                */

                mem.trace(__LINE__); int line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                trace(__LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.trace(cond, __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                trace(cond, __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.tracef("%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                tracef("%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.tracef(cond, "%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                tracef(cond, "%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                llVSgll = ll >= globalLogLevel;
                lVSll = LogLevel.trace >= ll;
                test = llVSgll && gllVSll && lVSll && gllOff && llOff && cond;

                mem.info(__LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                info(__LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.info(cond, __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                info(cond, __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.infof("%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                infof("%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.infof(cond, "%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                infof(cond, "%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                llVSgll = ll >= globalLogLevel;
                lVSll = LogLevel.trace >= ll;
                test = llVSgll && gllVSll && lVSll && gllOff && llOff && cond;

                mem.warning(__LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                warning(__LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.warning(cond, __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                warning(cond, __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.warningf("%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                warningf("%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.warningf(cond, "%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                warningf(cond, "%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                llVSgll = ll >= globalLogLevel;
                lVSll = LogLevel.trace >= ll;
                test = llVSgll && gllVSll && lVSll && gllOff && llOff && cond;

                mem.critical(__LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                critical(__LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.critical(cond, __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                critical(cond, __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.criticalf("%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                criticalf("%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.criticalf(cond, "%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                criticalf(cond, "%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;
            }

        }
    }
}

// Issue #5
unittest
{
    auto oldunspecificLogger = stdlog;

    scope(exit)
    {
        stdlog = oldunspecificLogger;
        globalLogLevel = LogLevel.all;
    }

    auto tl = new TestLogger(LogLevel.info);
    stdlog = tl;

    trace("trace");
    assert(tl.msg.indexOf("trace") == -1);
    //info("info");
    //assert(tl.msg.indexOf("info") == 0);
}

// Issue #5
unittest
{
    auto oldunspecificLogger = stdlog;

    scope(exit)
    {
        stdlog = oldunspecificLogger;
        globalLogLevel = LogLevel.all;
    }

    auto logger = new MultiLogger(LogLevel.error);

    auto tl = new TestLogger(LogLevel.info);
    logger.insertLogger("required", tl);
    stdlog = logger;

    trace("trace");
    assert(tl.msg.indexOf("trace") == -1);
    info("info");
    assert(tl.msg.indexOf("info") == -1);
    error("error");
    assert(tl.msg.indexOf("error") == 0);
}

unittest
{
    import std.exception : assertThrown;
    auto tl = new TestLogger();
    assertThrown!Throwable(tl.fatal("fatal"));
}

unittest
{
    auto dl = cast(FileLogger)stdlog;
    assert(dl !is null);
    assert(dl.logLevel == LogLevel.all);
    assert(globalLogLevel == LogLevel.all);
}
