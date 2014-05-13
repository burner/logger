/**
Implements logging facilities.

Message logging is a common approach to expose runtime information of a
program. Logging should be easy, but also flexible and powerful, therefore $(D D) 
provides a standard interface for logging.

The easiest way to create a log message is to write 
$(D import std.logger; log("I am here");) this will print a message to the 
stdio device.  The message will contain the filename, the linenumber, the name 
of the surrounding function, and the message.

Copyright: Copyright Robert burner Schadek 2013.
License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
Authors:   $(WEB http://www.svs.informatik.uni-oldenburg.de/60865.html, Robert burner Schadek)

-------------
log("Logging to the defaultLogger with its default LogLevel");
logF("%s to the defaultLogger with its default LogLevel", "Logging");
info("Logging to the defaultLogger with its info LogLevel");
warning(5 < 6, "Logging to the defaultLogger with its LogLevel.warning if 5 is less than 6");
error("Logging to the defaultLogger with its error LogLevel");
errorF("Logging %s the defaultLogger %s its error LogLevel", "to", "with");
critical("Logging to the defaultLogger with its error LogLevel");
fatal("Logging to the defaultLogger with its fatal LogLevel");

auto fileLogger = new FileLogger("NameOfTheLogFile");
fileLogger.log("Logging to the fileLogger with its default LogLevel");
fileLogger.info("Logging to the fileLogger with its default LogLevel");
fileLogger.warning(5 < 6, "Logging to the fileLogger with its LogLevel.warning if 5 is less than 6");
fileLogger.warningF(5 < 6, "Logging to the fileLogger with its LogLevel.warning if %s is %s than 6", 5, "less");
fileLogger.critical("Logging to the fileLogger with its info LogLevel");
fileLogger.log(5 < 6, "Logging to the fileLogger with its default LogLevel if 5 is less than 6");
fileLogger.fatal("Logging to the fileLogger with its warning LogLevel");
-------------

The following EBNF describes how to construct log statements:
<table>
 <tr>
  <td>LOGGING</td> <td style="width:30px"> : </td> <td> MEMBER_LOG ;</td> </tr>
 </tr>
 <tr>
  <td/> <td/> | </td> <td> FREE_LOG ;</td>
 </tr>
 <tr>
  <td>MEMBER_LOG</td> <td> : </td> <td> identifier LOG_CALL ;</td>
 </tr>
 <tr>
  <td>FREE_LOG</td> <td> : </td> <td> LOG_CALL ;</td>
 </tr>
 <tr>
  <td> LOG_CALL </td> <td> : </td> <td> LOG_STRING </td>
 </tr>
 <tr>
  <td/> <td> | </td> <td> LOG_FORMAT ;</td>
 </tr>
 <tr>
  <td> LOG_STRING </td> <td> : </td> <td> log(LOG_TYPE_PARAMS) </td>
 </tr>
 <tr>
  <td/> <td> | </td> <td> LOG_LEVEL(LOG_PARAMS) ;</td>
 </tr>
 <tr>
 <tr>
  <td> LOG_FORMAT </td> <td> : </td> <td> logF(LOG_TYPE_PARAMS_A) </td>
 </tr>
 <tr>
  <td/> <td> | </td> <td> LOG_LEVELF(LOG_PARAMS_A) ;</td>
 </tr>
 <tr>
  <td> LOG_LEVEL </td> <td> : </td> <td> trace | info | warning | error |
  critical | fatal ; </td> 
 </tr>
 <tr>
  <td> LOG_LEVELF </td> <td> : </td> <td> traceF | infoF | warningF | errorF |
  criticalF | fatalF ; </td> 
 </tr>
 <tr>
  <td> LOG_TYPE_PARAMS </td> <td> : </td> <td> EPSILON | bool | LOG_LEVEL |
    string | bool, LOG_LEVEL | bool, string | LOG_LEVEL, string | bool, LOG_LEVEL,
    string ; </td>
 <tr>
 <tr>
  <td> LOG_PARAMS </td> <td> : </td> <td> EPSILON | bool | 
    bool, string | string ; </td>
 <tr>
 <tr>
  <td> LOG_TYPE_PARAMS_A </td> <td> : </td> <td> EPSILON | bool | LOG_LEVEL |
    string | string, A... | bool, LOG_LEVEL | bool, string | bool, string,
    A... ; </td>
  <tr>
  <td/> 
    <td> | </td> <td> LOG_LEVEL, string | LOG_LEVEL, string, A... | bool, LOG_LEVEL,
      string | bool, LOG_LEVEL, string, A... ;
    </td>
  <tr>
 <tr>
  <td> LOG_PARAMS_A </td> <td> : </td> <td> EPSILON | bool | 
    bool, string | bool, string, A... | string | string, A... ; </td>
 <tr>
</table>
The occurrences of $(D A...), in the grammar, specify variadic template
arguments.

For conditional logging pass a boolean to the log or logf functions. Only if
the condition pass is true the message will be logged.

Messages are logged if the $(D LogLevel) of the log message is greater equal
than the $(D LogLevel) of the used $(D Logger), and the global $(D LogLevel).
To assign the $(D LogLevel) of a $(D Logger) use the $(D logLevel) property of
the logger. The global $(D LogLevel) is managed by the static $(D LogManager).
It can be changed by assigning the $(D globalLogLevel) property of the $(D
LogManager).

To customize the logger behaviour, create a new $(D class) that inherits from
the abstract $(D Logger) $(D class), and implements the $(D writeLogMsg) method.
-------------
class MyCustomLogger : Logger {
    override void writeLogMsg(LoggerPayload payload))
    {
        // log message in my custom way
    }
}

auto logger = new MyCustomLogger();
logger.log("Awesome log message");
-------------

In order to disable logging at compile time, pass $(D DisableLogger) as a
version argument to the $(D D) compiler.
*/

module std.logger;

import std.array : empty;
import std.stdio;
import std.conv;
import std.datetime;
import std.string;
import std.exception;
import std.concurrency;
import core.sync.mutex : Mutex;

private pure string logLevelToParameterString(const LogLevel lv)
{
    switch(lv)
    {
        case LogLevel.unspecific:
            return "of the used $(D Logger)";
        case LogLevel.trace:
            return "LogLevel.trace";
        case LogLevel.info:
            return "LogLevel.info";
        case LogLevel.warning:
            return "LogLevel.warning";
        case LogLevel.error:
            return "LogLevel.error";
        case LogLevel.critical:
            return "LogLevel.critical";
        case LogLevel.fatal:
            return "LogLevel.fatal";
        default:
            assert(false, to!string(cast(int)lv));
    }
}

private pure string logLevelToFuncNameString(const LogLevel lv)
{
    switch(lv)
    {
        case LogLevel.unspecific:
            return "";
        case LogLevel.trace:
            return "trace";
        case LogLevel.info:
            return "info";
        case LogLevel.warning:
            return "warning";
        case LogLevel.error:
            return "error";
        case LogLevel.critical:
            return "critical";
        case LogLevel.fatal:
            return "fatal";
        default:
            assert(false, to!string(cast(int)lv));
    }
}

private pure string logLevelToDisable(const LogLevel lv)
{
    switch(lv)
    {
        case LogLevel.unspecific:
            return "";
        case LogLevel.trace:
            return "DisableTraceLogging";
        case LogLevel.info:
            return "DisableInfoLogging";
        case LogLevel.warning:
            return "DisableWarningLogging";
        case LogLevel.error:
            return "DisableErrorLogging";
        case LogLevel.critical:
            return "DisableCriticalLogging";
        case LogLevel.fatal:
            return "DisableFatalLogging";
        default:
            assert(false, to!string(cast(int)lv));
    }
}

private string genDocComment(const bool asMemberFunction,
        const bool asConditional, const bool asPrintf,
        const LogLevel lv, const bool specificLogLevel = false)
{
    string ret = "/**\n * This ";
    ret ~= asMemberFunction ? "member " : "";
    ret ~= "function ";
    ret ~= "logs a string message" ~
        (asPrintf ? "in a printf like fashion" : "") ~
        (asConditional ? "depending on a condition" : "") ~
        ", with ";

    if (specificLogLevel)
    {
        ret ~= "a $(D LogLevel) passed explicitly.\n *\n";
    }
    else
    {
        ret ~= "the $(D LogLevel) " ~ logLevelToParameterString(lv) ~ ".\n *\n";
    }

    ret ~= " * This ";
    ret ~= asMemberFunction ? "member " : "";
    ret ~= "function takes ";

    if(specificLogLevel)
    {
        ret ~= "a $(D LogLevel) as first argument.";

        if(asConditional)
        {
            ret ~= " In addition to the $(D bool) value passed the passed "
                ~ "$(D LogLevel) determines if the message is logged. ";
            ret ~= " The second argument is a $(D bool) value. If the value is"
                ~ " $(D true) the message will be logged solely depending on"
                ~ " its $(D LogLevel). If the value is $(D false) the message"
                ~ " will ot be logged.";
        }
    }
    else if(asConditional)
    {
        ret ~= "a $(D bool) as first argument."
            ~ " If the value is $(D true) the message will be logged solely"
            ~ " depending on its $(D LogLevel). If the value is $(D false)"
            ~ " the message will ot be logged.";
    }
    else
    {
        ret ~= "the log message as first argument.";
    }

    if(!specificLogLevel)
    {
        ret ~= " The $(D LogLevel) of the message is $(D " ~
            logLevelToParameterString(lv) ~ ").";
    }

    ret ~= " In order for the message to be processed the "
        ~ "$(D LogLevel) must be greater equal to the $(D LogLevel) of "
        ~ "the used logger, and the global $(D LogLevel).";

    ret ~= asPrintf ? "The log message can contain printf style format"
        ~ " sequences that will be combined with the passed variadic"
        ~ " arguements.": "";

    ret ~= "\n *\n * Params:\n";

    ret ~= specificLogLevel ? " * logLevel = The $(D LogLevel) used for " ~
        "logging the message.\n" : "";

    ret ~= asConditional ? " * cond = The $(D bool) value indicating if the"
        ~ " message should be logged.\n" : "";

    ret ~= " * msg = The message that should be logged.\n";

    ret ~= asPrintf ? " * a = The format arguments that will be used"
        ~ " to printf style formatting.\n" : "";

    ret ~= " *\n * ";
    ret ~= asMemberFunction ? "Returns: The logger used for by the "
        ~ "logging member function." : "Returns: The logger used by the "
        ~ "logging function as reference.";

    ret ~= " \n * \n * Examples:\n * --------------------\n";
    ret ~= asMemberFunction ? " * someLogger." : " * ";

    if (specificLogLevel)
    {
        ret ~= "log";
    }

    ret ~= logLevelToFuncNameString(lv);
    ret ~= asPrintf ? "F(" : "(";
    ret ~= specificLogLevel ? "someLogLevel, " : "";
    ret ~= asConditional ? "someBoolValue, " : "";
    ret ~= asPrintf ? "Hello %s, \"World\"" : "Hello World";

    ret ~= ");\n * --------------------\n";

    return ret ~ " */\n";
}

//pragma(msg, genDocComment(false, true, true, LogLevel.unspecific, true));
//pragma(msg, buildLogFunction(true, false, true, LogLevel.info));
//pragma(msg, buildLogFunction(false, false, false, LogLevel.unspecific));

private string buildLogFunction(const bool asMemberFunction,
        const bool asConditional, const bool asPrintf, const LogLevel lv,
        const bool specificLogLevel = false)
{
    string ret = genDocComment(asMemberFunction, asConditional, asPrintf, lv,
        specificLogLevel);
    ret ~= asMemberFunction ? "Logger " : "public ref Logger ";
    if (lv != LogLevel.unspecific)
    {
        ret ~= logLevelToFuncNameString(lv);
    }
    else
    {
        ret ~= "log";
    }

    ret ~= asPrintf ? "F(" : "(";

    if (asPrintf) 
    {
        ret ~= q{int line = __LINE__, string file = __FILE__, string funcName
            = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__, 
            string moduleName = __MODULE__, A...)(};

        ret ~= specificLogLevel ? "const LogLevel logLevel, " : "";

        if (asConditional) 
        {
            ret ~= "bool cond, ";
        }
        ret ~= "string msg, lazy A a";
    } 
    else 
    {
        ret ~= specificLogLevel ? "const LogLevel logLevel, " : "";

        if (asConditional) 
        {
            ret ~= "bool cond, ";
        }
        ret ~= q{string msg = "", int line = __LINE__, string file =
            __FILE__, string funcName = __FUNCTION__, string prettyFuncName
             = __PRETTY_FUNCTION__, string moduleName = __MODULE__};
    }

    ret ~= ") @trusted {\n";

    if (!specificLogLevel && (lv == LogLevel.trace || lv == LogLevel.info ||
            lv == LogLevel.warning || lv == LogLevel.critical || lv ==
            LogLevel.fatal))
    {
        ret ~= "\tversion(" ~ logLevelToDisable(lv) ~ 
            ")\n\t{\n\t}\n\telse\n\t{\n";
    }

    if (asMemberFunction) 
    {
        if (asConditional && lv == LogLevel.unspecific) 
        {
            ret ~= "\tif(cond) {\n\t";
        } 
        else if (asConditional && lv != LogLevel.unspecific) 
        {
            ret ~= "\tif(cond && " ~ logLevelToParameterString(lv) ~
                " >= this.logLevel && " ~ logLevelToParameterString(lv) ~ " >= " ~
                "LogManager.globalLogLevel) {\n\t";
        } 
        else if (asConditional && specificLogLevel) 
        {
            ret ~= "\tif(cond && logLevel >= this.logLevel && logLevel >= " ~
                "LogManager.globalLogLevel) {\n\t";
        } 
        else if (!asConditional && lv != LogLevel.unspecific) 
        {
            ret ~= "\tif(" ~ logLevelToParameterString(lv) ~
                " >= this.logLevel && " ~ logLevelToParameterString(lv) ~ " >= " ~
                "LogManager.globalLogLevel) {\n\t";
        } 
        else if (!asConditional && specificLogLevel) 
        {
            ret ~= "\tif(logLevel >= this.logLevel && logLevel >= " ~
                "LogManager.globalLogLevel) {\n\t";
        }
        ret ~= "\tthis.logMessage(file, line, funcName, prettyFuncName, " ~
            "moduleName, ";
        if (specificLogLevel) 
        {
            ret ~= "logLevel, ";
        } 
        else 
        {
            ret ~= lv == LogLevel.unspecific ? "this.logLevel_, " :
                logLevelToParameterString(lv) ~ ", ";
        }

        ret ~= asConditional ? "cond, " : "true, ";
        ret ~= asPrintf ? "format(msg, a));\n" : "msg);\n";
        if (asConditional || lv != LogLevel.unspecific || specificLogLevel) 
        {
            if (lv == LogLevel.fatal) 
            {
                ret ~= "\t\tthis.fatalLogger();\n";
            }
            ret ~= "\t}\n";
        }
    } 
    else // !asMemberFunction
    {
        if (asConditional && lv == LogLevel.unspecific) 
        {
            ret ~= "\tif (cond) {\n\t";
        } 
        else if (asConditional && lv != LogLevel.unspecific) 
        {
            ret ~= "\tif (cond && " ~ logLevelToParameterString(lv) ~ " >= " ~
                "LogManager.globalLogLevel) {\n\t";
        } 
        else if (asConditional && specificLogLevel) 
        {
            ret ~= "\tif (cond && logLevel >= LogManager.globalLogLevel) {\n\t";
        } 
        else if (!asConditional && lv != LogLevel.unspecific) 
        {
            ret ~= "\tif (" ~ logLevelToParameterString(lv) ~ " >= " ~
                "LogManager.globalLogLevel) {\n\t";
        } 
        else if (!asConditional && specificLogLevel) 
        {
            ret ~= "\tif (logLevel >= LogManager.globalLogLevel) {\n\t";
        }

        ret ~= "\tLogManager.defaultLogger.log(";

        if (specificLogLevel) 
        {
            ret ~= "logLevel, ";
        } 
        else 
        {
            ret ~= lv == LogLevel.unspecific ? 
                "LogManager.defaultLogger.logLevel, " :
                logLevelToParameterString(lv) ~ ", ";
        }

        ret ~= asConditional ? "cond, " : "true, ";
        ret ~= asPrintf ? "format(msg, a), " : "msg, ";
        ret ~= "line, file, funcName, prettyFuncName, moduleName);\n";

        if (asConditional || lv != LogLevel.unspecific || specificLogLevel) 
        {
            if (lv == LogLevel.fatal) 
            {
                ret ~= "\t\tLogManager.defaultLogger.fatalLogger();\n";
            }
            ret ~= "\t}\n";
        }
    }

    if (!specificLogLevel && (
            lv == LogLevel.trace || lv == LogLevel.info ||
            lv == LogLevel.warning || lv == LogLevel.critical || 
            lv == LogLevel.fatal))
    {
        ret ~= "\t}\n";
    }

    if (asMemberFunction) 
    {
        ret ~= "\treturn this;";
        ret ~= "\n}\n";
    } 
    else 
    {
        ret ~= "\treturn LogManager.defaultLogger;";
        ret ~= "\n}\n";
    }
    return ret;
}

// just sanity checking if parenthesis, and braces are balanced
unittest
{
    import std.algorithm : balancedParens;

    foreach(mem; [true, false]) 
    {
        foreach(con; [true, false]) 
        {
            foreach(pf; [true, false]) 
            {
                foreach(ll; [LogLevel.unspecific, LogLevel.trace, LogLevel.info, 
                        LogLevel.warning, LogLevel.error, LogLevel.critical,
                        LogLevel.fatal])
                {
                    string s = buildLogFunction(mem, con, pf, ll);
                    assert(s.balancedParens('(', ')'));
                    assert(s.balancedParens('{', '}'));
                }
            }
        }
    }
}

/**
Tracer generates $(D trace) calls to the passed logger wenn the $(D Tracer)
struct gets out of scope, this way tracing the control flow gets easier. The
trace message will contain the linenumber where the $(D Tracer) struct was
created.

Example:
-------
{
    auto tracer = Tracer(trace("entering"));
    ...
            // when the scope is left the tracer will log a trace message
            // saying "leaving scope"
}
-------
*/
struct Tracer {
    private Logger logger;
    private int line;
    private string file;
    private string funcName;
    private string prettyFuncName;

    /**
    This static method is used to construct a Tracer as shown in the above
    example.

    Params:
        l = The $(D Logger) that should be used by the $(D Tracer)

    Returns: A new $(D Tracer)
    */
    static Tracer opCall(Logger l, int line = __LINE__, string file = __FILE__,
           string funcName = __FUNCTION__, 
           string prettyFuncName = __PRETTY_FUNCTION__) @trusted
    {
        Tracer ret;
        ret.logger = l;
        ret.line = line;
        ret.file = file;
        ret.funcName = funcName;
        ret.prettyFuncName = prettyFuncName;
        return ret;
    }

    ~this() @trusted
    {
        this.logger.trace("leaving scope", this.line, this.file,
            this.funcName, this.prettyFuncName);
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
    unspecific = 0, /** If no $(D LogLevel) is passed to the log function this
                    level indicates that the current level of the $(D Logger)
                    is to be used for logging the message.  */
    all = 1, /** Lowest possible assignable $(D LogLevel). */
    trace = 32, /** $(D LogLevel) for tracing the execution of the program. */
    info = 64, /** This level is used to display information about the
                program. */
    warning = 96, /** warnings about the program should be displayed with this
                   level. */
    error = 128, /** Information about errors should be logged with this level.*/
    critical = 160, /** Messages that inform about critical errors should be
                    logged with this level. */
    fatal = 192,   /** Log messages that describe fatel errors should use this
                  level. */
    off = ubyte.max /** Highest possible $(D LogLevel). */
}

/** This class is the base of every logger. In order to create a new kind of
logger a derivating class needs to implementation the method $(D writeLogMsg).
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
        /// the pretty formatted name of the function the log function was called from
        string prettyFuncName;
        /// the $(D LogLevel) associated with the log message
        LogLevel logLevel;
        /// the time the message was logged.
        SysTime timestamp;
        /// the name of the module
        string moduleName;
        /// thread id
        Tid threadId;
        /// the message
        string msg;

        // Helper
        static LoggerPayload opCall(string file, int line, string funcName,
                string prettyFuncName, string moduleName, LogLevel logLevel, 
                SysTime timestamp, Tid threadId, string msg) @trusted
        {
            LoggerPayload ret;
            ret.file = file;
            ret.line = line;
            ret.funcName = funcName;
            ret.prettyFuncName = prettyFuncName;
            ret.logLevel = logLevel;
            ret.timestamp = timestamp;
            ret.moduleName = moduleName;
            ret.threadId = threadId;
            ret.msg = msg;
            return ret;
        }
    }

    /** This constructor takes a name of type $(D string), and a $(D LogLevel).

    Every subclass of $(D Logger) has to call this constructor from there
    constructor. It sets the $(D LogLevel), the name of the $(D Logger), and
    creates a fatal handler. The fatal handler will throw, and $(D Error) if a
    log call is made with a $(D LogLevel) $(D LogLevel.fatal).
    */
    public this(string newName, LogLevel lv) @safe
    {
        this.logLevel = lv;
        this.name = newName;
        this.fatalLogger = delegate() {
            throw new Error("A Fatal Log Message was logged");
        };
    }

    /** A custom logger needs to implement this method.
    Params:
        payload = All information associated with call to log function.
    */
    public void writeLogMsg(LoggerPayload payload);

    /** This method is the entry point into each logger. It compares the given
    $(D LogLevel) with the $(D LogLevel) of the $(D Logger), and the global
    $(LogLevel). If the passed $(D LogLevel) is greater or equal to both the
    message, and all other parameter are passed to the abstract method
    $(D writeLogMsg).
    */
    public void logMessage(string file, int line, string funcName,
            string prettyFuncName, string moduleName, LogLevel logLevel, 
            bool cond, string msg)
        @trusted
    {
        version(DisableLogging)
        {
        }
        else
        {
            const bool ll = logLevel >= this.logLevel_;
            const bool gll = logLevel >= LogManager.globalLogLevel;
            if (ll && gll)
            {
                writeLogMsg(LoggerPayload(file, line, funcName, prettyFuncName,
                    moduleName, logLevel, Clock.currTime, thisTid, msg));
            }
        }
    }

    /** Get the $(D LogLevel) of the logger. */
    public @property final LogLevel logLevel() const pure nothrow @safe
    {
        return this.logLevel_;
    }

    /** Set the $(D LogLevel) of the logger. The $(D LogLevel) can not be set
    to $(D LogLevel.unspecific).*/
    public @property final void logLevel(const LogLevel lv) pure nothrow @safe
    {
        assert(lv != LogLevel.unspecific);
        this.logLevel_ = lv;
    }

    /** Get the $(D name) of the logger. */
    public @property final string name() const pure nothrow @safe
    {
        return this.name_;
    }

    /** Set the name of the logger. */
    public @property final void name(string newName) pure nothrow @safe
    {
        this.name_ = newName;
    }

    /** This methods sets the $(D delegate) called in case of a log message
    with $(D LogLevel.fatal).

    By default an $(D Error) will be thrown.
    */
    public final void setFatalHandler(void delegate() dg) @safe {
        this.fatalLogger = dg;
    }

    //                     mem   cond   printf LogLevel
    mixin(buildLogFunction(true, false, false, LogLevel.unspecific));
    mixin(buildLogFunction(true, false, false, LogLevel.trace));
    mixin(buildLogFunction(true, false, false, LogLevel.info));
    mixin(buildLogFunction(true, false, false, LogLevel.warning));
    mixin(buildLogFunction(true, false, false, LogLevel.error));
    mixin(buildLogFunction(true, false, false, LogLevel.critical));
    mixin(buildLogFunction(true, false, false, LogLevel.fatal));
    mixin(buildLogFunction(true, false, true, LogLevel.unspecific));
    mixin(buildLogFunction(true, false, true, LogLevel.trace));
    mixin(buildLogFunction(true, false, true, LogLevel.info));
    mixin(buildLogFunction(true, false, true, LogLevel.warning));
    mixin(buildLogFunction(true, false, true, LogLevel.error));
    mixin(buildLogFunction(true, false, true, LogLevel.critical));
    mixin(buildLogFunction(true, false, true, LogLevel.fatal));
    mixin(buildLogFunction(true, true, false, LogLevel.unspecific));
    mixin(buildLogFunction(true, true, false, LogLevel.trace));
    mixin(buildLogFunction(true, true, false, LogLevel.info));
    mixin(buildLogFunction(true, true, false, LogLevel.warning));
    mixin(buildLogFunction(true, true, false, LogLevel.error));
    mixin(buildLogFunction(true, true, false, LogLevel.critical));
    mixin(buildLogFunction(true, true, false, LogLevel.fatal));
    mixin(buildLogFunction(true, true, true, LogLevel.unspecific));
    mixin(buildLogFunction(true, true, true, LogLevel.trace));
    mixin(buildLogFunction(true, true, true, LogLevel.info));
    mixin(buildLogFunction(true, true, true, LogLevel.warning));
    mixin(buildLogFunction(true, true, true, LogLevel.error));
    mixin(buildLogFunction(true, true, true, LogLevel.critical));
    mixin(buildLogFunction(true, true, true, LogLevel.fatal));
    mixin(buildLogFunction(true, false, false, LogLevel.unspecific, true));
    mixin(buildLogFunction(true, true, false, LogLevel.unspecific, true));
    mixin(buildLogFunction(true, false, true, LogLevel.unspecific, true));
    mixin(buildLogFunction(true, true, true, LogLevel.unspecific, true));

    private LogLevel logLevel_ = LogLevel.info;
    private string name_;
    private void delegate() fatalLogger;
}

/** This $(D Logger) implementation writes log messages to the systems
standard output. The format of the output is:
$(D FileNameWithoutPath:FunctionNameWithoutModulePath:LineNumber Message).
*/
class StdIOLogger : Logger
{
    @trusted static this()
    {
        StdIOLogger.stdioMutex = new Mutex();
    }

    /** Default constructor for the $(D StdIOLogger) Logger.
    
    Params:
      lv = The $(D LogLevel) for the $(D StdIOLogger). By default the $(D LogLevel)
      for $(D StdIOLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto l1 = new StdIOLogger;
    auto l2 = new StdIOLogger(LogLevel.fatal);
    -------------
    */
    public @safe this(const LogLevel lv = LogLevel.info)
    {
        super("", lv);
    }

    /** A constructor for the $(D StdIOLogger) Logger.
    
    Params:
      name = The name of the logger. Compare to $(D MultiLogger.insertLogger).
      lv = The $(D LogLevel) for the $(D StdIOLogger). By default the $(D LogLevel)
      for $(D StdIOLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto l1 = new StdIOLogger("someName");
    auto l2 = new StdIOLogger("someName", LogLevel.fatal);
    -------------
    */
    public @safe this(string name, const LogLevel lv = LogLevel.info)
    {
        super(name, lv);
    }

    /** The messages written to $(D stdio) has the format of:
    $(D FileNameWithoutPath:FunctionNameWithoutModulePath:LineNumber Message).
    */
    public override void writeLogMsg(LoggerPayload payload) @trusted
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

    private static __gshared Mutex stdioMutex;
}

unittest
{
    version(std_logger_stdouttest)
    {
        auto s = new StdIOLogger();
        s.log();
    }
}

/** This $(D Logger) implementation writes log messages to the associated
file. The name of the file has to be passed on construction time. If the file
is already present new log messages will be append at its end.
*/
class FileLogger : Logger
{
    /** Default constructor for the $(D StdIOLogger) Logger.
    
    Params:
      fn = The filename of the output file of the $(D FileLogger).
      lv = The $(D LogLevel) for the $(D FileLogger). By default the $(D LogLevel)
      for $(D FileLogger) is $(D LogLevel.info).

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
      lv = The $(D LogLevel) for the $(D FileLogger). By default the $(D LogLevel)
      for $(D FileLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto l1 = new FileLogger("logFile", "loggerName");
    auto l2 = new FileLogger("logFile", "loggerName", LogLevel.fatal);
    -------------
    */
    public @trusted this(const string fn, string name, const LogLevel lv = LogLevel.info)
    {
        super(name, lv);
        this.filename = fn;
        this.file_.open(this.filename, "a");
        this.fileMutex = new Mutex();
    }

    /** The messages written to file has the format of:
    $(D FileNameWithoutPath:FunctionNameWithoutModulePath:LineNumber Message).
    */
    public override void writeLogMsg(LoggerPayload payload) @trusted
    {
        version(DisableFileLogging)
        {
        }
        else
        {
            size_t fnIdx = payload.file.lastIndexOf('/');
            fnIdx = fnIdx == -1 ? 0 : fnIdx+1;
            size_t funIdx = payload.funcName.lastIndexOf('.');
            funIdx = funIdx == -1 ? 0 : funIdx+1;
            synchronized(fileMutex)
            {
                this.file_.writefln("%s:%s:%s:%u %s",payload.timestamp.toISOExtString(),
                    payload.file[fnIdx .. $], payload.funcName[funIdx .. $],
                    payload.line, payload.msg);
            }
        }
    }

    /** The file written to is accessible by this method.*/
    public @property ref File file() @trusted
    {
        return this.file_;
    }

    private __gshared File file_;
    private __gshared Mutex fileMutex;
    private string filename;
}

/** MultiLogger logs to multiple logger.

It can be used to construct arbitrary, tree like structures. Basically a $(D
MultiLogger) is a map. It maps $(D string)s to $(D Logger). By adding $(D
MultiLogger) into another $(D MultiLogger) non leaf nodes are added. The 
*/

class MultiLogger : Logger
{
    /** Default constructor for the $(D MultiLogger) Logger.
    
    Params:
      lv = The $(D LogLevel) for the $(D MultiLogger). By default the $(D LogLevel)
      for $(D MultiLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto l1 = new MultiLogger;
    auto l2 = new MultiLogger(LogLevel.fatal);
    -------------
    */
    public this(const LogLevel lv = LogLevel.info) @safe
    {
        super("", lv);
    }

    /** A constructor for the $(D MultiLogger) Logger.
    
    Params:
      name = The name of the logger. Compare to $(D FileLogger.insertLogger).
      lv = The $(D LogLevel) for the $(D MultiLogger). By default the $(D LogLevel)
      for $(D MultiLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto l1 = new MultiLogger("loggerName");
    auto l2 = new MultiLogger("loggerName", LogLevel.fatal);
    -------------
    */
    public this(string name, const LogLevel lv = LogLevel.info) @safe
    {
        super(name, lv);
    }

    private Logger[string] logger;

    /** This method inserts a new Logger into the Multilogger.
    */
    public void insertLogger(Logger newLogger) @safe
    {
        if (newLogger.name.empty)
        {
            throw new Exception("A Logger must have a name to be inserted " ~ 
                "into the MulitLogger");
        }
        else if (newLogger.name in logger)
        {
            throw new Exception("This MultiLogger instance already holds a"
                ~ " Logger named '%s'".format(newLogger.name));
        }
        else
        {
            logger[newLogger.name] = newLogger;
        }
    }

    ///
    unittest
    {
        auto l1 = new MultiLogger;
        auto l2 = new StdIOLogger("some_logger");

        l1.insertLogger(l2);

        assert(l1.removeLogger("some_logger") is l2);
    }

    /** This method removes a Logger from the Multilogger.

    See_Also: std.logger.MultiLogger.insertLogger
    */
    public Logger removeLogger(string loggerName) @safe
    {
        if (loggerName !in logger)
        {
            throw new Exception("This MultiLogger instance does not hold a"
                ~ " Logger named '%s'".format(loggerName));
        }
        else
        {
            Logger ret = logger[loggerName];
            logger.remove(loggerName);
            return ret;
        }
    }

    /** This method returns a $(D Logger) if it is present in the $(D
    MultiLogger), otherwise a $(D RangeError) will be thrown.
    */
    public Logger opIndex(string key) @safe
    {
        return logger[key];
    }

    ///
    unittest
    {
        auto ml = new MultiLogger();
        auto sl = new StdIOLogger("some_name");

        ml.insertLogger(sl);

        assert(ml["some_name"] is sl);
    }

    public override void writeLogMsg(LoggerPayload payload) @trusted {
        version(DisableFileLogging)
        {
        }
        else
        {
            foreach (it; logger)
            {
                /* The LogLevel of the Logger must be >= than the LogLevel of
                the payload. Usally this is handled by the log functions. As
                they are not called in this case, we have to handle it by hand
                here.
                */
                const bool ll = payload.logLevel >= it.logLevel_;
                if (ll)
                {
                    it.writeLogMsg(payload);
                }
            }
        }
    }
}

/** The $(D NullLogger) will not process any log messages.

In case of a log message with $(D LogLevel.fatal) nothing will happen.
*/
class NullLogger : Logger {
    /** The default constructor for the $(D NullLogger).

    Independend of the parameter this Logger will never log a message.
    
    Params:
      lv = The $(D LogLevel) for the $(D MultiLogger). By default the $(D LogLevel)
      for $(D MultiLogger) is $(D LogLevel.info).
    */
    public this(const LogLevel lv = LogLevel.info) @safe
    {
        super("", lv);
        this.setFatalHandler = delegate() {};
    }

    /** A constructor for the $(D NullLogger).

    Independend of the parameter this Logger will never log a message.
    
    Params:
      name = The name of the logger. Compare to $(D FileLogger.insertLogger).
      lv = The $(D LogLevel) for the $(D MultiLogger). By default the $(D LogLevel)
      for $(D MultiLogger) is $(D LogLevel.info).
    */
    public this(string name, const LogLevel lv = LogLevel.info) @safe
    {
        super(name, lv);
        this.setFatalHandler = delegate() {};
    }

    public override void writeLogMsg(LoggerPayload payload) @safe {
    }
}

unittest {
    auto nl1 = new NullLogger(LogLevel.all);
    auto nl2 = new NullLogger("NULL", LogLevel.all);
    nl1.info("You should never read this.");
    nl2.fatal("You should never read this, either.");
}

///
unittest
{
    auto ml1 = new MultiLogger();
    auto ml2 = new MultiLogger("TestLogger2");
    auto tl1 = new TestLogger("testlogger");

    ml1.insertLogger(ml2);
    ml2.insertLogger(tl1);
    
    ml1.log("Some Msg");

    assert(tl1.msg == "Some Msg");

}

/** The static $(D LogManager) handles the creation, and the release of
instances of the $(D Logger) class. It also handels the $(I defaultLogger)
which is used if no logger is manually selected. Additionally the
$(D LogManager) also allows to retrieve $(D Logger) by there name.
An $(D StdIOLogger) is assigned to be the default $(D Logger).
*/
static class LogManager {
    private @trusted static this()
    {
        LogManager.defaultLogger_ = new StdIOLogger();
        LogManager.defaultLogger.logLevel = LogLevel.info;
        LogManager.globalLogLevel_ = LogLevel.all;
    }

    // You must not instantiate a LogManager
    @disable private this() {}

    /** This method returns the default $(D Logger). 
   
    The Logger is returned as a reference that means it can be assigend,
    thus changing the defaultLogger.      

    Example:
    -------------
    LogManager.defaultLogger = new StdIOLogger;
    -------------
    The example sets a new $(D StdIOLogger) as new defaultLogger.
    */
    public @property final static ref Logger defaultLogger() @trusted
    {
        return LogManager.defaultLogger_;
    }

    /** This method returns the global $(D LogLevel). */
    public static @property LogLevel globalLogLevel() @trusted
    {
        return LogManager.globalLogLevel_;
    }

    /** This method sets the global $(D LogLevel). 
    
     Every log message with a $(D LogLevel) lower as the global $(D LogLevel)
    will be discarded before it reaches $(D writeLogMessage) method.      
    */
    public static @property void globalLogLevel(LogLevel ll) @trusted
    {
        if(LogManager.defaultLogger !is null) {
            LogManager.defaultLogger.logLevel = ll;
        }
        LogManager.globalLogLevel_ = ll;
    }

    private static __gshared Logger defaultLogger_;
    private static __gshared LogLevel globalLogLevel_;
}

//                     mem    cond   printf LogLevel
mixin(buildLogFunction(false, false, false, LogLevel.unspecific));
mixin(buildLogFunction(false, false, false, LogLevel.trace));
mixin(buildLogFunction(false, false, false, LogLevel.info));
mixin(buildLogFunction(false, false, false, LogLevel.warning));
mixin(buildLogFunction(false, false, false, LogLevel.error));
mixin(buildLogFunction(false, false, false, LogLevel.critical));
mixin(buildLogFunction(false, false, false, LogLevel.fatal));
mixin(buildLogFunction(false, false, true, LogLevel.unspecific));
mixin(buildLogFunction(false, false, true, LogLevel.trace));
mixin(buildLogFunction(false, false, true, LogLevel.info));
mixin(buildLogFunction(false, false, true, LogLevel.warning));
mixin(buildLogFunction(false, false, true, LogLevel.error));
mixin(buildLogFunction(false, false, true, LogLevel.critical));
mixin(buildLogFunction(false, false, true, LogLevel.fatal));
mixin(buildLogFunction(false, true, false, LogLevel.unspecific));
mixin(buildLogFunction(false, true, false, LogLevel.trace));
mixin(buildLogFunction(false, true, false, LogLevel.info));
mixin(buildLogFunction(false, true, false, LogLevel.warning));
mixin(buildLogFunction(false, true, false, LogLevel.error));
mixin(buildLogFunction(false, true, false, LogLevel.critical));
mixin(buildLogFunction(false, true, false, LogLevel.fatal));
mixin(buildLogFunction(false, true, true, LogLevel.unspecific));
mixin(buildLogFunction(false, true, true, LogLevel.trace));
mixin(buildLogFunction(false, true, true, LogLevel.info));
mixin(buildLogFunction(false, true, true, LogLevel.warning));
mixin(buildLogFunction(false, true, true, LogLevel.error));
mixin(buildLogFunction(false, true, true, LogLevel.critical));
mixin(buildLogFunction(false, true, true, LogLevel.fatal));
mixin(buildLogFunction(false, false, false, LogLevel.unspecific, true));
mixin(buildLogFunction(false, true, false, LogLevel.unspecific, true));
mixin(buildLogFunction(false, false, true, LogLevel.unspecific, true));
mixin(buildLogFunction(false, true, true, LogLevel.unspecific, true));

unittest
{
    LogLevel ll = LogManager.globalLogLevel;
    LogManager.globalLogLevel = LogLevel.fatal;
    assert(LogManager.globalLogLevel == LogLevel.fatal);
    LogManager.globalLogLevel = ll;
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

        public this(string n = "", const LogLevel lv = LogLevel.info) @safe
        {
            super(n, lv);
        }

        public override void writeLogMsg(LoggerPayload payload) @safe
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
    assert(tl1.func == "std.logger.testFuncNames", tl1.func);
    assert(tl1.prettyFunc == "void std.logger.testFuncNames(Logger logger)", 
        tl1.prettyFunc);
    assert(tl1.msg == "I'm here", tl1.msg);
}

unittest
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

    ml.removeLogger(tl1.name);
    ml.removeLogger(tl2.name);
    assertThrown!Exception(ml.removeLogger(tl1.name));
}

unittest
{
    auto oldLL = LogManager.globalLogLevel;
    LogManager.globalLogLevel = LogLevel.all;
    scope(exit) LogManager.globalLogLevel = oldLL;
    auto tl = new TestLogger("one", LogLevel.trace);
    tl.trace("hello");
    assert(tl.msg == "hello", tl.msg);
    {
        auto tracer = Tracer(tl.trace("entering"));
        assert(tl.line == __LINE__-1, to!string(tl.line));
    }
    assert(tl.msg != "entering");
    assert(tl.msg == "leaving scope");
    assert(tl.line == __LINE__-5);
}

unittest
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

unittest
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
    l.logF(msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    l.logF(true, msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    l.logF(false, msg, "Yet");
    int nLineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    l.logF(LogLevel.fatal, msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    l.logF(LogLevel.fatal, true, msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    l.logF(LogLevel.fatal, false, msg, "Yet");
    nLineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    auto oldunspecificLogger = LogManager.defaultLogger;

    assert(oldunspecificLogger.logLevel == LogLevel.all,
         to!string(oldunspecificLogger.logLevel));

    assert(l.logLevel == LogLevel.info);
    LogManager.defaultLogger = l;
    assert(LogManager.globalLogLevel == LogLevel.all,
            to!string(LogManager.globalLogLevel));

    scope(exit)
    {
        LogManager.defaultLogger = oldunspecificLogger;
    }

    assert(LogManager.defaultLogger.logLevel == LogLevel.info);
    assert(LogManager.globalLogLevel == LogLevel.all);
    assert(log(false) is l);

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
    logF(msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    logF(true, msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    logF(false, msg, "Yet");
    nLineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    msg = "%s Another message";
    logF(LogLevel.fatal, msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    logF(LogLevel.fatal, true, msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    logF(LogLevel.fatal, false, msg, "Yet");
    nLineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);
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

unittest // file logger test
{
    import std.file;
    import std.stdio;
    Mt19937 gen;
    string name = randomString(32);
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

    l.file.flush();
    l.file.close();

    auto file = File(filename, "r");
    assert(!file.eof);

    string readLine = file.readln();
    assert(readLine.indexOf(written) != -1);
    assert(readLine.indexOf(notWritten) == -1);
    file.close();

    l = new FileLogger(filename);
    l.log(LogLevel.critical, false, notWritten);
    l.log(LogLevel.fatal, true, written);
    l.file.close();

    file = File(filename, "r");
    file.readln();
    readLine = file.readln();
    string nextFile = file.readln();
    assert(nextFile.empty, nextFile);
    assert(readLine.indexOf(written) != -1);
    assert(readLine.indexOf(notWritten) == -1);
}


@trusted unittest // default logger
{
    import std.file;
    Mt19937 gen;
    string name = randomString(32);
    string filename = randomString(32) ~ ".tempLogFile";
    FileLogger l = new FileLogger(filename);
    auto oldunspecificLogger = LogManager.defaultLogger;
    LogManager.defaultLogger = l;

    scope(exit)
    {
        remove(filename);
        LogManager.defaultLogger = oldunspecificLogger;
    }

    string notWritten = "this should not be written to file";
    string written = "this should be written to file";

    l.logLevel = LogLevel.critical;
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

    l = new FileLogger(filename);
    LogManager.defaultLogger = l;
    log.logLevel = LogLevel.fatal;
    log(LogLevel.critical, false, notWritten);
    log(LogLevel.fatal, true, written);
    l.file.close();

    file = File(filename, "r");
    file.readln();
    readLine = file.readln();
    string nextFile = file.readln();
    assert(!nextFile.empty, nextFile);
    assert(nextFile.indexOf(written) != -1);
    assert(nextFile.indexOf(notWritten) == -1);
}

@trusted unittest
{
    auto tl = new TestLogger("tl", LogLevel.all);
    int l = __LINE__;
    tl.info("a");
    assert(tl.line == l+1);
    assert(tl.msg == "a");
    assert(tl.logLevel == LogLevel.all);
    assert(LogManager.globalLogLevel == LogLevel.all);
    l = __LINE__;
    tl.trace("b");
    assert(tl.msg == "b", tl.msg);
    assert(tl.line == l+1, to!string(tl.line));
}
