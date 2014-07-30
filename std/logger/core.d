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
log("Logging to the defaultLogger with its default LogLevel");
logf(LogLevel.info, 5 < 6, "%s to the defaultLogger with its LogLevel.info", "Logging");
info("Logging to the defaultLogger with its info LogLevel");
warning(5 < 6, "Logging to the defaultLogger with its LogLevel.warning if 5 is less than 6");
error("Logging to the defaultLogger with its error LogLevel");
errorf("Logging %s the defaultLogger %s its error LogLevel", "to", "with");
critical("Logging to the"," defaultLogger with its error LogLevel");
fatal("Logging to the defaultLogger with its fatal LogLevel");

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
object called $(D defaultLogger).
$(LI $(D log))
$(LI $(D trace))
$(LI $(D info))
$(LI $(D warning))
$(LI $(D critical))
$(LI $(D fatal))
The default $(D Logger) will by default log to $(D stdout) and has a default
$(D LogLevel) of $(D LogLevel.all). The default Logger can be accessed by
using a property call $(D defaultLogger). This property a reference to the
current default $(D Logger). This reference can be used to assign a new
default $(D Logger).
-------------
defaultLogger = new FileLogger("New_Default_Log_File.log");
-------------

Additional $(D Logger) can be created by creating a new instance of the
required $(D Logger). These $(D Logger) have the same methodes as the
$(D defaultLogger).

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

To customize the logger behaviour, create a new $(D class) that inherits from
the abstract $(D Logger) $(D class), and implements the $(D writeLogMsg)
method.
-------------
class MyCustomLogger : Logger {
    this(string newName, LogLevel lv) @safe
    {
        super(newName, lv);
    }

    override void writeLogMsg(ref LoggerPayload payload)
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

In order to disable logging at compile time, pass $(D DisableLogger) as a
version argument to the $(D D) compiler.
*/
module std.logger.core;

import std.array;
import std.stdio;
import std.conv;
import std.datetime;
import std.string;
import std.range;
import std.exception;
import std.concurrency;
import std.format;

import std.logger.stdiologger;
import std.logger.stderrlogger;
import std.logger.multilogger;
import std.logger.filelogger;
import std.logger.nulllogger;

	version(DisableTrace)
	    immutable TraceLoggingDisabled = true;
	else
	    immutable TraceLoggingDisabled = false;
	
	version(DisableInfo)
	    immutable InfoLoggingDisabled = true;
	else
	    immutable InfoLoggingDisabled = false;
	
	version(DisableWarning)
	    immutable WarningLoggingDisabled = true;
	else
	    immutable WarningLoggingDisabled = false;
	
	version(DisableCritical)
	    immutable CriticalLoggingDisabled = true;
	else
	    immutable CriticalLoggingDisabled = false;
	
	version(DisableFatal)
	    immutable FatalLoggingDisabled = true;
	else
	    immutable FatalLoggingDisabled = false;
	
	version(DisableBelowTrace)
	    immutable BelowTraceLoggingDisabled = true;
	else
	    immutable BelowTraceLoggingDisabled = false;
	
	version(DisableBelowInfo)
	    immutable BelowInfoLoggingDisabled = true;
	else
	    immutable BelowInfoLoggingDisabled = false;
	
	version(DisableBelowWarning)
	    immutable BelowWarningLoggingDisabled = true;
	else
	    immutable BelowWarningLoggingDisabled = false;
	
	version(DisableBelowCritical)
	    immutable BelowCriticalLoggingDisabled = true;
	else
	    immutable BelowCriticalLoggingDisabled = false;
	
	version(DisableBelowFatal)
	    immutable BelowFatalLoggingDisabled = true;
	else
	    immutable BelowFatalLoggingDisabled = false;

pure bool isLoggingEnabled(LogLevel ll) @safe nothrow
{
    version(DisableLogging)
    {
        return false;
    }
    else
    {
        bool isDisabled;
        switch(ll)
        {
            case LogLevel.trace:
                isDisabled = TraceLoggingDisabled;
                break;
            case LogLevel.info:
                isDisabled = InfoLoggingDisabled;
                break;
            case LogLevel.warning:
                isDisabled = WarningLoggingDisabled;
                break;
            case LogLevel.critical:
                isDisabled = CriticalLoggingDisabled;
                break;
            case LogLevel.fatal:
                isDisabled = FatalLoggingDisabled;
                break;
            default: break;
        }

        if(isDisabled)
        {
            return false;
        }

        if (ll < LogLevel.trace && BelowTraceLoggingDisabled)
        {
            return false;
        }
        if (ll < LogLevel.info && BelowInfoLoggingDisabled)
        {
            return false;
        }
        if (ll < LogLevel.warning && BelowWarningLoggingDisabled)
        {
            return false;
        }
        if (ll < LogLevel.critical && BelowCriticalLoggingDisabled)
        {
            return false;
        }
        if (ll < LogLevel.fatal && BelowFatalLoggingDisabled)
        {
            return false;
        }

        return true;
    }
}

unittest
{
    foreach(ll; [LogLevel.trace, LogLevel.info, LogLevel.warning,
            LogLevel.critical, LogLevel.fatal])
    {
        assert(isLoggingEnabled(ll));
    }
}

/** This function logs data.

In order for the data to be processed the $(D LogLevel) of the
$(D defaultLogger) must be greater equal to the global $(D LogLevel).

Params:
args = The data that should be logged.

Returns: The logger used by the logging function as reference.

Examples:
--------------------
log("Hello World", 3.1415);
--------------------
*/
void log(int line = __LINE__, string file = __FILE__,
    string funcName = __FUNCTION__,
    string prettyFuncName = __PRETTY_FUNCTION__,
    string moduleName = __MODULE__, A...)(const LogLevel ll, 
	lazy bool condition, lazy A args) 
{
	version(DisableLogging)
	{
	}
	else
	{
        if (isLoggingEnabled(ll)
                && ll >= globalLogLevel
                && ll >= defaultLogger.logLevel
                && globalLogLevel != LogLevel.off
                && defaultLogger.logLevel != LogLevel.off
                && condition)
        {
            defaultLogger.log!(line, file, funcName,prettyFuncName,
                moduleName)(ll, args);
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
	version(DisableLogging)
	{
	}
	else
	{
        if (isLoggingEnabled(ll)
                && ll >= globalLogLevel
                && ll >= defaultLogger.logLevel
                && globalLogLevel != LogLevel.off
                && defaultLogger.logLevel != LogLevel.off )
        {
            defaultLogger.log!(line, file, funcName,prettyFuncName,
                moduleName)(ll, args);
        }
	}
}

void log(int line = __LINE__, string file = __FILE__,
    string funcName = __FUNCTION__,
    string prettyFuncName = __PRETTY_FUNCTION__,
    string moduleName = __MODULE__, A...)(lazy bool condition, lazy A args)
	@trusted
{
	version(DisableLogging)
	{
	}
	else
	{
        if (isLoggingEnabled(defaultLogger.logLevel)
                && defaultLogger.logLevel >= globalLogLevel
                && globalLogLevel != LogLevel.off
                && defaultLogger.logLevel != LogLevel.off 
				&& condition)
        {
            defaultLogger.log!(line, file, funcName,prettyFuncName,
                moduleName)(args);
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
	version(DisableLogging)
	{
	}
	else
	{
        if (isLoggingEnabled(defaultLogger.logLevel)
                && defaultLogger.logLevel >= globalLogLevel
                && globalLogLevel != LogLevel.off
                && defaultLogger.logLevel != LogLevel.off)
        {
            defaultLogger.log!(line, file, funcName,prettyFuncName,
                moduleName)(args);
        }
    }
}
/+
    else
    {
        if (isLoggingEnabled(defaultLogger.logLevel)
                && defaultLogger.logLevel >= globalLogLevel
                && globalLogLevel != LogLevel.off
                && defaultLogger.logLevel != LogLevel.off)
        {
            defaultLogger.log!(line, file, funcName,prettyFuncName,
                moduleName)(args);
        }
    }
	}
}
+/


/** This function logs data in a $(D printf)-style manner.

In order for the data to be processed the $(D LogLevel) of the
$(D defaultLogger) must be greater equal to the global $(D LogLevel).

Params:
args = The data that should be logged.

Returns: The logger used by the logging function as reference.

Examples:
--------------------
logf("Hello World %f", 3.1415);
--------------------
*/
version(DisableLogging)
{
    ref Logger logf(int line = __LINE__, string file = __FILE__,
        string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(A args) @trusted
    {

        return defaultLogger;
    }
}
else
{
    ref Logger logf(int line = __LINE__, string file = __FILE__,
        string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(lazy A args) @trusted
    {

        static if (args.length > 2 && is(A[0] == LogLevel)
            && is(A[1] : bool))
        {
            if (isLoggingEnabled(args[0])
                    && args[0] >= globalLogLevel
                    && args[0] >= defaultLogger.logLevel
                    && globalLogLevel != LogLevel.off
                    && defaultLogger.logLevel != LogLevel.off
                    && args[1])
            {
                defaultLogger.logf!(line, file, funcName,prettyFuncName,
                    moduleName)(args[0], args[2 .. $]);
            }
        }
        else static if (args.length > 1 && is(A[0] == LogLevel))
        {
            if (isLoggingEnabled(args[0])
                    && args[0] >= globalLogLevel
                    && args[0] >= defaultLogger.logLevel
                    && globalLogLevel != LogLevel.off
                    && defaultLogger.logLevel != LogLevel.off )
            {
                defaultLogger.logf!(line, file, funcName,prettyFuncName,
                    moduleName)(args);
            }
        }
        else static if (args.length > 1 && is(A[0] : bool))
        {
            if (isLoggingEnabled(defaultLogger.logLevel)
                    && defaultLogger.logLevel >= globalLogLevel
                    && globalLogLevel != LogLevel.off
                    && defaultLogger.logLevel != LogLevel.off
                    && args[0])
            {
                defaultLogger.logf!(line, file, funcName,prettyFuncName,
                    moduleName)(args[1 .. $]);
            }
        }
        else
        {
            if (isLoggingEnabled(defaultLogger.logLevel)
                    && defaultLogger.logLevel >= globalLogLevel
                    && globalLogLevel != LogLevel.off
                    && defaultLogger.logLevel != LogLevel.off)
            {
                defaultLogger.logf!(line, file, funcName,prettyFuncName,
                    moduleName)(args);
            }
        }
        return defaultLogger;
    }
}

///
template DefaultLogFunction(LogLevel ll)
{
    /** This function logs data in a writeln style manner to the
    $(D defaultLogger).

    In order for the resulting log message to be logged the $(D LogLevel) must
    be greater or equal than the $(D LogLevel) of the $(D defaultLogger) and
    must be greater or equal than the global $(D LogLevel).

    Params:
    args = The data that should be logged.

    Returns: The logger used by the logging function as reference.

    Examples:
    --------------------
    trace(1337, "is number");
    info(1337, "is number");
    error(1337, "is number");
    critical(1337, "is number");
    fatal(1337, "is number");
    --------------------
    */
    ref Logger DefaultLogFunction(int line = __LINE__,
        string file = __FILE__, string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(lazy A args) @trusted
    {
        static if (args.length > 1 && is(A[0] : bool))
        {
            if (isLoggingEnabled(ll)
                    && ll >= defaultLogger.logLevel
                    && defaultLogger.logLevel >= globalLogLevel
                    && globalLogLevel != LogLevel.off
                    && defaultLogger.logLevel != LogLevel.off
                    && args[0])
            {
                defaultLogger.MemLogFunctions!(ll).logImpl!(line, file,
                       funcName, prettyFuncName, moduleName)(args[1 .. $]);
            }
        }
        else
        {
            if (isLoggingEnabled(ll)
                    && ll >= defaultLogger.logLevel
                    && defaultLogger.logLevel >= globalLogLevel
                    && globalLogLevel != LogLevel.off
                    && defaultLogger.logLevel != LogLevel.off)
            {
                defaultLogger.MemLogFunctions!(ll).logImpl!(line, file,
                       funcName, prettyFuncName, moduleName)(args);
            }
        }

        return defaultLogger;
    }
}

template DefaultLogFunctionDisabled(LogLevel ll)
{
    ref Logger DefaultLogFunction(int line = __LINE__,
        string file = __FILE__, string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(A) @trusted
    {
        return defaultLogger;
    }
}
/// Ditto
version(TraceLoggingDisabled)
    alias trace = DefaultLogFunctionDisabled!(LogLevel.trace);
else
    alias trace = DefaultLogFunction!(LogLevel.trace);
/// Ditto
version(InfoLoggingDisabled)
    alias info = DefaultLogFunctionDisabled!(LogLevel.info);
else
    alias info = DefaultLogFunction!(LogLevel.info);

/// Ditto
version(WarningLoggingDisabled)
    alias warning = DefaultLogFunctionDisabled!(LogLevel.warning);
else
    alias warning = DefaultLogFunction!(LogLevel.warning);

/// Ditto
version(ErrorLoggingDisabled)
    alias error = DefaultLogFunctionDisabled!(LogLevel.error);
else
    alias error = DefaultLogFunction!(LogLevel.error);

/// Ditto
version(CriticalLoggingDisabled)
    alias critical = DefaultLogFunctionDisabled!(LogLevel.critical);
else
    alias critical = DefaultLogFunction!(LogLevel.critical);

/// Ditto
version(FatalLoggingDisabled)
    alias fatal = DefaultLogFunctionDisabled!(LogLevel.fatal);
else
    alias fatal = DefaultLogFunction!(LogLevel.fatal);

///
template DefaultLogFunctionf(LogLevel ll)
{
    /** This function logs data in a writefln style manner to the
    $(D defaultLogger).

    In order for the resulting log message to be logged the $(D LogLevel) must
    be greater or equal than the $(D LogLevel) of the $(D defaultLogger) and
    must be greater or equal than the global $(D LogLevel).

    Params:
    args = The data that should be logged.

    Returns: The logger used by the logging function as reference.

    Examples:
    --------------------
    tracef("%d %s", 1337, "is number");
    infof("%d %s", 1337, "is number");
    errorf("%d %s", 1337, "is number");
    criticalf("%d %s", 1337, "is number");
    fatalf("%d %s", 1337, "is number");
    --------------------
    */
    ref Logger DefaultLogFunctionf(int line = __LINE__,
        string file = __FILE__, string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(lazy A args)
        @trusted
    {
        static if (args.length > 1 && is(A[0] : bool))
        {
            if (isLoggingEnabled(ll)
                    && ll >= defaultLogger.logLevel
                    && defaultLogger.logLevel >= globalLogLevel
                    && globalLogLevel != LogLevel.off
                    && defaultLogger.logLevel != LogLevel.off
                    && args[0])
            {
                defaultLogger.MemLogFunctions!(ll).logImplf!(line, file,
                       funcName, prettyFuncName, moduleName)(args[1 .. $]);
            }
        }
        else
        {
            if (isLoggingEnabled(ll)
                    && ll >= defaultLogger.logLevel
                    && defaultLogger.logLevel >= globalLogLevel
                    && globalLogLevel != LogLevel.off
                    && defaultLogger.logLevel != LogLevel.off)
            {
                defaultLogger.MemLogFunctions!(ll).logImplf!(line, file,
                       funcName, prettyFuncName, moduleName)(args);
            }
        }

        return defaultLogger;
    }
}

/// Ditto
template DefaultLogFunctionfDisabled(LogLevel ll)
{
    ref Logger DefaultLogFunctionf(int line = __LINE__,
        string file = __FILE__, string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(A)
        @trusted
    {
        return defaultLogger;
    }
}

/// Ditto
version(TraceLoggingDisabled)
    alias tracef = DefaultLogFunctionfDisabled!(LogLevel.trace);
else
    alias tracef = DefaultLogFunctionf!(LogLevel.trace);

/// Ditto
version(InfoLoggingDisabled)
    alias infof = DefaultLogFunctionfDisabled!(LogLevel.info);
else
    alias infof = DefaultLogFunctionf!(LogLevel.info);

/// Ditto
version(WarningLoggingDisabled)
    alias warningf = DefaultLogFunctionfDisabled!(LogLevel.warning);
else
    alias warningf = DefaultLogFunctionf!(LogLevel.warning);

/// Ditto
version(ErrorLoggingDisabled)
    alias errorf = DefaultLogFunctionfDisabled!(LogLevel.error);
else
    alias errorf = DefaultLogFunctionf!(LogLevel.error);

/// Ditto
version(CriticalLoggingDisabled)
    alias criticalf = DefaultLogFunctionfDisabled!(LogLevel.critical);
else
    alias criticalf = DefaultLogFunctionf!(LogLevel.critical);

/// Ditto
version(FatalLoggingDisabled)
    alias fatalf = DefaultLogFunctionfDisabled!(LogLevel.fatal);
else
    alias fatalf = DefaultLogFunctionf!(LogLevel.fatal);

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
        std.format.formattedWrite(oRange, "%s", arg);
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
    fatal = 192,   /** Log messages that describe fatel errors should use this
                  level. */
    off = ubyte.max /** Highest possible $(D LogLevel). */
}

/** This class is the base of every logger. In order to create a new kind of
logger a deriving class needs to implement the $(D writeLogMsg) method.
*/
abstract class Logger
{
    /** LoggerPayload is a aggregation combining all information associated
    with a log message. This aggregation will be passed to the method
    writeLogMsg.
    */
    protected struct LoggerPayload
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
        /// the name of the module
        string moduleName;
        /// the $(D LogLevel) associated with the log message
        LogLevel logLevel;
        /// thread id
        Tid threadId;
        /// the time the message was logged.
        SysTime timestamp;
        /// the message
        string msg;
    }

    /** This constructor takes a name of type $(D string), and a $(D LogLevel).

    Every subclass of $(D Logger) has to call this constructor from there
    constructor. It sets the $(D LogLevel), the name of the $(D Logger), and
    creates a fatal handler. The fatal handler will throw an $(D Error) if a
    log call is made with a $(D LogLevel) $(D LogLevel.fatal).
    */
    this(string newName, LogLevel lv) @safe
    {
        this.logLevel = lv;
        this.name = newName;
        this.fatalHandler = delegate() {
            throw new Error("A Fatal Log Message was logged");
        };

        this.msgAppender = appender!string();
    }

    /** A custom logger needs to implement this method.
    Params:
        payload = All information associated with call to log function.
    */
    void writeLogMsg(ref LoggerPayload payload) {}

    /* The default implementation will use an $(D std.array.appender)
    internally to construct the message string. This means dynamic,
    GC memory allocation. A logger can avoid this allocation by
    reimplementing $(D logHeader), $(D logMsgPart) and $(D finishLogMsg).
    $(D logHeader) is always called first, followed by any number of calls
    to $(D logMsgPart) and one call to $(D finishLogMsg).
    */
    public void logHeader(string file, int line, string funcName,
        string prettyFuncName, string moduleName, LogLevel logLevel,
        Tid threadId, SysTime timestamp)
        @trusted
    {
        version(DisableLogging)
        {
        }
        else
        {
            header = LoggerPayload(file, line, funcName, prettyFuncName,
                moduleName, logLevel, threadId, timestamp, null);
        }
    }

    /** Logs a part of the log message. */
    public void logMsgPart(const(char)[] msg)
    {
        version(DisableLogging)
        {
        }
        else
        {
            msgAppender.put(msg);
        }
    }

    /** Signals that the message has been written and no more calls to
    $(D logMsgPart) follow. */
    public void finishLogMsg()
    {
        version(DisableLogging)
        {
        }
        else
        {
            header.msg = msgAppender.data;
            this.writeLogMsg(header);
            msgAppender = appender!string();
        }
    }

    /** This method is the entry point into each logger. It compares the given
    $(D LogLevel) with the $(D LogLevel) of the $(D Logger), and the global
    $(LogLevel). If the passed $(D LogLevel) is greater or equal to both the
    message, and all other parameter are passed to the abstract method
    $(D writeLogMsg).
    */
    /+
    void logMessage(string file, int line, string funcName,
            string prettyFuncName, string moduleName, LogLevel logLevel,
            string msg)
        @trusted
    {
        version(DisableLogging)
        {
        }
        else
        {
            auto lp = LoggerPayload(file, line, funcName, prettyFuncName,
                moduleName, logLevel, thisTid, Clock.currTime, msg);
            this.writeLogMsg(lp);
        }
    }
    +/

    /** Get the $(D LogLevel) of the logger. */
    @property final LogLevel logLevel() const pure nothrow @safe
    {
        return this.logLevel_;
    }

    /** Set the $(D LogLevel) of the logger. The $(D LogLevel) can not be set
    to $(D LogLevel.unspecific).*/
    @property final void logLevel(const LogLevel lv) pure nothrow @safe
    {
        this.logLevel_ = lv;
    }

    /** Get the $(D name) of the logger. */
    @property final string name() const pure nothrow @safe
    {
        return this.name_;
    }

    /** Set the name of the logger. */
    @property final void name(string newName) pure nothrow @safe
    {
        this.name_ = newName;
    }

    /** This methods sets the $(D delegate) called in case of a log message
    with $(D LogLevel.fatal).

    By default an $(D Error) will be thrown.
    */
    final void setFatalHandler(void delegate() dg) @safe {
        this.fatalHandler = dg;
    }

    ///
    template MemLogFunctions(LogLevel ll)
    {
        /** This function logs data in a writeln style manner to the
        used logger.

        In order for the resulting log message to be logged the $(D LogLevel)
        must be greater or equal than the $(D LogLevel) of the used $(D Logger)
        and must be greater or equal than the global $(D LogLevel).

        Params:
        args = The data that should be logged.

        Returns: The logger used by the logging function as reference.

        Examples:
        --------------------
        Logger g;
        g.trace(1337, "is number");
        g.info(1337, "is number");
        g.error(1337, "is number");
        g.critical(1337, "is number");
        g.fatal(1337, "is number");
        --------------------
        */
        ref Logger logImpl(int line = __LINE__,
            string file = __FILE__, string funcName = __FUNCTION__,
            string prettyFuncName = __PRETTY_FUNCTION__,
            string moduleName = __MODULE__, A...)(lazy A args) @trusted
        {
            static if (args.length > 1 && is(A[0] : bool))
            {
                if (isLoggingEnabled(ll)
                        && ll >= this.logLevel_
                        && ll >= globalLogLevel
                        && globalLogLevel != LogLevel.off
                        && this.logLevel_ != LogLevel.off
                        && args[0])
                {
                    this.logHeader(file, line, funcName, prettyFuncName,
                        moduleName, ll, thisTid, Clock.currTime);

                    auto writer = MsgRange(this);
                    formatString(writer, args[1 .. $]);

                    this.finishLogMsg();

                    static if (ll == LogLevel.fatal)
                        fatalHandler();
                }
            }
            else
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

            return this;
        }

        /** This function logs data in a writefln style manner to the
        used $(D Logger).

        In order for the resulting log message to be logged the $(D LogLevel)
        must be greater or equal than the $(D LogLevel) of the used $(D Logger)
        and must be greater or equal than the global $(D LogLevel).

        Params:
        args = The data that should be logged.

        Returns: The logger used by the logging function as reference.

        Examples:
        --------------------
        Logger g;
        g.tracef("%d %s", 1337, "is number");
        g.infof("%d %s", 1337, "is number");
        g.errorf("%d %s", 1337, "is number");
        g.criticalf("%d %s", 1337, "is number");
        g.fatalf("%d %s", 1337, "is number");
        --------------------
        */
        ref Logger logImplf(int line = __LINE__,
            string file = __FILE__, string funcName = __FUNCTION__,
            string prettyFuncName = __PRETTY_FUNCTION__,
            string moduleName = __MODULE__, A...)(lazy A args)
            @trusted
        {
            static if (args.length > 1 && is(A[0] : bool))
            {
                if (isLoggingEnabled(ll)
                        && ll >= this.logLevel_
                        && ll >= globalLogLevel
                        && globalLogLevel != LogLevel.off
                        && this.logLevel_ != LogLevel.off
                        && args[0])
                {
                    this.logHeader(file, line, funcName, prettyFuncName,
                        moduleName, ll, thisTid, Clock.currTime);

                    auto writer = MsgRange(this);
                    formattedWrite(writer, args[1 .. $]);

                    this.finishLogMsg();

                    static if (ll == LogLevel.fatal)
                        fatalHandler();
                }
            }
            else
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
                    formattedWrite(writer, args);

                    this.finishLogMsg();

                    static if (ll == LogLevel.fatal)
                        fatalHandler();
                }
            }

            return this;
        }
    }

    template MemLogFunctionsDisabled(LogLevel ll)
    {
        ref Logger logImpl(int line = __LINE__,
            string file = __FILE__, string funcName = __FUNCTION__,
            string prettyFuncName = __PRETTY_FUNCTION__,
            string moduleName = __MODULE__, A...)(A) @trusted
        {

            return this;
        }

        ref Logger logImplf(int line = __LINE__,
            string file = __FILE__, string funcName = __FUNCTION__,
            string prettyFuncName = __PRETTY_FUNCTION__,
            string moduleName = __MODULE__, A...)(A) @trusted
        {
            return this;
        }
    }

    version(DisableTrace)
    {
        /// Ditto
        alias trace = MemLogFunctionsDisabled!(LogLevel.trace).logImpl;
        /// Ditto
        alias tracef = MemLogFunctionsDisabled!(LogLevel.trace).logImplf;
    }
    else
    {
        /// Ditto
        alias trace = MemLogFunctions!(LogLevel.trace).logImpl;
        /// Ditto
        alias tracef = MemLogFunctions!(LogLevel.trace).logImplf;
    }

    version(DisableInfo)
    {
        /// Ditto
        alias info = MemLogFunctionsDisabled!(LogLevel.info).logImpl;
        /// Ditto
        alias infof = MemLogFunctionsDisabled!(LogLevel.info).logImplf;
    }
    else
    {
        /// Ditto
        alias info = MemLogFunctions!(LogLevel.info).logImpl;
        /// Ditto
        alias infof = MemLogFunctions!(LogLevel.info).logImplf;
    }

    version(DisableWarning)
    {
        /// Ditto
        alias warning = MemLogFunctionsDisabled!(LogLevel.warning).logImpl;
        /// Ditto
        alias warningf = MemLogFunctionsDisabled!(LogLevel.warning).logImplf;
    }
    else
    {
        /// Ditto
        alias warning = MemLogFunctions!(LogLevel.warning).logImpl;
        /// Ditto
        alias warningf = MemLogFunctions!(LogLevel.warning).logImplf;
    }

    version(DisableError)
    {
        /// Ditto
        alias error = MemLogFunctionsDisabled!(LogLevel.error).logImpl;
        /// Ditto
        alias errorf = MemLogFunctionsDisabled!(LogLevel.error).logImplf;
    }
    else
    {
        /// Ditto
        alias error = MemLogFunctions!(LogLevel.error).logImpl;
        /// Ditto
        alias errorf = MemLogFunctions!(LogLevel.error).logImplf;
    }

    version(DisableCritical)
    {
        /// Ditto
        alias critical = MemLogFunctionsDisabled!(LogLevel.critical).logImpl;
        /// Ditto
        alias criticalf = MemLogFunctionsDisabled!(LogLevel.critical).logImplf;
    }
    else
    {
        /// Ditto
        alias critical = MemLogFunctions!(LogLevel.critical).logImpl;
        /// Ditto
        alias criticalf = MemLogFunctions!(LogLevel.critical).logImplf;
    }

    version(DisableFatal)
    {
        /// Ditto
        alias fatal = MemLogFunctionsDisabled!(LogLevel.fatal).logImpl;
        /// Ditto
        alias fatalf = MemLogFunctionsDisabled!(LogLevel.fatal).logImplf;
    }
    else
    {
        /// Ditto
        alias fatal = MemLogFunctions!(LogLevel.fatal).logImpl;
        /// Ditto
        alias fatalf = MemLogFunctions!(LogLevel.fatal).logImplf;
    }

    /** This method logs data with the $(D LogLevel) of the used $(D Logger).

    This method takes a $(D bool) as first argument. In order for the
    data to be processed the $(D bool) must be $(D true) and the $(D LogLevel)
    of the Logger must be greater or equal to the global $(D LogLevel).

    Params:
    args = The data that should be logged.

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
		version(DisableLogging)
		{
		}
		else
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
		version(DisableLogging)
		{
		}
		else
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
		version(DisableLogging)
		{
		}
		else
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
		version(DisableLogging)
		{
		}
		else
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
    /+
	version(DisableLogging)
    {
        ref Logger log(int line = __LINE__, string file = __FILE__,
            string funcName = __FUNCTION__,
            string prettyFuncName = __PRETTY_FUNCTION__,
            string moduleName = __MODULE__, A...)(A args) @trusted
        {
            return this;
        }
    }
    else
    {
        ref Logger log(int line = __LINE__, string file = __FILE__,
            string funcName = __FUNCTION__,
            string prettyFuncName = __PRETTY_FUNCTION__,
            string moduleName = __MODULE__, A...)(lazy A args) @trusted
        {
            static if (args.length > 1 && is(A[0] == LogLevel)
                && is(A[1] : bool))
            {
                if (isLoggingEnabled(args[0])
                        && args[0] >= this.logLevel_
                        && args[0] >= globalLogLevel
                        && this.logLevel_ != LogLevel.off
                        && globalLogLevel != LogLevel.off
                        && args[1])
                {
                    this.logHeader(file, line, funcName, prettyFuncName,
                        moduleName, args[0], thisTid, Clock.currTime);

                    auto writer = MsgRange(this);
                    formatString(writer, args[2 .. $]);

                    this.finishLogMsg();
                }
            }
            else static if (args.length > 0 && is(A[0] == LogLevel))
            {
                if (isLoggingEnabled(args[0])
                        && args[0] >= this.logLevel_
                        && args[0] >= globalLogLevel
                        && this.logLevel_ != LogLevel.off
                        && globalLogLevel != LogLevel.off)
                {
                    this.logHeader(file, line, funcName, prettyFuncName,
                        moduleName, args[0], thisTid, Clock.currTime);

                    auto writer = MsgRange(this);
                    formatString(writer, args[1 .. $]);

                    this.finishLogMsg();
                }
            }
            else static if (args.length > 0 && is(A[0] : bool))
            {
                if (isLoggingEnabled(this.logLevel_)
                        && this.logLevel_ >= globalLogLevel
                        && this.logLevel_ != LogLevel.off
                        && globalLogLevel != LogLevel.off
                        && args[0])
                {
                    this.logHeader(file, line, funcName, prettyFuncName,
                        moduleName, this.logLevel_, thisTid, Clock.currTime);

                    auto writer = MsgRange(this);
                    formatString(writer, args[1 .. $]);

                    this.finishLogMsg();
                }
            }
            else
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

            return this;
        }
    }
	+/

    /** This method logs data in a $(D printf)-style manner.

    In order for the data to be processed the $(D LogLevel) of the Logger
    must be greater or equal to the global $(D LogLevel).

    Params:
    args = The data that should be logged.

    Returns: The logger used by the logging function as reference.

    Examples:
    --------------------
    auto l = new StdioLogger();
    l.logf("Hello World %f", 3.1415);
    --------------------
    */
    version(DisableLogging)
    {
        ref Logger logf(int line = __LINE__, string file = __FILE__,
            string funcName = __FUNCTION__,
            string prettyFuncName = __PRETTY_FUNCTION__,
            string moduleName = __MODULE__, A...)(A)
            @trusted
        {
            return this;
        }
    }
    else
    {
        ref Logger logf(int line = __LINE__, string file = __FILE__,
            string funcName = __FUNCTION__,
            string prettyFuncName = __PRETTY_FUNCTION__,
            string moduleName = __MODULE__, A...)(lazy A args)
            @trusted
        {
            static if (args.length > 2 && is(A[0] == LogLevel)
                && is(A[1] : bool))
            {
                if (isLoggingEnabled(args[0])
                        && args[0] >= globalLogLevel
                        && args[0] >= this.logLevel_
                        && this.logLevel_ != LogLevel.off
                        && globalLogLevel != LogLevel.off
                        && args[1])
                {
                    this.logHeader(file, line, funcName, prettyFuncName,
                        moduleName, args[0], thisTid, Clock.currTime);

                    auto writer = MsgRange(this);
                    formattedWrite(writer, args[2 .. $]);

                    this.finishLogMsg();
                }
            }
            else static if (args.length > 1 && is(A[0] == LogLevel))
            {
                if (isLoggingEnabled(args[0])
                        && args[0] >= this.logLevel_
                        && args[0] >= globalLogLevel
                        && this.logLevel_ != LogLevel.off
                        && globalLogLevel != LogLevel.off)
                {
                    this.logHeader(file, line, funcName, prettyFuncName,
                        moduleName, args[0], thisTid, Clock.currTime);

                    auto writer = MsgRange(this);
                    formattedWrite(writer, args[1 .. $]);

                    this.finishLogMsg();
                }
            }
            else static if (args.length > 1 && is(A[0] : bool))
            {
                if (isLoggingEnabled(this.logLevel_)
                        && this.logLevel_ >= globalLogLevel
                        && globalLogLevel != LogLevel.off
                        && this.logLevel_ != LogLevel.off
                        && args[0])
                {
                    this.logHeader(file, line, funcName, prettyFuncName,
                        moduleName, this.logLevel_, thisTid, Clock.currTime);

                    auto writer = MsgRange(this);
                    formattedWrite(writer, args[1 .. $]);

                    this.finishLogMsg();
                }
            }
            else
            {
                if (isLoggingEnabled(this.logLevel_)
                        && this.logLevel_ >= globalLogLevel
                        && globalLogLevel != LogLevel.off
                        && this.logLevel_ != LogLevel.off)
                {
                    this.logHeader(file, line, funcName, prettyFuncName,
                        moduleName, this.logLevel_, thisTid, Clock.currTime);

                    auto writer = MsgRange(this);
                    formattedWrite(writer, args);

                    this.finishLogMsg();
                }
            }

            return this;
        }
    }

    final override bool opEquals(Object o) const @safe nothrow
    {
        Logger other = cast(Logger)o;
        if (other is null)
            return false;

        return this.name_ == other.name_;
    }

    final override int opCmp(Object o) const @safe
    {
        Logger other = cast(Logger)o;
        if (other is null)
            throw new Exception("Passed Object not of type Logger");

        return this.name_ < other.name ? -1
            : this.name_ == other.name ? 0
            : 1;
    }

    private LogLevel logLevel_ = LogLevel.info;
    private string name_;
    private void delegate() fatalHandler;
    protected Appender!string msgAppender;
    protected LoggerPayload header;
}

/** This method returns the default $(D Logger).

The Logger is returned as a reference. This means it can be rassigned,
thus changing the $(D defaultLogger).

Example:
-------------
defaultLogger = new StdioLogger;
-------------
The example sets a new $(D StdioLogger) as new $(D defaultLogger).
*/
@property ref Logger defaultLogger() @trusted
{
    static __gshared Logger logger;
    if (logger is null)
    {
        logger = new StderrLogger(globalLogLevel());
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
    if (defaultLogger !is null)
    {
        defaultLogger.logLevel = ll;
    }
    globalLogLevelImpl() = ll;
}

version(unittest)
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

version(unittest)
{
    class TestLogger : Logger
    {
        int line = -1;
        string file = null;
        string func = null;
        string prettyFunc = null;
        string msg = null;
        LogLevel lvl;

        this(string n = "", const LogLevel lv = LogLevel.info) @safe
        {
            super(n, lv);
        }

        override void writeLogMsg(ref LoggerPayload payload) @safe
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
        logger.log("I'm here");
    }
}

unittest
{
    auto tl1 = new TestLogger("one");
    testFuncNames(tl1);
    assert(tl1.func == "std.logger.core.testFuncNames", tl1.func);
    assert(tl1.prettyFunc ==
        "void std.logger.core.testFuncNames(Logger logger)", tl1.prettyFunc);
    assert(tl1.msg == "I'm here", tl1.msg);
}

@safe unittest
{
    auto oldunspecificLogger = defaultLogger;
    LogLevel oldLogLevel = globalLogLevel;
    scope(exit)
    {
        defaultLogger = oldunspecificLogger;
        globalLogLevel = oldLogLevel;
    }

    defaultLogger = new TestLogger("testlogger");

    auto ll = [LogLevel.trace, LogLevel.info, LogLevel.warning,
         LogLevel.error, LogLevel.critical, LogLevel.fatal, LogLevel.off];

}

@safe unittest
{
    auto tl1 = new TestLogger("one");
    auto tl2 = new TestLogger("two");

    auto ml = new MultiLogger();
    ml.insertLogger(tl1);
    ml.insertLogger(tl2);
    assertThrown!Exception(ml.insertLogger(tl1));

    string msg = "Hello Logger World";
    ml.log(msg);
    int lineNumber = __LINE__ - 1;
    assert(tl1.msg == msg);
    assert(tl1.line == lineNumber);
    assert(tl2.msg == msg);
    assert(tl2.line == lineNumber);

    ml.removeLogger(tl1);
    ml.removeLogger(tl2);
    assertThrown!Exception(ml.removeLogger(tl1));
}

@safe unittest
{
    bool errorThrown = false;
    auto tl = new TestLogger("one");
    auto dele = delegate() {
        errorThrown = true;
    };
    tl.setFatalHandler(dele);
    tl.fatal();
    assert(errorThrown);
}

@safe unittest
{
    auto l = new TestLogger("_", LogLevel.info);
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

    auto oldunspecificLogger = defaultLogger;

    assert(oldunspecificLogger.logLevel == LogLevel.all,
         to!string(oldunspecificLogger.logLevel));

    assert(l.logLevel == LogLevel.info);
    defaultLogger = l;
    assert(globalLogLevel == LogLevel.all,
            to!string(globalLogLevel));

    scope(exit)
    {
        defaultLogger = oldunspecificLogger;
    }

    assert(defaultLogger.logLevel == LogLevel.info);
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
    auto oldunspecificLogger = defaultLogger;
    defaultLogger = l;

    scope(exit)
    {
        remove(filename);
        defaultLogger = oldunspecificLogger;
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
    auto oldunspecificLogger = defaultLogger;

    scope(exit)
    {
        remove(filename);
        defaultLogger = oldunspecificLogger;
        globalLogLevel = LogLevel.all;
    }

    string notWritten = "this should not be written to file";
    string written = "this should be written to file";

    auto l = new FileLogger(filename);
    defaultLogger = l;
    defaultLogger.logLevel = LogLevel.fatal;

    log(LogLevel.critical, false, notWritten);
    log(LogLevel.fatal, true, written);
    destroy(l);

    auto file = File(filename, "r");
    auto readLine = file.readln();
    string nextFile = file.readln();
    assert(!nextFile.empty, nextFile);
    assert(nextFile.indexOf(written) != -1);
    assert(nextFile.indexOf(notWritten) == -1);
    file.close();
}

@safe unittest
{
    auto tl = new TestLogger("tl", LogLevel.all);
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
    auto oldunspecificLogger = defaultLogger;

    auto mem = new TestLogger("tl");
    defaultLogger = mem;

    scope(exit)
    {
        defaultLogger = oldunspecificLogger;
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
    auto mem = new TestLogger("tl");
    auto oldunspecificLogger = defaultLogger;

    defaultLogger = mem;
    scope(exit)
    {
        defaultLogger = oldunspecificLogger;
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
    auto oldunspecificLogger = defaultLogger;

    scope(exit)
    {
        defaultLogger = oldunspecificLogger;
        globalLogLevel = LogLevel.all;
    }

    auto tl = new TestLogger("required name", LogLevel.info);
    defaultLogger = tl;

    trace("trace");
    assert(tl.msg.indexOf("trace") == -1);
    //info("info");
    //assert(tl.msg.indexOf("info") == 0);
}

// Issue #5
unittest
{
    auto oldunspecificLogger = defaultLogger;

    scope(exit)
    {
        defaultLogger = oldunspecificLogger;
        globalLogLevel = LogLevel.all;
    }

    auto logger = new MultiLogger(LogLevel.error);

    auto tl = new TestLogger("required name", LogLevel.info);
    logger.insertLogger(tl);
    defaultLogger = logger;

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
	auto dl = cast(StderrLogger)defaultLogger;
	assert(dl !is null);
	assert(dl.logLevel == LogLevel.all);
	assert(globalLogLevel == LogLevel.all);
}
