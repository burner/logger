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
loglcf(LogLevel.info, 5 < 6, "%s to the defaultLogger with its LogLevel.info", "Logging");
info("Logging to the defaultLogger with its info LogLevel");
warningc(5 < 6, "Logging to the defaultLogger with its LogLevel.warning if 5 is less than 6");
error("Logging to the defaultLogger with its error LogLevel");
errorf("Logging %s the defaultLogger %s its error LogLevel", "to", "with");
critical("Logging to the"," defaultLogger with its error LogLevel");
fatal("Logging to the defaultLogger with its fatal LogLevel");

auto fLogger = new FileLogger("NameOfTheLogFile");
fLogger.log("Logging to the fileLogger with its default LogLevel");
fLogger.info("Logging to the fileLogger with its default LogLevel");
fLogger.warningc(5 < 6, "Logging to the fileLogger with its LogLevel.warning if 5 is less than 6");
fLogger.warningcf(5 < 6, "Logging to the fileLogger with its LogLevel.warning if %s is %s than 6", 5, "less");
fLogger.critical("Logging to the fileLogger with its info LogLevel");
fLogger.loglc(LogLevel.trace, 5 < 6, "Logging to the fileLogger"," with its default LogLevel if 5 is less than 6");
fLogger.fatal("Logging to the fileLogger with its warning LogLevel");
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
    <td> LOG_CALL </td> <td> : </td> <td> LOG_NORMAL </td>
  </tr>
  <tr>
    <td/> <td> | </td> <td> LOG_FORMAT ;</td>
  </tr>

  <tr>
    <td> LOG_NORMAL </td> <td> : </td> <td> NOLOGLEVEL </td>
  </tr>
  <tr>
    <td/> <td> | </td> <td> DIRECT</td>
  </tr>
  <tr>
    <td/> <td> | </td> <td> LOGLEVEL</td>
  </tr>
  <tr>
    <td/> <td> | </td> <td> DIRECTLOGLEVEL</td>
  </tr>
  <tr>
    <td/> <td> | </td> <td> CONDI</td>
  </tr>
  <tr>
    <td/> <td> | </td> <td> LLCONDI</td>
  </tr>
  <tr>
    <td/> <td> | </td> <td> DIRECTCONDI ;</td>
  </tr>

  <tr>
    <td> LOG_FORMAT </td> <td> : </td> <td> NOLOGLEVELF </td>
  </tr>
  <tr>
    <td/> <td> | </td> <td> DIRECTF</td>
  </tr>
  <tr>
    <td/> <td> | </td> <td> LOGLEVELF</td>
  </tr>
  <tr>
    <td/> <td> | </td> <td> DIRECTLOGLEVELF</td>
  </tr>
  <tr>
    <td/> <td> | </td> <td> CONDIF</td>
  </tr>
  <tr>
    <td/> <td> | </td> <td> LLCONDIF</td>
  </tr>
  <tr>
    <td/> <td> | </td> <td> DIRECTCONDIF ;</td>
  </tr>

  <tr>
    <td> NOLOGLEVEL </td> <td> | </td> <td> log ( A... ) ; </td>
  </tr>
  <tr>
    <td> DIRECT </td> <td> | </td> <td> LL ( A... ) ; </td>
  </tr>
  <tr>
    <td> LOGLEVEL </td> <td> | </td> <td> logl (LogLevel, A... ) ; </td>
  </tr>
  <tr>
    <td> DIRECTLOGLEVEL </td> <td> | </td> <td> LLl (A... ) ; </td>
  </tr>
  <tr>
    <td> CONDI </td> <td> | </td> <td> logc (true|false, A... ) ; </td>
  </tr>
  <tr>
    <td> LLCONDI </td> <td> | </td> <td> loglc (LogLevel, true|false, A...) ; </td>
  </tr>
  <tr>
    <td> DIRECTCONDI </td> <td> | </td> <td> LLc (true|false, A... ) ; </td>
  </tr>

  <tr>
    <td> NOLOGLEVELF </td> <td> | </td> <td> logf ( string , A... ) ; </td>
  </tr>
  <tr>
    <td> DIRECTF </td> <td> | </td> <td> LLf ( string , A... ) ; </td>
  </tr>
  <tr>
    <td> LOGLEVELF </td> <td> | </td> <td> logl (LogLevel, string , A... ) ; </td>
  </tr>
  <tr>
    <td> DIRECTLOGLEVELF </td> <td> | </td> <td> LLl (string , A... ) ; </td>
  </tr>
  <tr>
    <td> CONDIF </td> <td> | </td> <td> logc (true|false, string , A... ) ; </td>
  </tr>
  <tr>
    <td> LLCONDIF </td> <td> | </td> <td> loglc (LogLevel, true|false, string , A... ) ; </td>
  </tr>
  <tr>
    <td> DIRECTCONDIF </td> <td> | </td> <td> LLc (true|false, string , A... ) ; </td>
  </tr>

  <tr>
    <td> LL </td> <td> | </td> <td> info | warning | error | critical | fatal ; </td>
  </tr>
</table>
The occurrences of $(D A...), in the grammar, specify variadic template
arguments.

For conditional logging pass a boolean to the logc or logcf functions. Only if
the condition pass is true the message will be logged.

Messages are logged if the $(D LogLevel) of the log message is greater equal
than the $(D LogLevel) of the used $(D Logger) and additionally if the $(D
LogLevel of the log message is greater equal to the global $(D LogLevel).
The global $(D LogLevel) is accessible by using $(D
LogManager.globalLogLevel). To assign the $(D LogLevel) of a $(D Logger) use 
the $(D logLevel) property of the logger.

To customize the logger behaviour, create a new $(D class) that inherits from
the abstract $(D Logger) $(D class), and implements the $(D writeLogMsg)
method.
-------------
class MyCustomLogger : Logger {
    override void writeLogMsg(ref LoggerPayload payload))
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
//import core.sync.mutex : Mutex;

import std.logger.stdiologger;
import std.logger.multilogger;
import std.logger.filelogger;
import std.logger.nulllogger;

/+
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
        ret ~= "the $(D LogLevel) " ~ logLevelToParameterString(lv) ~
            ".\n *\n";
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
    ret ~= asPrintf ? "f(" : "(";
    ret ~= specificLogLevel ? "someLogLevel, " : "";
    ret ~= asConditional ? "someBoolValue, " : "";
    ret ~= asPrintf ? "Hello %s, \"World\"" : "Hello World";

    ret ~= ");\n * --------------------\n";

    return ret ~ " */\n";
}
+/

//pragma(msg, genDocComment(false, false, false, LogLevel.unspecific, true));
//pragma(msg, buildLogFunction(false, false, false, LogLevel.unspecific));
//pragma(msg, buildLogFunction(false, false, false, LogLevel.unspecific));
//pragma(msg, buildLogFunction(false, false, false, LogLevel.trace));
//pragma(msg, buildLogFunction(false, false, true, LogLevel.info));

/** This function logs data.

In order for the data to be processed the $(D LogLevel) of the defaultLogger 
must be greater equal to the global $(D LogLevel).

Params:
args = The data that should be logged.

Returns: The logger used by the logging function as reference. 

Examples:
--------------------
log("Hello World", 3.1415);
--------------------
*/
public ref Logger log(int line = __LINE__, string file = __FILE__, 
	string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	string moduleName = __MODULE__, A...)(lazy A args) @trusted 
{
	if (LogManager.defaultLogger.logLevel >= LogManager.globalLogLevel
			&& LogManager.globalLogLevel != LogLevel.off 
			&& LogManager.defaultLogger.logLevel != LogLevel.off) 
	{
		LogManager.defaultLogger.log!(line, file, funcName,prettyFuncName, 
			moduleName)(args);
	}

	return LogManager.defaultLogger;
}

/** This function logs data depending on a $(D LogLevel) passed
explicitly.

This function takes a $(D LogLevel) as first argument. In order for the
data to be processed the $(D LogLevel) must be greater equal to the
$(D LogLevel) of the used logger, and the global $(D LogLevel).

Params:
logLevel = The $(D LogLevel) used for logging the message.
args = The data that should be logged.

Returns: The logger used by the logging function as reference. 

Examples:
--------------------
logl(LogLevel.error, "Hello World");
--------------------
*/
public ref Logger logl(int line = __LINE__, string file = __FILE__, 
	string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	string moduleName = __MODULE__, A...)(const LogLevel logLevel, lazy A args)
	@trusted 
{
	if (logLevel >= LogManager.globalLogLevel 
			&& logLevel >= LogManager.defaultLogger.logLevel
			&& LogManager.globalLogLevel != LogLevel.off 
			&& LogManager.defaultLogger.logLevel != LogLevel.off ) 
	{
		LogManager.defaultLogger.logl!(line, file, funcName,prettyFuncName, 
			moduleName)(logLevel, args);
	}

	return LogManager.defaultLogger;
}

/** This function logs data depending on a $(D condition) passed
explicitly.

This function takes a $(D bool) as first argument. In order for the
data to be processed the $(D bool) must be $(D true) and the $(D LogLevel) of
the defaultLogger must be greater equal to the global $(D LogLevel).

Params:
cond = Only if this $(D bool) is $(D true) will the data be logged.
args = The data that should be logged.

Returns: The logger used by the logging function as reference. 

Examples:
--------------------
logc(false, 1337);
--------------------
*/
public ref Logger logc(int line = __LINE__, string file = __FILE__, 
	string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	string moduleName = __MODULE__, A...)(const bool cond, lazy A args) @trusted 
{
	if (cond && LogManager.defaultLogger.logLevel >= LogManager.globalLogLevel
			&& LogManager.globalLogLevel != LogLevel.off 
			&& LogManager.defaultLogger.logLevel != LogLevel.off ) 
	{
		LogManager.defaultLogger.logc!(line, file, funcName,prettyFuncName, 
			moduleName)(cond, args);
	}

	return LogManager.defaultLogger;
}

/** This function logs data depending on a $(D condition) and a $(D LogLevel) 
passed explicitly.

This function takes a $(D bool) as first argument and a $(D bool) as second 
argument. In order for the
data to be processed the $(D bool) must be $(D true) and the $(D LogLevel) of
the defaultLogger must be greater equal to the global $(D LogLevel).

Params:
logLevel = The $(D LogLevel) used for logging the message.
cond = Only if this $(D bool) is $(D true) will the data be logged.
args = The data that should be logged.

Returns: The logger used by the logging function as reference. 

Examples:
--------------------
loglc(LogLevel.info, someCondition, 13, 37, "Hello World");
--------------------
*/
public ref Logger loglc(int line = __LINE__, string file = __FILE__, 
	string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	string moduleName = __MODULE__, A...)(const LogLevel logLevel, const bool cond, 
	lazy A args) @trusted 
{
	if (cond && logLevel >= LogManager.globalLogLevel
			&& logLevel >= LogManager.defaultLogger.logLevel
			&& LogManager.globalLogLevel != LogLevel.off 
			&& LogManager.defaultLogger.logLevel != LogLevel.off ) 
	{
		LogManager.defaultLogger.loglc!(line, file, funcName,prettyFuncName, 
			moduleName)(logLevel, cond, args);
	}

	return LogManager.defaultLogger;
}

/** This function logs data in a printf style manner.

In order for the data to be processed the $(D LogLevel) of the defaultLogger 
must be greater equal to the global $(D LogLevel).

Params:
msg = The $(D string) that is used to format the additional data.
args = The data that should be logged.

Returns: The logger used by the logging function as reference. 

Examples:
--------------------
logf("Hello World %f", 3.1415);
--------------------
*/
public ref Logger logf(int line = __LINE__, string file = __FILE__, 
	string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	string moduleName = __MODULE__, A...)(string msg, 
	lazy A args) @trusted 
{
	if (LogManager.defaultLogger.logLevel >= LogManager.globalLogLevel
			&& LogManager.globalLogLevel != LogLevel.off 
			&& LogManager.defaultLogger.logLevel != LogLevel.off ) 
	{
		LogManager.defaultLogger.logf!(line, file, funcName,prettyFuncName, 
			moduleName)(msg, args);
	}

	return LogManager.defaultLogger;
}

/** This function logs data in a printf style manner depending on a 
$(D condition) and a $(D LogLevel) passed explicitly.

This function takes a $(D LogLevel) as first argument. In order for the
data to be processed the $(D LogLevel) must be greater equal to the
$(D LogLevel) of the used Logger and the global $(D LogLevel).

Params:
logLevel = The $(D LogLevel) used for logging the message.
msg = The $(D string) that is used to format the additional data.
args = The data that should be logged.

Returns: The logger used by the logging function as reference. 

Examples:
--------------------
loglf(LogLevel.critical, "%d", 1337);
--------------------
*/
public ref Logger loglf(int line = __LINE__, string file = __FILE__, 
	string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	string moduleName = __MODULE__, A...)(const LogLevel logLevel, string msg, 
	lazy A args) @trusted 
{
	if (logLevel >= LogManager.globalLogLevel 
			&& logLevel >= LogManager.defaultLogger.logLevel
			&& LogManager.globalLogLevel != LogLevel.off 
			&& LogManager.defaultLogger.logLevel != LogLevel.off ) 
	{
		LogManager.defaultLogger.loglf!(line, file, funcName,prettyFuncName, 
			moduleName)(logLevel, msg, args);
	}

	return LogManager.defaultLogger;
}

/** This function logs data in a printf style manner depending on a 
$(D condition) passed explicitly

This function takes a $(D bool) as first argument. In order for the
data to be processed the $(D bool) must be $(D true) and the $(D LogLevel) of
the defaultLogger must be greater equal to the global $(D LogLevel).

Params:
cond = Only if this $(D bool) is $(D true) will the data be logged.
msg = The $(D string) that is used to format the additional data.
args = The data that should be logged.

Returns: The logger used by the logging function as reference. 

Examples:
--------------------
logcf(false, "%d", 1337);
--------------------
*/
public ref Logger logcf(int line = __LINE__, string file = __FILE__, 
	string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	string moduleName = __MODULE__, A...)(const bool cond, string msg, lazy A args) 
	@trusted 
{
	if (cond && LogManager.defaultLogger.logLevel >= LogManager.globalLogLevel
			&& LogManager.globalLogLevel != LogLevel.off 
			&& LogManager.defaultLogger.logLevel != LogLevel.off ) 
	{
		LogManager.defaultLogger.logcf!(line, file, funcName,prettyFuncName, 
			moduleName)(cond, msg, args);
	}

	return LogManager.defaultLogger;
}

/** This function logs data in a printf style manner depending on a $(D
LogLevel) and a $(D condition) passed explicitly

This function takes a $(D LogLevel) as first argument This function takes a
$(D bool) as second argument. In order for the data to be processed the 
$(D bool) must be $(D true) and the $(D LogLevel) of the defaultLogger must be
greater equal to the global $(D LogLevel).

Params:
logLevel = The $(D LogLevel) used for logging the message.
cond = Only if this $(D bool) is $(D true) will the data be logged.
msg = The $(D string) that is used to format the additional data.
args = The data that should be logged.

Returns: The logger used by the logging function as reference. 

Examples:
--------------------
loglcf(LogLevel.trace, false, "%d %s", 1337, "is number");
--------------------
*/
public ref Logger loglcf(int line = __LINE__, string file = __FILE__, 
	string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	string moduleName = __MODULE__, A...)(const LogLevel logLevel, bool cond, 
	string msg, lazy A args) @trusted 
{
	if (cond && logLevel >= LogManager.globalLogLevel 
			&& logLevel >= LogManager.defaultLogger.logLevel
			&&LogManager.globalLogLevel != LogLevel.off 
			&& LogManager.defaultLogger.logLevel != LogLevel.off ) 
	{
		LogManager.defaultLogger.loglcf!(line, file, funcName,prettyFuncName, 
			moduleName)(logLevel, cond, msg, args);
	}

	return LogManager.defaultLogger;
}

/** This function logs data with $(D LogLevel) $(D trace).

In order for the data to be processed the $(D LogLevel) of the defaultLogger
must be smaller equal to $(D LogLevel.trace) and the global $(D LogLevel) must
also be smaller equal to $(D LogLevel.trace).

Params:
args = The data that should be logged.

Returns: The logger used by the logging function as reference. 

Examples:
--------------------
trace(1337, "is number");
--------------------

Additionally, to $(D tracecf) there are the function.
$(LI $(D info))
$(LI $(D warning))
$(LI $(D error))
$(LI $(D critical))
$(LI $(D fatal))

These function behave exactly like $(D tracecf) with the exception of a
different $(D LogLevel) used for logging the data.
*/
public ref Logger trace(int line = __LINE__, string file = __FILE__, 
	string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	string moduleName = __MODULE__, A...)(lazy A args) @trusted 
{
	if (LogLevel.trace >= LogManager.globalLogLevel
			&& LogLevel.trace >= LogManager.defaultLogger.logLevel
			&& LogManager.globalLogLevel != LogLevel.off 
			&& LogManager.defaultLogger.logLevel != LogLevel.off) 
	{
		LogManager.defaultLogger.trace!(line, file, funcName,prettyFuncName, 
			moduleName)(args);
	}

	return LogManager.defaultLogger;
}

/** This function logs data in a printf style manner with $(D LogLevel) 
$(D trace), a $(D condition) is passed explicitly.

This function takes a $(D bool) as first argument. In order for the data to be processed the 
$(D bool) must be $(D true), the $(D LogLevel) of the defaultLogger must be
smaller equal to $(D LogLevel.trace) and the global $(D LogLevel) must also be
smaller equal to $(D LogLevel.trace).

Params:
cond = Only if this $(D bool) is $(D true) will the data be logged.
msg = The $(D string) that is used to format the additional data.
args = The data that should be logged.

Returns: The logger used by the logging function as reference. 

Examples:
--------------------
tracecf(false, "%d %s", 1337, "is number");
--------------------

Additionally, to $(D tracecf) there are the function.
$(LI $(D infocf))
$(LI $(D warningcf))
$(LI $(D errorcf))
$(LI $(D criticalcf))
$(LI $(D fatalcf))

These function behave exactly like $(D tracecf) with the exception of a
different $(D LogLevel) used for logging the data.
*/
public ref Logger tracec(int line = __LINE__, string file = __FILE__, 
	string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	string moduleName = __MODULE__, A...)(const bool cond, lazy A args) @trusted 
{
	if (cond && LogLevel.trace >= LogManager.globalLogLevel
			&& LogLevel.trace >= LogManager.defaultLogger.logLevel
			&& LogManager.globalLogLevel != LogLevel.off 
			&& LogManager.defaultLogger.logLevel != LogLevel.off ) 
	{
		LogManager.defaultLogger.tracec!(line, file, funcName,prettyFuncName, 
			moduleName)(cond, args);
	}

	return LogManager.defaultLogger;
}

/** This function logs data in a printf style manner with $(D LogLevel) 
$(D trace).

In order for the data to be processed the $(D bool) must be $(D true), the $(D
LogLevel) of the defaultLogger must be smaller equal to $(D LogLevel.trace)
and the global $(D LogLevel) must also be smaller equal to $(D
LogLevel.trace).

Params:
msg = The $(D string) that is used to format the additional data.
args = The data that should be logged.

Returns: The logger used by the logging function as reference. 

Examples:
--------------------
tracef("%d %s", 1337, "is number");
--------------------

Additionally, to $(D tracecf) there are the function.
$(LI $(D infof))
$(LI $(D warningf))
$(LI $(D errorf))
$(LI $(D criticalf))
$(LI $(D fatalf))

These function behave exactly like $(D tracef) with the exception of a
different $(D LogLevel) used for logging the data.
*/
public ref Logger tracef(int line = __LINE__, string file = __FILE__, 
	string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	string moduleName = __MODULE__, A...)(const bool cond, string msg, lazy A args) 
	@trusted 
{
	if (cond && LogLevel.trace >= LogManager.globalLogLevel
			&& LogLevel.trace >= LogManager.defaultLogger.logLevel
			&& LogManager.globalLogLevel != LogLevel.off 
			&& LogManager.defaultLogger.logLevel != LogLevel.off ) 
	{
		LogManager.defaultLogger.tracecf!(line, file, funcName,prettyFuncName, 
			moduleName)(cond, msg, args);
	}

	return LogManager.defaultLogger;
}

/** This function logs data in a printf style manner with $(D LogLevel) 
$(D trace), a $(D condition) is passed explicitly

This function takes a $(D bool) as first argument. In order for the data to be processed the 
$(D bool) must be $(D true), the $(D LogLevel) of the defaultLogger must be
smaller equal to $(D LogLevel.trace) and the global $(D LogLevel) must also be
smaller equal to $(D LogLevel.trace).

Params:
cond = Only if this $(D bool) is $(D true) will the data be logged.
msg = The $(D string) that is used to format the additional data.
args = The data that should be logged.

Returns: The logger used by the logging function as reference. 

Examples:
--------------------
tracecf(false, "%d %s", 1337, "is number");
--------------------

Additionally, to $(D tracecf) there are the function.
$(LI $(D infocf))
$(LI $(D warningcf))
$(LI $(D errorcf))
$(LI $(D criticalcf))
$(LI $(D fatalcf))

These function behave exactly like $(D tracecf) with the exception of a
different $(D LogLevel) used for logging the data.
*/
public ref Logger tracecf(int line = __LINE__, string file = __FILE__, 
	string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	string moduleName = __MODULE__, A...)(const bool cond, string msg, lazy A args) 
	@trusted 
{
	if (cond && LogManager.defaultLogger.logLevel >= LogManager.globalLogLevel
			&& LogLevel.trace >= LogManager.defaultLogger.logLevel
			&& LogManager.globalLogLevel != LogLevel.off 
			&& LogManager.defaultLogger.logLevel != LogLevel.off ) 
	{
		LogManager.defaultLogger.tracecf!(line, file, funcName,prettyFuncName, 
			moduleName)(cond, msg, args);
	}

	return LogManager.defaultLogger;
}

enum freeLog = q{

public ref Logger %s(int line = __LINE__, string file = __FILE__, 
	string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	string moduleName = __MODULE__, A...)(lazy A args) @trusted 
{
	if (LogLevel.%s >= LogManager.globalLogLevel
			&& LogLevel.%s >= LogManager.defaultLogger.logLevel
			&& LogManager.globalLogLevel != LogLevel.off 
			&& LogManager.defaultLogger.logLevel != LogLevel.off) 
	{
		LogManager.defaultLogger.%s!(line, file, funcName,prettyFuncName, 
			moduleName)(args);
	}

	return LogManager.defaultLogger;
}

public ref Logger %sc(int line = __LINE__, string file = __FILE__, 
	string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	string moduleName = __MODULE__, A...)(const bool cond, lazy A args) @trusted 
{
	if (cond && LogLevel.%s >= LogManager.globalLogLevel
			&& LogLevel.%s >= LogManager.defaultLogger.logLevel
			&& LogManager.globalLogLevel != LogLevel.off 
			&& LogManager.defaultLogger.logLevel != LogLevel.off ) 
	{
		LogManager.defaultLogger.%sc!(line, file, funcName,prettyFuncName, 
			moduleName)(cond, args);
	}

	return LogManager.defaultLogger;
}

public ref Logger %sf(int line = __LINE__, string file = __FILE__, 
	string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	string moduleName = __MODULE__, A...)(string msg, lazy A args) 
	@trusted 
{
	if (cond && LogLevel.%s >= LogManager.globalLogLevel
			&& LogLevel.%s >= LogManager.defaultLogger.logLevel
			&& LogManager.globalLogLevel != LogLevel.off 
			&& LogManager.defaultLogger.logLevel != LogLevel.off ) 
	{
		LogManager.defaultLogger.%sf!(line, file, funcName,prettyFuncName, 
			moduleName)(msg, args);
	}

	return LogManager.defaultLogger;
}

public ref Logger %scf(int line = __LINE__, string file = __FILE__, 
	string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	string moduleName = __MODULE__, A...)(const bool cond, string msg, lazy A args) 
	@trusted 
{
	if (cond && LogLevel.%s >= LogManager.globalLogLevel
			&& LogLevel.%s >= LogManager.defaultLogger.logLevel
			&& LogManager.globalLogLevel != LogLevel.off 
			&& LogManager.defaultLogger.logLevel != LogLevel.off ) 
	{
		LogManager.defaultLogger.%scf!(line, file, funcName,prettyFuncName, 
			moduleName)(cond, msg, args);
	}

	return LogManager.defaultLogger;
}
};

/*


*/
	
mixin(freeLog.format(
	"info", "info", "info", "info",
	"info", "info", "info", "info",
	"info", "info", "info", "info",
	"info", "info", "info", "info"));
mixin(freeLog.format(
	"warning", "warning", "warning", "warning",
	"warning", "warning", "warning", "warning",
	"warning", "warning", "warning", "warning",
	"warning", "warning", "warning", "warning"));
mixin(freeLog.format(
	"error", "error", "error", "error",
	"error", "error", "error", "error",
	"error", "error", "error", "error",
	"error", "error", "error", "error"));
mixin(freeLog.format(
	"critical", "critical", "critical", "critical",
	"critical", "critical", "critical", "critical",
	"critical", "critical", "critical", "critical",
	"critical", "critical", "critical", "critical"));
mixin(freeLog.format(
	"fatal", "fatal", "fatal", "fatal",
	"fatal", "fatal", "fatal", "fatal",
	"fatal", "fatal", "fatal", "fatal",
	"fatal", "fatal", "fatal", "fatal"));

/+
private immutable formatString = q{
        import std.format : formattedWrite;

        auto app = appender!string();
        foreach (arg; args)
        {
            alias A = typeof(arg);
            static if (isAggregateType!A || is(A == enum))
            {
                std.format.formattedWrite(app, "%s", arg);
            }
            else static if (isSomeString!A)
            {
                std.format.formattedWrite(app, "%s", arg);
            }
            else static if (isIntegral!A)
            {
                toTextRange(arg, app);
            }
            else static if (isBoolean!A)
            {
                std.format.formattedWrite(app, "%s", arg ? "true" : "false");
            }
            else static if (isSomeChar!A)
            {
                std.format.formattedWrite(app, "%c", arg);
            }
            else
            {
                // Most general case
                std.format.formattedWrite(w, "%s", arg);
            }
        }
};
+/

/+
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

    ret ~= specificLogLevel ? "l" : "";

    ret ~= asConditional ? "c" : "";

    ret ~= asPrintf ? "f(" : "(";

    ret ~= q{int line = __LINE__, string file = __FILE__, string funcName
       = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
       string moduleName = __MODULE__, A...)(};

    if (asPrintf)
    {
        ret ~= specificLogLevel ? "const LogLevel logLevel, " : "";

        if (asConditional)
        {
            ret ~= "bool cond, ";
        }
        ret ~= "string msg, lazy A args";
    }
    else
    {
        ret ~= specificLogLevel ? "const LogLevel logLevel, " : "";

        if (asConditional)
        {
            ret ~= "bool cond, ";
        }
        ret ~= "lazy A args";
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
        bool firstBool;

        if (asConditional)
        {
            ret ~= "\tif (cond";
            firstBool = true;
        }

        if (specificLogLevel)
        {
            ret ~= (firstBool ? " && " : "\tif (") ~
                "logLevel >= this.logLevel && " ~
                "logLevel >= LogManager.globalLogLevel && " ~
                "this.logLevel != LogLevel.off && " ~
                "LogManager.globalLogLevel != LogLevel.off";


            firstBool = true;
        }

        if (lv != LogLevel.unspecific)
        {
            ret ~= (firstBool ? " && " : "\tif (") ~
                logLevelToParameterString(lv) ~ " >= this.logLevel && " ~
                logLevelToParameterString(lv) ~
                " >= LogManager.globalLogLevel && LogManager.globalLogLevel " ~
                "!= LogLevel.off";

            firstBool = true;
        }

        ret ~= firstBool ? ") {\n" : "";

        if (!asPrintf)
        {
            ret ~= formatString;
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
        ret ~= asPrintf ? "format(msg, args));\n" : "app.data());\n";
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
        bool firstBool;

        if (asConditional)
        {
            ret ~= "\tif (cond";
            firstBool = true;
        }

        if (specificLogLevel)
        {
            ret ~= (firstBool ? " && " : "\tif (") ~
                "logLevel >= LogManager.globalLogLevel && " ~
                "logLevel >= LogManager.defaultLogger.logLevel &&" ~
                "LogManager.globalLogLevel != LogLevel.off && " ~
                "LogManager.defaultLogger.logLevel != LogLevel.off ";


            firstBool = true;
        }

        if (lv != LogLevel.unspecific)
        {
            ret ~= (firstBool ? " && " : "\tif (") ~
                logLevelToParameterString(lv) ~
                " >= LogManager.globalLogLevel && " ~
                logLevelToParameterString(lv) ~
                " >= LogManager.defaultLogger.logLevel && " ~
                "LogManager.globalLogLevel != LogLevel.off";

            firstBool = true;
        }

        ret ~= firstBool ? ") {\n" : "";

        if (asPrintf)
        {
            ret ~= "\tLogManager.defaultLogger.loglcf!(line, file, funcName," ~
                "prettyFuncName, moduleName)\n\t\t(";
        }
        else
        {
            ret ~= "\tLogManager.defaultLogger.loglc!(line, file, funcName," ~
                "prettyFuncName, moduleName)\n\t\t(";
        }

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
        ret ~= asPrintf ? "msg, args);\n" : "args);\n";

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
+/

enum memLog = q{
	public ref Logger %s(int line = __LINE__, string file = __FILE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string moduleName = __MODULE__, A...)(lazy A args) @trusted 
	{
		if (LogLevel.%s >= LogManager.globalLogLevel
				&& LogManager.globalLogLevel != LogLevel.off 
				&& this.logLevel_ != LogLevel.off) 
		{

			this.logMessage(file, line, funcName, prettyFuncName, moduleName,
				LogLevel.%s, true, Logger.buildLogString(args));
			%s
		}
	
		return this;
	}

	public ref Logger %sc(int line = __LINE__, string file = __FILE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string moduleName = __MODULE__, A...)(const bool cond, lazy A args) @trusted 
	{
		if (cond && LogLevel.%s >= LogManager.globalLogLevel
				&& LogManager.globalLogLevel != LogLevel.off 
				&& this.logLevel_ != LogLevel.off) 
		{
			this.logMessage(file, line, funcName, prettyFuncName, moduleName,
				LogLevel.%s, cond, Logger.buildLogString(args));
			%s
		}

		return this;
	}

	public ref Logger %sf(int line = __LINE__, string file = __FILE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string moduleName = __MODULE__, A...)(string msg, lazy A args) @trusted 
	{
		if (LogLevel.%s >= LogManager.globalLogLevel
				&& LogManager.globalLogLevel != LogLevel.off 
				&& this.logLevel_ != LogLevel.off) 
		{

			this.logMessage(file, line, funcName, prettyFuncName, moduleName,
				LogLevel.%s, true, format(msg, args));
			%s
		}
	
		return this;
	}

	public ref Logger %scf(int line = __LINE__, string file = __FILE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string moduleName = __MODULE__, A...)(const bool cond, string msg, lazy A args)
	   	@trusted 
	{
		if (cond && LogLevel.%s >= LogManager.globalLogLevel
				&& LogManager.globalLogLevel != LogLevel.off 
				&& this.logLevel_ != LogLevel.off) 
		{
			this.logMessage(file, line, funcName, prettyFuncName, moduleName,
				LogLevel.%s, cond, format(msg, args));
			%s
		}

		return this;
	}
};
/*

	*/

//pragma(msg, memLog.format("fatal", "fatal", "fatal", "fatalHandler();"));

//string fatalDG = "fatalLogger();"

//pragma(msg, memLog);
/*pragma(msg, memLog.format(
	"info", "info", "info", "fatalHandler();",
	"info", "info", "info", "fatalHandler();",
	"fatal", "fatal", "fatal", "fatalHandler();",
	"fatal", "fatal", "fatal", "fatalHandler();"));
*/



//pragma(msg, buildLogFunction(true, false, false, LogLevel.unspecific));

// just sanity checking if parenthesis, and braces are balanced
/+
unittest
{
    import std.algorithm : balancedParens;

    foreach(mem; [true, false])
    {
        foreach(con; [true, false])
        {
            foreach(pf; [true, false])
            {
                foreach(ll; [LogLevel.unspecific, LogLevel.trace,
                        LogLevel.info, LogLevel.warning, LogLevel.error,
                        LogLevel.critical, LogLevel.fatal])
                {
                    string s = buildLogFunction(mem, con, pf, ll);
                    assert(s.balancedParens('(', ')'));
                    assert(s.balancedParens('{', '}'));
                }
            }
        }
    }
}
+/

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
                Tid threadId, SysTime timestamp, string msg) @trusted
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
    creates a fatal handler. The fatal handler will throw an $(D Error) if a
    log call is made with a $(D LogLevel) $(D LogLevel.fatal).
    */
    public this(string newName, LogLevel lv) @safe
    {
        this.logLevel = lv;
        this.name = newName;
        this.fatalHandler = delegate() {
            throw new Error("A Fatal Log Message was logged");
        };
    }

    /** A custom logger needs to implement this method.
    Params:
        payload = All information associated with call to log function.
    */
    public void writeLogMsg(ref LoggerPayload payload);

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
            auto lp = LoggerPayload(file, line, funcName, prettyFuncName,
                moduleName, logLevel, thisTid, Clock.currTime, msg);
            this.writeLogMsg(lp);
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
        this.fatalHandler = dg;
    }

	static private final string buildLogString(Args...)(Args args)
	{
		auto app = appender!string();
		auto fmt = FormatSpec!char("%s");
		foreach(arg; args)
		{
			formatValue(app, arg, fmt);
		}

		return app.data();
	}

	
	/** This method logs data depending on a $(D condition) passed
	explicitly.
	
	This method takes a $(D bool) as first argument. In order for the
	data to be processed the $(D bool) must be $(D true) and the $(D LogLevel) of
	the Logger must be greater equal to the global $(D LogLevel).
	
	Params:
	cond = Only if this $(D bool) is $(D true) will the data be logged.
	args = The data that should be logged.
	
	Returns: The logger used by the logging function as reference. 
	
	Examples:
	--------------------
	auto l = new StdIOLogger();
	l.log(1337);
	--------------------
	*/
	public ref Logger log(int line = __LINE__, string file = __FILE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string moduleName = __MODULE__, A...)(lazy A args) @trusted 
	{
		if (this.logLevel_ >= LogManager.globalLogLevel
				&& LogManager.globalLogLevel != LogLevel.off 
				&& this.logLevel_ != LogLevel.off) 
		{

			this.logMessage(file, line, funcName, prettyFuncName, moduleName,
				this.logLevel_, true, Logger.buildLogString(args));
		}
	
		return this;
	}

	/** This method logs data depending on a $(D condition) passed
	explicitly.
	
	This method takes a $(D bool) as first argument. In order for the
	data to be processed the $(D bool) must be $(D true) and the $(D LogLevel) of
	the Logger must be greater equal to the global $(D LogLevel).
	
	Params:
	cond = Only if this $(D bool) is $(D true) will the data be logged.
	args = The data that should be logged.
	
	Returns: The logger used by the logging function as reference. 
	
	Examples:
	--------------------
	auto l = new StdIOLogger();
	l.logc(false, 1337);
	--------------------
	*/
	public ref Logger logc(int line = __LINE__, string file = __FILE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string moduleName = __MODULE__, A...)(const bool cond, lazy A args) @trusted 
	{
		if (cond && this.logLevel_ >= LogManager.globalLogLevel
				&& LogManager.globalLogLevel != LogLevel.off 
				&& this.logLevel_ != LogLevel.off) 
		{
			this.logMessage(file, line, funcName, prettyFuncName, moduleName,
				this.logLevel_, cond, Logger.buildLogString(args));
		}

		return this;
	}

	/** This method logs data depending on a $(D LogLevel) passed
	explicitly.
	
	This method takes a $(D LogLevel) as first argument. In order for the
	data to be processed the $(D LogLevel) must be greater equal to the
	$(D LogLevel) of the used Logger and the global $(D LogLevel).
	
	Params:
	logLevel = The $(D LogLevel) used for logging the message.
	args = The data that should be logged.
	
	Returns: The logger used by the logging function as reference. 
	
	Examples:
	--------------------
	auto l = new StdIOLogger();
	l.logl(LogLevel.error, "Hello World");
	--------------------
	*/
	public ref Logger logl(int line = __LINE__, string file = __FILE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string moduleName = __MODULE__, A...)(const LogLevel logLevel, lazy A args) 
		@trusted 
	{
		if (logLevel >= this.logLevel
				&& logLevel >= LogManager.globalLogLevel
				&& LogManager.globalLogLevel != LogLevel.off 
				&& this.logLevel_ != LogLevel.off) 
		{
			this.logMessage(file, line, funcName, prettyFuncName, moduleName,
				logLevel, true, Logger.buildLogString(args));
		}

		return this;
	}

	/** This method logs data depending on a $(D condition) and a $(D LogLevel) 
	passed explicitly.
	
	This method takes a $(D bool) as first argument and a $(D bool) as second
	argument. In order for the data to be processed the $(D bool) must be $(D
	true) and the $(D LogLevel) of the Logger must be greater equal to
	the global $(D LogLevel).
	
	Params:
	logLevel = The $(D LogLevel) used for logging the message.
	cond = Only if this $(D bool) is $(D true) will the data be logged.
	args = The data that should be logged.
	
	Returns: The logger used by the logging function as reference. 
	
	Examples:
	--------------------
	auto l = new StdIOLogger();
	l.loglc(LogLevel.info, someCondition, 13, 37, "Hello World");
	--------------------
	*/
	public ref Logger loglc(int line = __LINE__, string file = __FILE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string moduleName = __MODULE__, A...)(const LogLevel logLevel, 
		const bool cond, lazy A args) @trusted 
	{
		if (cond && logLevel >= this.logLevel
				&& logLevel >= LogManager.globalLogLevel
				&& LogManager.globalLogLevel != LogLevel.off 
				&& this.logLevel_ != LogLevel.off) 
		{
			this.logMessage(file, line, funcName, prettyFuncName, moduleName,
				logLevel, cond, Logger.buildLogString(args));
		}

		return this;
	}

	
	/** This method logs data in a printf style manner.
	
	In order for the data to be processed the $(D LogLevel) of the Logger 
	must be greater equal to the global $(D LogLevel).
	
	Params:
	msg = The $(D string) that is used to format the additional data.
	args = The data that should be logged.
	
	Returns: The logger used by the logging function as reference. 
	
	Examples:
	--------------------
	auto l = new StdIOLogger();
	l.logf("Hello World %f", 3.1415);
	--------------------
	*/
	public ref Logger logf(int line = __LINE__, string file = __FILE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string moduleName = __MODULE__, A...)(string msg, lazy A args) @trusted 
	{
		if (this.logLevel_ >= LogManager.globalLogLevel
				&& LogManager.globalLogLevel != LogLevel.off 
				&& this.logLevel_ != LogLevel.off) 
		{

			this.logMessage(file, line, funcName, prettyFuncName, moduleName,
				this.logLevel_, true, format(msg, args));
		}
	
		return this;
	}

	/** This function logs data in a printf style manner depending on a 
	$(D condition) passed explicitly
	
	This function takes a $(D bool) as first argument. In order for the
	data to be processed the $(D bool) must be $(D true) and the $(D LogLevel) of
	the Logger must be greater equal to the global $(D LogLevel).
	
	Params:
	cond = Only if this $(D bool) is $(D true) will the data be logged.
	msg = The $(D string) that is used to format the additional data.
	args = The data that should be logged.
	
	Returns: The logger used by the logging function as reference. 
	
	Examples:
	--------------------
	auto l = new StdIOLogger();
	l.logcf(false, "%d", 1337);
	--------------------
	*/
	public ref Logger logcf(int line = __LINE__, string file = __FILE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string moduleName = __MODULE__, A...)(const bool cond, string msg, lazy A args)
	   	@trusted 
	{
		if (cond && this.logLevel_ >= LogManager.globalLogLevel
				&& LogManager.globalLogLevel != LogLevel.off 
				&& this.logLevel_ != LogLevel.off) 
		{
			this.logMessage(file, line, funcName, prettyFuncName, moduleName,
				this.logLevel_, cond, format(msg, args));
		}

		return this;
	}

	/** This function logs data in a printf style manner depending on a 
	$(D condition).
	
	This function takes a $(D LogLevel) as first argument. In order for the
	data to be processed the $(D LogLevel) must be greater equal to the
	$(D LogLevel) of the used Logger, and the global $(D LogLevel).
	
	Params:
	logLevel = The $(D LogLevel) used for logging the message.
	msg = The $(D string) that is used to format the additional data.
	args = The data that should be logged.
	
	Returns: The logger used by the logging function as reference. 
	
	Examples:
	--------------------
	auto l = new StdIOLogger();
	l.loglf(LogLevel.critical, "%d", 1337);
	--------------------
	*/
	public ref Logger loglf(int line = __LINE__, string file = __FILE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string moduleName = __MODULE__, A...)(const LogLevel logLevel, string msg, 
		lazy A args) @trusted 
	{
		if (logLevel >= this.logLevel
				&& logLevel >= LogManager.globalLogLevel
				&& LogManager.globalLogLevel != LogLevel.off 
				&& this.logLevel_ != LogLevel.off) 
		{
			this.logMessage(file, line, funcName, prettyFuncName, moduleName,
				logLevel, true, format(msg, args));
		}

		return this;
	}

	public ref Logger loglcf(int line = __LINE__, string file = __FILE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string moduleName = __MODULE__, A...)(const LogLevel logLevel, const bool cond, 
		string msg, lazy A args) @trusted 
	{
		if (cond && logLevel >= this.logLevel
				&& logLevel >= LogManager.globalLogLevel
				&& LogManager.globalLogLevel != LogLevel.off 
				&& this.logLevel_ != LogLevel.off) 
		{
			this.logMessage(file, line, funcName, prettyFuncName, moduleName,
				logLevel, cond, format(msg, args));
		}

		return this;
	}

	public ref Logger trace(int line = __LINE__, string file = __FILE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string moduleName = __MODULE__, A...)(lazy A args) @trusted 
	{
		if (LogLevel.trace >= LogManager.globalLogLevel
				&& LogManager.globalLogLevel != LogLevel.off 
				&& this.logLevel_ != LogLevel.off) 
		{

			this.logMessage(file, line, funcName, prettyFuncName, moduleName,
				LogLevel.trace, true, Logger.buildLogString(args));
		}
	
		return this;
	}

	public ref Logger tracec(int line = __LINE__, string file = __FILE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string moduleName = __MODULE__, A...)(const bool cond, lazy A args) @trusted 
	{
		if (cond && LogLevel.trace >= LogManager.globalLogLevel
				&& LogManager.globalLogLevel != LogLevel.off 
				&& this.logLevel_ != LogLevel.off) 
		{
			this.logMessage(file, line, funcName, prettyFuncName, moduleName,
				LogLevel.trace, cond, Logger.buildLogString(args));
		}

		return this;
	}

	public ref Logger tracef(int line = __LINE__, string file = __FILE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string moduleName = __MODULE__, A...)(string msg, lazy A args) @trusted 
	{
		if (LogLevel.trace >= LogManager.globalLogLevel
				&& LogManager.globalLogLevel != LogLevel.off 
				&& this.logLevel_ != LogLevel.off) 
		{

			this.logMessage(file, line, funcName, prettyFuncName, moduleName,
				LogLevel.trace, true, format(msg, args));
		}
	
		return this;
	}

	public ref Logger tracecf(int line = __LINE__, string file = __FILE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string moduleName = __MODULE__, A...)(const bool cond, string msg, lazy A args)
	   	@trusted 
	{
		if (cond && LogLevel.trace >= LogManager.globalLogLevel
				&& LogManager.globalLogLevel != LogLevel.off 
				&& this.logLevel_ != LogLevel.off) 
		{
			this.logMessage(file, line, funcName, prettyFuncName, moduleName,
				LogLevel.trace, cond, format(msg, args));
		}

		return this;
	}
	
	mixin(memLog.format(
		"info", "info", "info", "",
		"info", "info", "info", "",
		"info", "info", "info", "",
		"info", "info", "info", ""));
	mixin(memLog.format(
		"warning", "warning", "warning", "",
		"warning", "warning", "warning", "",
		"warning", "warning", "warning", "",
		"warning", "warning", "warning", ""));
	mixin(memLog.format(
		"error", "error", "error", "",
		"error", "error", "error", "",
		"error", "error", "error", "",
		"error", "error", "error", ""));
	mixin(memLog.format(
		"critical", "critical", "critical", "",
		"critical", "critical", "critical", "",
		"critical", "critical", "critical", "",
		"critical", "critical", "critical", ""));
	mixin(memLog.format(
		"fatal", "fatal", "fatal", "fatalHandler();",
		"fatal", "fatal", "fatal", "fatalHandler();",
		"fatal", "fatal", "fatal", "fatalHandler();",
		"fatal", "fatal", "fatal", "fatalHandler();"));

	/*
    //                     mem   cond   printf LogLevel
    //mixin(buildLogFunction(true, false, false, LogLevel.unspecific));
    //mixin(buildLogFunction(true, false, false, LogLevel.trace));
    //mixin(buildLogFunction(true, false, false, LogLevel.info));
    mixin(buildLogFunction(true, false, false, LogLevel.warning));
    mixin(buildLogFunction(true, false, false, LogLevel.error));
    mixin(buildLogFunction(true, false, false, LogLevel.critical));
    mixin(buildLogFunction(true, false, false, LogLevel.fatal));
    //mixin(buildLogFunction(true, false, true, LogLevel.unspecific));
    //mixin(buildLogFunction(true, false, true, LogLevel.trace));
    //mixin(buildLogFunction(true, false, true, LogLevel.info));
    mixin(buildLogFunction(true, false, true, LogLevel.warning));
    mixin(buildLogFunction(true, false, true, LogLevel.error));
    mixin(buildLogFunction(true, false, true, LogLevel.critical));
    mixin(buildLogFunction(true, false, true, LogLevel.fatal));
    mixin(buildLogFunction(true, true, false, LogLevel.unspecific));
    //mixin(buildLogFunction(true, true, false, LogLevel.trace));
    //mixin(buildLogFunction(true, true, false, LogLevel.info));
    mixin(buildLogFunction(true, true, false, LogLevel.warning));
    mixin(buildLogFunction(true, true, false, LogLevel.error));
    mixin(buildLogFunction(true, true, false, LogLevel.critical));
    mixin(buildLogFunction(true, true, false, LogLevel.fatal));
    mixin(buildLogFunction(true, true, true, LogLevel.unspecific));
    //mixin(buildLogFunction(true, true, true, LogLevel.trace));
    //mixin(buildLogFunction(true, true, true, LogLevel.info));
    mixin(buildLogFunction(true, true, true, LogLevel.warning));
    mixin(buildLogFunction(true, true, true, LogLevel.error));
    mixin(buildLogFunction(true, true, true, LogLevel.critical));
    mixin(buildLogFunction(true, true, true, LogLevel.fatal));
    //mixin(buildLogFunction(true, false, false, LogLevel.unspecific, true));
    //mixin(buildLogFunction(true, true, false, LogLevel.unspecific, true));
    //mixin(buildLogFunction(true, false, true, LogLevel.unspecific, true));
    //mixin(buildLogFunction(true, true, true, LogLevel.unspecific, true));
	*/

    private LogLevel logLevel_ = LogLevel.info;
    private string name_;
    private void delegate() fatalHandler;
}

/** The static $(D LogManager) handles the creation, and the release of
instances of the $(D Logger) class. It also handles the $(I defaultLogger)
which is used if no logger is manually selected. Additionally the
$(D LogManager) also allows to retrieve $(D Logger)s by their names.
An $(D StdIOLogger) is assigned to be the default $(D Logger).
*/
static class LogManager {
    private @trusted static this()
    {
        //LogManager.defaultLogger_ = new StdIOLogger();
        //LogManager.defaultLogger.logLevel = LogLevel.all;
        LogManager.globalLogLevel_ = LogLevel.all;
    }

    // You must not instantiate a LogManager
    @disable private this() {}

    /** This method returns the default $(D Logger).

    The Logger is returned as a reference. This means it can be rassigned,
    thus changing the defaultLogger.

    Example:
    -------------
    LogManager.defaultLogger = new StdIOLogger;
    -------------
    The example sets a new $(D StdIOLogger) as new defaultLogger.
    */
    public @property final static ref Logger defaultLogger() @trusted
    {
        if(LogManager.defaultLogger_ is null)
        {
            LogManager.defaultLogger_ = new
                StdIOLogger(LogManager.globalLogLevel_);
        }
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
//pragma(msg, buildLogFunction(false, false, false, LogLevel.unspecific));
//mixin(buildLogFunction(false, false, false, LogLevel.unspecific));
//mixin(buildLogFunction(false, false, false, LogLevel.trace));
//mixin(buildLogFunction(false, false, false, LogLevel.info));
//mixin(buildLogFunction(false, false, false, LogLevel.warning));
//mixin(buildLogFunction(false, false, false, LogLevel.error));
//mixin(buildLogFunction(false, false, false, LogLevel.critical));
//mixin(buildLogFunction(false, false, false, LogLevel.fatal));
//mixin(buildLogFunction(false, false, true, LogLevel.unspecific));
//mixin(buildLogFunction(false, false, true, LogLevel.trace));
//mixin(buildLogFunction(false, false, true, LogLevel.info));
//mixin(buildLogFunction(false, false, true, LogLevel.warning));
//mixin(buildLogFunction(false, false, true, LogLevel.error));
//mixin(buildLogFunction(false, false, true, LogLevel.critical));
//mixin(buildLogFunction(false, false, true, LogLevel.fatal));
//mixin(buildLogFunction(false, true, false, LogLevel.unspecific));
//mixin(buildLogFunction(false, true, false, LogLevel.trace));
//mixin(buildLogFunction(false, true, false, LogLevel.info));
//mixin(buildLogFunction(false, true, false, LogLevel.warning));
//mixin(buildLogFunction(false, true, false, LogLevel.error));
//mixin(buildLogFunction(false, true, false, LogLevel.critical));
//mixin(buildLogFunction(false, true, false, LogLevel.fatal));
//mixin(buildLogFunction(false, true, true, LogLevel.unspecific));
//mixin(buildLogFunction(false, true, true, LogLevel.trace));
//mixin(buildLogFunction(false, true, true, LogLevel.info));
//mixin(buildLogFunction(false, true, true, LogLevel.warning));
//mixin(buildLogFunction(false, true, true, LogLevel.error));
//mixin(buildLogFunction(false, true, true, LogLevel.critical));
//mixin(buildLogFunction(false, true, true, LogLevel.fatal));
//mixin(buildLogFunction(false, false, false, LogLevel.unspecific, true));
//mixin(buildLogFunction(false, true, false, LogLevel.unspecific, true));
//mixin(buildLogFunction(false, false, true, LogLevel.unspecific, true));
//mixin(buildLogFunction(false, true, true, LogLevel.unspecific, true));

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

        public override void writeLogMsg(ref LoggerPayload payload) @safe
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

unittest
{
    auto oldunspecificLogger = LogManager.defaultLogger;
    LogLevel oldLogLevel = LogManager.globalLogLevel;
    scope(exit)
    {
        LogManager.defaultLogger = oldunspecificLogger;
        LogManager.globalLogLevel = oldLogLevel;
    }

    LogManager.defaultLogger = new TestLogger("testlogger");

    auto ll = [LogLevel.trace, LogLevel.info, LogLevel.warning,
         LogLevel.error, LogLevel.critical, LogLevel.fatal, LogLevel.off];

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

    l.logc(true, msg);
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg);
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    l.logc(false, msg);
    assert(l.msg == msg);
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    msg = "%s Another message";
    l.logf(msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    l.logcf(true, msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    l.logcf(false, msg, "Yet");
    int nLineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    l.loglf(LogLevel.fatal, msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    l.loglcf(LogLevel.fatal, true, msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    l.loglcf(LogLevel.fatal, false, msg, "Yet");
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

    logc(true, msg);
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg);
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    logc(false, msg);
    assert(l.msg == msg);
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    msg = "%s Another message";
    logf(msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    logcf(true, msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    logcf(false, msg, "Yet");
    nLineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    msg = "%s Another message";
    loglf(LogLevel.fatal, msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    loglcf(LogLevel.fatal, true, msg, "Yet");
    lineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);

    loglcf(LogLevel.fatal, false, msg, "Yet");
    nLineNumber = __LINE__ - 1;
    assert(l.msg == msg.format("Yet"));
    assert(l.line == lineNumber);
    assert(l.logLevel == LogLevel.info);
}

@trusted unittest // default logger
{
    import std.file;
    string name = randomString(32);
    string filename = randomString(32) ~ ".tempLogFile";
    FileLogger l = new FileLogger(filename);
    auto oldunspecificLogger = LogManager.defaultLogger;
    LogManager.defaultLogger = l;

    scope(exit)
    {
        remove(filename);
        LogManager.defaultLogger = oldunspecificLogger;
        LogManager.globalLogLevel = LogLevel.all;
    }

    string notWritten = "this should not be written to file";
    string written = "this should be written to file";

    LogManager.globalLogLevel = LogLevel.critical;
    assert(l.logLevel == LogLevel.critical);

    logl(LogLevel.warning, notWritten);
    logl(LogLevel.critical, written);

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
    auto oldunspecificLogger = LogManager.defaultLogger;

    scope(exit)
    {
        remove(filename);
        LogManager.defaultLogger = oldunspecificLogger;
        LogManager.globalLogLevel = LogLevel.all;
    }

    string notWritten = "this should not be written to file";
    string written = "this should be written to file";

    auto l = new FileLogger(filename);
    LogManager.defaultLogger = l;
    log.logLevel = LogLevel.fatal;

    loglc(LogLevel.critical, false, notWritten);
    loglc(LogLevel.fatal, true, written);
    l.file.flush();
	GC.free(cast(void*)l);

    auto file = File(filename, "r");
    auto readLine = file.readln();
    string nextFile = file.readln();
    assert(!nextFile.empty, nextFile);
    assert(nextFile.indexOf(written) != -1);
    assert(nextFile.indexOf(notWritten) == -1);
	file.close();
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

//pragma(msg, buildLogFunction(true, false, true, LogLevel.unspecific, true));

// testing possible log conditions
@trusted unittest
{
    auto oldunspecificLogger = LogManager.defaultLogger;

    auto mem = new TestLogger("tl");
    LogManager.defaultLogger = mem;

    scope(exit)
    {
        LogManager.defaultLogger = oldunspecificLogger;
        LogManager.globalLogLevel = LogLevel.all;
    }

    int value = 0;
    foreach(gll; [LogLevel.all, LogLevel.trace,
            LogLevel.info, LogLevel.warning, LogLevel.error,
            LogLevel.critical, LogLevel.fatal, LogLevel.off])
    {

        LogManager.globalLogLevel = gll;

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
                                if (memOrG)
                                {
                                    if (prntf)
                                    {
                                        if (cond)
                                        {
                                            mem.loglcf(ll2, condValue, "%s",
                                                value);
                                        }
                                        else
                                        {
                                            mem.loglf(ll2, "%s", value);
                                        }
                                    }
                                    else
                                    {
                                        if (cond)
                                        {
                                            mem.loglc(ll2, condValue,
                                                to!string(value));
                                        }
                                        else
                                        {
                                            mem.logl(ll2, to!string(value));
                                        }
                                    }
                                }
                                else
                                {
                                    if (prntf)
                                    {
                                        if (cond)
                                        {
                                            loglcf(ll2, condValue, "%s", value);
                                        }
                                        else
                                        {
                                            loglf(ll2, "%s", value);
                                        }
                                    }
                                    else
                                    {
                                        if (cond)
                                        {
                                            loglc(ll2, condValue,
                                                to!string(value));
                                        }
                                        else
                                        {
                                            logl(ll2, to!string(value));
                                        }
                                    }
                                }

                                string valueStr = to!string(value);
                                ++value;

                                bool shouldLog = ((gll != LogLevel.off)
                                    && (ll != LogLevel.off)
                                    && (cond ? condValue : true)
                                    && (ll2 >= gll)
                                    && (ll2 >= ll));

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
                                        "gll(%u) ll2(%u) cond(%b)" ~
                                        " condValue(%b)" ~
                                        " memOrG(%b) shouldLog(%b) %s == %s",
                                        gll, ll2, cond, condValue, memOrG,
                                        shouldLog, mem.msg, valueStr
                                    ));
                                }
                                else
                                {
                                    assert(mem.msg != valueStr, format(
                                        "gll(%u) ll2(%u) cond(%b) " ~
                                        "condValue(%b)  memOrG(%b) " ~
                                        "shouldLog(%b) %s != %s", gll,
                                        ll2, cond, condValue, memOrG,shouldLog,
                                        mem.msg, valueStr
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

// Issue #5
unittest
{
    auto oldunspecificLogger = LogManager.defaultLogger;

    scope(exit)
    {
        LogManager.defaultLogger = oldunspecificLogger;
        LogManager.globalLogLevel = LogLevel.all;
    }

    auto tl = new TestLogger("required name", LogLevel.info);
    LogManager.defaultLogger = tl;

    trace("trace");
    assert(tl.msg.indexOf("trace") == -1);
    info("info");
    assert(tl.msg.indexOf("info") == 0);
}

// Issue #5
unittest
{
    auto oldunspecificLogger = LogManager.defaultLogger;

    scope(exit)
    {
        LogManager.defaultLogger = oldunspecificLogger;
        LogManager.globalLogLevel = LogLevel.all;
    }

    auto logger = new MultiLogger(LogLevel.error);

    auto tl = new TestLogger("required name", LogLevel.info);
    logger.insertLogger(tl);
    LogManager.defaultLogger = logger;

    trace("trace");
    assert(tl.msg.indexOf("trace") == -1);
    info("info");
    assert(tl.msg.indexOf("info") == -1);
    error("error");
    assert(tl.msg.indexOf("error") == 0);
}
