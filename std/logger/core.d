/**
Implements logging facilities.

Message logging is a common approach to expose runtime information of a
program. Logging should be easy, but also flexible and powerful, therefore $(D D)
provides a standard interface for logging.

The easiest way to create a log message is to write
$(D import std.logger; log("I am here");) this will print a message to the
stdio device.  The message will contain the filename, the linenumber, the name
of the surrounding function, and the message.

Copyright: Copyright Robert burner Schadek 2013 --
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

By default only one $(D Logger) exists, this is the defaultLogger. In order to
use this $(D Logger) simply call the free standing log functions like:
$(LI $(D log))
$(LI $(D trace))
$(LI $(D info))
$(LI $(D warning))
$(LI $(D critical))
$(LI $(D fatal))
The default $(D Logger) will by default log to stdout and has a default
$(D LogLevel) of $(D LogLevel.all). The default Logger can be accessed by
using a property call $(D defaultLogger). This property a reference to the
current default $(D Logger). This reference can be used to assign a new
default $(D Logger).
-------------
defaultLogger = new FileLogger("New_Default_Log_File.log");
-------------

Additional $(D Logger) can be created by creating a new instance of the
required $(D Logger). These $(D Logger) have the same methodes as the
defaultLogger.

The $(D LogLevel) of an log call can be defined in two was. The first is by
calling $(D logl) and passing the $(D LogLevel) explicit. Notice the
additional $(B l) after log. The $(D LogLevel) is to be passed as first
argument to the function. The second way, of setting the $(D LogLevel) of a
log call, is be call either $(D trace), $(D info), $(D warning), $(D critical)
or $(D fatal). The log call will than have the respective $(D LogLevel).

Conditional logging can be achived be appending a $(B c) to the function
identifier and passing a $(D bool) as first argument to the function.
If conditional logging is used the condition must be $(D true) in order to
have the log message logged.

In order to combine a explicit $(D LogLevel) passing with conditional logging
call the function or method $(D loglc). The first required argument to the
call then becomes the $(D LogLevel) and the second argument is the $(D bool).

Messages are logged if the $(D LogLevel) of the log message is greater equal
than the $(D LogLevel) of the used $(D Logger) and additionally if the
$(D LogLevel) of the log message is greater equal to the global $(D LogLevel).
The global $(D LogLevel) is accessible by using $(D globalLogLevel).
To assign the $(D LogLevel) of a $(D Logger) use the $(D logLevel) property of
the logger.

If printf style logging is required add a $(B f) to the logging call, like
such:
$(D myLogger.infof("Hello %s", "world");) or $(fatalf("errno %d", 1337))
The additional $(B f) enables printf style logging for call combinations of
explicit $(D LogLevel) and conditional logging functions and methods. The
$(B f) is always to be placed last.

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

Even though the idea behind this logging module is to provide a common
interface and easy extensibility certain specific Logger are already
implemented.

$(LI StdIOLogger = This $(D Logger) logs data to stdout.)
$(LI FileLogger = This $(D Logger) logs data to files.)
$(LI MulitLogger = This $(D Logger) logs data to multiple $(D Logger).)
$(LI NullLogger = This $(D Logger) will never do anything.)
$(LI TemplateLogger = This $(D Logger) can be used to create simple custom $(D Logger).)

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
import std.logger.multilogger;
import std.logger.filelogger;
import std.logger.nulllogger;

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
    if (defaultLogger.logLevel >= globalLogLevel
            && globalLogLevel != LogLevel.off
            && defaultLogger.logLevel != LogLevel.off)
    {
        defaultLogger.log!(line, file, funcName,prettyFuncName,
            moduleName)(args);
    }

    return defaultLogger;
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
    if (logLevel >= globalLogLevel
            && logLevel >= defaultLogger.logLevel
            && globalLogLevel != LogLevel.off
            && defaultLogger.logLevel != LogLevel.off )
    {
        defaultLogger.logl!(line, file, funcName,prettyFuncName,
            moduleName)(logLevel, args);
    }

    return defaultLogger;
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
    if (cond && defaultLogger.logLevel >= globalLogLevel
            && globalLogLevel != LogLevel.off
            && defaultLogger.logLevel != LogLevel.off )
    {
        defaultLogger.logc!(line, file, funcName,prettyFuncName,
            moduleName)(cond, args);
    }

    return defaultLogger;
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
    if (cond && logLevel >= globalLogLevel
            && logLevel >= defaultLogger.logLevel
            && globalLogLevel != LogLevel.off
            && defaultLogger.logLevel != LogLevel.off )
    {
        defaultLogger.loglc!(line, file, funcName,prettyFuncName,
            moduleName)(logLevel, cond, args);
    }

    return defaultLogger;
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
    if (defaultLogger.logLevel >= globalLogLevel
            && globalLogLevel != LogLevel.off
            && defaultLogger.logLevel != LogLevel.off )
    {
        defaultLogger.logf!(line, file, funcName,prettyFuncName,
            moduleName)(msg, args);
    }

    return defaultLogger;
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
    if (logLevel >= globalLogLevel
            && logLevel >= defaultLogger.logLevel
            && globalLogLevel != LogLevel.off
            && defaultLogger.logLevel != LogLevel.off )
    {
        defaultLogger.loglf!(line, file, funcName,prettyFuncName,
            moduleName)(logLevel, msg, args);
    }

    return defaultLogger;
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
    if (cond && defaultLogger.logLevel >= globalLogLevel
            && globalLogLevel != LogLevel.off
            && defaultLogger.logLevel != LogLevel.off )
    {
        defaultLogger.logcf!(line, file, funcName,prettyFuncName,
            moduleName)(cond, msg, args);
    }

    return defaultLogger;
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
    if (cond && logLevel >= globalLogLevel
            && logLevel >= defaultLogger.logLevel
            &&globalLogLevel != LogLevel.off
            && defaultLogger.logLevel != LogLevel.off )
    {
        defaultLogger.loglcf!(line, file, funcName,prettyFuncName,
            moduleName)(logLevel, cond, msg, args);
    }

    return defaultLogger;
}

alias trace = logImpl!(LogLevel.trace);
alias info = logImpl!(LogLevel.info);
alias warning = logImpl!(LogLevel.warning);
alias error = logImpl!(LogLevel.error);
alias critical = logImpl!(LogLevel.critical);
alias fatal = logImpl!(LogLevel.fatal);

alias tracec = logImplc!(LogLevel.trace);
alias infoc = logImplc!(LogLevel.info);
alias warningc = logImplc!(LogLevel.warning);
alias errorc = logImplc!(LogLevel.error);
alias criticalc = logImplc!(LogLevel.critical);
alias fatalc = logImplc!(LogLevel.fatal);

alias tracef = logImplf!(LogLevel.trace);
alias infof = logImplf!(LogLevel.info);
alias warningf = logImplf!(LogLevel.warning);
alias errorf = logImplf!(LogLevel.error);
alias criticalf = logImplf!(LogLevel.critical);
alias fatalf = logImplf!(LogLevel.fatal);

alias tracecf = logImplcf!(LogLevel.trace);
alias infocf = logImplcf!(LogLevel.info);
alias warningcf = logImplcf!(LogLevel.warning);
alias errorcf = logImplcf!(LogLevel.error);
alias criticalcf = logImplcf!(LogLevel.critical);
alias fatalcf = logImplcf!(LogLevel.fatal);

template logImpl(LogLevel ll)
{
	ref Logger logImpl(int line = __LINE__, string file = __FILE__,
	    string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	    string moduleName = __MODULE__, A...)(lazy A args) @trusted
	{
	    if (ll >= globalLogLevel
	            && ll >= defaultLogger.logLevel
	            && globalLogLevel != LogLevel.off
	            && defaultLogger.logLevel != LogLevel.off)
	    {
	        defaultLogger.logImplM!(ll).logImpl!(line, file, funcName,prettyFuncName,
	            moduleName)(args);
	    }
	
	    return defaultLogger;
	}
}

template logImplc(LogLevel ll)
{
	ref Logger logImplc(int line = __LINE__, string file = __FILE__,
	    string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	    string moduleName = __MODULE__, A...)(const bool cond, lazy A args) @trusted
	{
	    if (cond && ll >= globalLogLevel
	            && ll >= defaultLogger.logLevel
	            && globalLogLevel != LogLevel.off
	            && defaultLogger.logLevel != LogLevel.off )
	    {
	        defaultLogger.logImplM!(ll).logImplc!(line, file, funcName,prettyFuncName,
	            moduleName)(cond, args);
	    }
	
	    return defaultLogger;
	}
}

template logImplf(LogLevel ll)
{
	ref Logger logImplf(int line = __LINE__, string file = __FILE__,
	    string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	    string moduleName = __MODULE__, A...)(string msg, lazy A args)
	    @trusted
	{
	    if (ll >= globalLogLevel
	            && ll >= defaultLogger.logLevel
	            && globalLogLevel != LogLevel.off
	            && defaultLogger.logLevel != LogLevel.off )
	    {
	        defaultLogger.logImplM!(ll).logImplc!(line, file, funcName,prettyFuncName,
	            moduleName)(true, msg, args);
	    }
	
	    return defaultLogger;
	}
}

template logImplcf(LogLevel ll)
{
	ref Logger logImplcf(int line = __LINE__, string file = __FILE__,
	    string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
	    string moduleName = __MODULE__, A...)(const bool cond, string msg, lazy A args)
	    @trusted
	{
	    if (cond && ll >= defaultLogger.logLevel
				&& defaultLogger.logLevel >= globalLogLevel
	            && globalLogLevel != LogLevel.off
	            && defaultLogger.logLevel != LogLevel.off )
	    {
	        defaultLogger.logImplM!(ll).logImplcf!(line, file, funcName,prettyFuncName,
	            moduleName)(cond, msg, args);
	    }
	
	    return defaultLogger;
	}
}

/+
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
    if (LogLevel.trace >= globalLogLevel
            && LogLevel.trace >= defaultLogger.logLevel
            && globalLogLevel != LogLevel.off
            && defaultLogger.logLevel != LogLevel.off)
    {
        defaultLogger.trace!(line, file, funcName,prettyFuncName,
            moduleName)(args);
    }

    return defaultLogger;
}

/** This method logs data with $(D LogLevel) $(D trace), a $(D condition)
is passed explicitly.

In order for the data to be processed the $(D LogLevel) of the defaultLogger
must be smaller equal to $(D LogLevel.trace) and the global $(D LogLevel) must
also be smaller equal to $(D LogLevel.trace).

Params:
cond = Only if this $(D bool) is $(D true) will the data be logged.
args = The data that should be logged.

Returns: The logger used by the logging method as reference.

Examples:
--------------------
trace(1337, "is number");
--------------------

Additionally, to $(D tracecf) there are the method.
$(LI $(D info))
$(LI $(D warning))
$(LI $(D error))
$(LI $(D critical))
$(LI $(D fatal))

These method behave exactly like $(D tracecf) with the exception of a
different $(D LogLevel) used for logging the data.
*/
public ref Logger tracec(int line = __LINE__, string file = __FILE__,
    string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
    string moduleName = __MODULE__, A...)(const bool cond, lazy A args) @trusted
{
    if (cond && LogLevel.trace >= globalLogLevel
            && LogLevel.trace >= defaultLogger.logLevel
            && globalLogLevel != LogLevel.off
            && defaultLogger.logLevel != LogLevel.off )
    {
        defaultLogger.tracec!(line, file, funcName,prettyFuncName,
            moduleName)(cond, args);
    }

    return defaultLogger;
}

/** This function logs data in a printf style manner with $(D LogLevel)
$(D LogLevel.trace).

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
    string moduleName = __MODULE__, A...)(string msg, lazy A args)
    @trusted
{
    if (LogLevel.trace >= globalLogLevel
            && LogLevel.trace >= defaultLogger.logLevel
            && globalLogLevel != LogLevel.off
            && defaultLogger.logLevel != LogLevel.off )
    {
        defaultLogger.tracecf!(line, file, funcName,prettyFuncName,
            moduleName)(true, msg, args);
    }

    return defaultLogger;
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
    if (cond && defaultLogger.logLevel >= globalLogLevel
            && LogLevel.trace >= defaultLogger.logLevel
            && globalLogLevel != LogLevel.off
            && defaultLogger.logLevel != LogLevel.off )
    {
        defaultLogger.tracecf!(line, file, funcName,prettyFuncName,
            moduleName)(cond, msg, args);
    }

    return defaultLogger;
}

enum freeLog = q{

public ref Logger %s(int line = __LINE__, string file = __FILE__,
    string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
    string moduleName = __MODULE__, A...)(lazy A args) @trusted
{
    if (LogLevel.%s >= globalLogLevel
            && LogLevel.%s >= defaultLogger.logLevel
            && globalLogLevel != LogLevel.off
            && defaultLogger.logLevel != LogLevel.off)
    {
        defaultLogger.%s!(line, file, funcName,prettyFuncName,
            moduleName)(args);
    }

    return defaultLogger;
}

public ref Logger %sc(int line = __LINE__, string file = __FILE__,
    string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
    string moduleName = __MODULE__, A...)(const bool cond, lazy A args) @trusted
{
    if (cond && LogLevel.%s >= globalLogLevel
            && LogLevel.%s >= defaultLogger.logLevel
            && globalLogLevel != LogLevel.off
            && defaultLogger.logLevel != LogLevel.off )
    {
        defaultLogger.%sc!(line, file, funcName,prettyFuncName,
            moduleName)(cond, args);
    }

    return defaultLogger;
}

public ref Logger %sf(int line = __LINE__, string file = __FILE__,
    string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
    string moduleName = __MODULE__, A...)(string msg, lazy A args)
    @trusted
{
    if (LogLevel.%s >= globalLogLevel
            && LogLevel.%s >= defaultLogger.logLevel
            && globalLogLevel != LogLevel.off
            && defaultLogger.logLevel != LogLevel.off )
    {
        defaultLogger.%sf!(line, file, funcName,prettyFuncName,
            moduleName)(msg, args);
    }

    return defaultLogger;
}

public ref Logger %scf(int line = __LINE__, string file = __FILE__,
    string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
    string moduleName = __MODULE__, A...)(const bool cond, string msg, lazy A args)
    @trusted
{
    if (cond && LogLevel.%s >= globalLogLevel
            && LogLevel.%s >= defaultLogger.logLevel
            && globalLogLevel != LogLevel.off
            && defaultLogger.logLevel != LogLevel.off )
    {
        defaultLogger.%scf!(line, file, funcName,prettyFuncName,
            moduleName)(cond, msg, args);
    }

    return defaultLogger;
}
};

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

enum memLog = q{
    public ref Logger %s(int line = __LINE__, string file = __FILE__,
        string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(lazy A args) @trusted
    {
        if (LogLevel.%s >= globalLogLevel
                && globalLogLevel != LogLevel.off
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
        if (cond && LogLevel.%s >= globalLogLevel
                && globalLogLevel != LogLevel.off
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
        if (LogLevel.%s >= globalLogLevel
                && globalLogLevel != LogLevel.off
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
        if (cond && LogLevel.%s >= globalLogLevel
                && globalLogLevel != LogLevel.off
                && this.logLevel_ != LogLevel.off)
        {
            this.logMessage(file, line, funcName, prettyFuncName, moduleName,
                LogLevel.%s, cond, format(msg, args));
            %s
        }

        return this;
    }
};
+/

/**
There are eight usable logging level. These level are $(I all), $(I trace),
$(I info), $(I warning), $(I error), $(I critical), $(I fatal), and $(I off).
If a log function with $(D LogLevel.fatal) is called the shutdown handler of
that logger is called.
*/
enum LogLevel : ubyte
{
    //unspecific = 0, 
	/*If no $(D LogLevel) is passed to the log function this
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

	alias trace = logImplM!(LogLevel.trace).logImpl;
	alias info = logImplM!(LogLevel.info).logImpl;
	alias warning = logImplM!(LogLevel.warning).logImpl;
	alias error = logImplM!(LogLevel.error).logImpl;
	alias critical = logImplM!(LogLevel.critical).logImpl;
	alias fatal = logImplM!(LogLevel.fatal).logImpl;
	
	alias tracec = logImplM!(LogLevel.trace).logImplc;
	alias infoc = logImplM!(LogLevel.info).logImplc;
	alias warningc = logImplM!(LogLevel.warning).logImplc;
	alias errorc = logImplM!(LogLevel.error).logImplc;
	alias criticalc = logImplM!(LogLevel.critical).logImplc;
	alias fatalc = logImplM!(LogLevel.fatal).logImplc;
	
	alias tracef = logImplM!(LogLevel.trace).logImplf;
	alias infof = logImplM!(LogLevel.info).logImplf;
	alias warningf = logImplM!(LogLevel.warning).logImplf;
	alias errorf = logImplM!(LogLevel.error).logImplf;
	alias criticalf = logImplM!(LogLevel.critical).logImplf;
	alias fatalf = logImplM!(LogLevel.fatal).logImplf;
	
	alias tracecf = logImplM!(LogLevel.trace).logImplcf;
	alias infocf = logImplM!(LogLevel.info).logImplcf;
	alias warningcf = logImplM!(LogLevel.warning).logImplcf;
	alias errorcf = logImplM!(LogLevel.error).logImplcf;
	alias criticalcf = logImplM!(LogLevel.critical).logImplcf;
	alias fatalcf = logImplM!(LogLevel.fatal).logImplcf;

	template logImplM(LogLevel ll) 
	{
    	public ref Logger logImpl(int line = __LINE__, string file = __FILE__,
    	    string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
    	    string moduleName = __MODULE__, A...)(lazy A args) @trusted
    	{
    	    if (ll >= globalLogLevel
    	            && globalLogLevel != LogLevel.off
    	            && this.logLevel_ != LogLevel.off)
    	    {

    	        this.logMessage(file, line, funcName, prettyFuncName, moduleName,
    	            ll, true, Logger.buildLogString(args));

				static if(ll == LogLevel.fatal)
					fatalHandler();
    	    }

    	    return this;
    	}

    	public ref Logger logImplc(int line = __LINE__, string file = __FILE__,
    	    string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
    	    string moduleName = __MODULE__, A...)(const bool cond, lazy A args) @trusted
    	{
    	    if (cond && ll >= globalLogLevel
    	            && globalLogLevel != LogLevel.off
    	            && this.logLevel_ != LogLevel.off)
    	    {
    	        this.logMessage(file, line, funcName, prettyFuncName, moduleName,
    	            ll, cond, Logger.buildLogString(args));

				static if(ll == LogLevel.fatal)
					fatalHandler();
    	    }

    	    return this;
    	}

    	public ref Logger logImplf(int line = __LINE__, string file = __FILE__,
    	    string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
    	    string moduleName = __MODULE__, A...)(string msg, lazy A args) @trusted
    	{
    	    if (ll >= globalLogLevel
    	            && globalLogLevel != LogLevel.off
    	            && this.logLevel_ != LogLevel.off)
    	    {

    	        this.logMessage(file, line, funcName, prettyFuncName, moduleName,
    	            ll, true, format(msg, args));

				static if(ll == LogLevel.fatal)
					fatalHandler();
    	    }

    	    return this;
    	}

    	public ref Logger logImplcf(int line = __LINE__, string file = __FILE__,
    	    string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
    	    string moduleName = __MODULE__, A...)(const bool cond, string msg, 
			lazy A args) @trusted
    	{
    	    if (cond && ll >= globalLogLevel
    	            && globalLogLevel != LogLevel.off
    	            && this.logLevel_ != LogLevel.off)
    	    {
    	        this.logMessage(file, line, funcName, prettyFuncName, moduleName,
    	            ll, cond, format(msg, args));

				static if(ll == LogLevel.fatal)
					fatalHandler();
    	    }

    	    return this;
    	}
	}

    /** This method logs data with the $(D LogLevel) of the used $(D Logger).

    This method takes a $(D bool) as first argument. In order for the
    data to be processed the $(D bool) must be $(D true) and the $(D LogLevel) of
    the Logger must be greater equal to the global $(D LogLevel).

    Params:
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
        if (this.logLevel_ >= globalLogLevel
                && globalLogLevel != LogLevel.off
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
        if (cond && this.logLevel_ >= globalLogLevel
                && globalLogLevel != LogLevel.off
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
                && logLevel >= globalLogLevel
                && globalLogLevel != LogLevel.off
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
                && logLevel >= globalLogLevel
                && globalLogLevel != LogLevel.off
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
        if (this.logLevel_ >= globalLogLevel
                && globalLogLevel != LogLevel.off
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
        if (cond && this.logLevel_ >= globalLogLevel
                && globalLogLevel != LogLevel.off
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
                && logLevel >= globalLogLevel
                && globalLogLevel != LogLevel.off
                && this.logLevel_ != LogLevel.off)
        {
            this.logMessage(file, line, funcName, prettyFuncName, moduleName,
                logLevel, true, format(msg, args));
        }

        return this;
    }

    /** This method logs data in a printf style manner depending on a $(D
    LogLevel) and a $(D condition) passed explicitly

    This method takes a $(D LogLevel) as first argument. This function takes a
    $(D bool) as second argument. In order for the data to be processed the
    $(D bool) must be $(D true) and the $(D LogLevel) of the Logger must be
    greater equal to the global $(D LogLevel).

    Params:
    logLevel = The $(D LogLevel) used for logging the message.
    cond = Only if this $(D bool) is $(D true) will the data be logged.
    msg = The $(D string) that is used to format the additional data.
    args = The data that should be logged.

    Returns: The logger used by the logging method as reference.

    Examples:
    --------------------
    auto l = new StdIOLogger();
    l.loglcf(LogLevel.trace, false, "%d %s", 1337, "is number");
    --------------------
    */
    public ref Logger loglcf(int line = __LINE__, string file = __FILE__,
        string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(const LogLevel logLevel, const bool cond,
        string msg, lazy A args) @trusted
    {
        if (cond && logLevel >= this.logLevel
                && logLevel >= globalLogLevel
                && globalLogLevel != LogLevel.off
                && this.logLevel_ != LogLevel.off)
        {
            this.logMessage(file, line, funcName, prettyFuncName, moduleName,
                logLevel, cond, format(msg, args));
        }

        return this;
    }

	/+
    /** This method logs data with $(D LogLevel) $(D trace).

    In order for the data to be processed the $(D LogLevel) of the defaultLogger
    must be smaller equal to $(D LogLevel.trace) and the global $(D LogLevel) must
    also be smaller equal to $(D LogLevel.trace).

    Params:
    args = The data that should be logged.

    Returns: The logger used by the logging method as reference.

    Examples:
    --------------------
    auto l = new StdIOLogger();
    l.trace(1337, "is number");
    --------------------

    Additionally, to $(D tracecf) there are the method.
    $(LI $(D info))
    $(LI $(D warning))
    $(LI $(D error))
    $(LI $(D critical))
    $(LI $(D fatal))

    These method behave exactly like $(D tracecf) with the exception of a
    different $(D LogLevel) used for logging the data.
    */
    public ref Logger trace(int line = __LINE__, string file = __FILE__,
        string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(lazy A args) @trusted
    {
        if (LogLevel.trace >= globalLogLevel
                && globalLogLevel != LogLevel.off
                && this.logLevel_ != LogLevel.off)
        {

            this.logMessage(file, line, funcName, prettyFuncName, moduleName,
                LogLevel.trace, true, Logger.buildLogString(args));
        }

        return this;
    }

    /** This method logs data with $(D LogLevel) $(D trace), a $(D condition)
    is passed explicitly.

    This method takes a $(D bool) as first argument. In order for the data to
    be processed the $(D bool) must be $(D true), the $(D LogLevel) of the
    Logger must be smaller equal to $(D LogLevel.trace) and the global
    $(D LogLevel) must also be smaller equal to $(D LogLevel.trace).

    Params:
    cond = Only if this $(D bool) is $(D true) will the data be logged.
    args = The data that should be logged.

    Returns: The logger used by the logging method as reference.

    Examples:
    --------------------
    auto l = new StdIOLogger();
    l.tracec(false, 1337, "is number");
    --------------------

    Additionally, to $(D tracecf) there are the method.
    $(LI $(D infocf))
    $(LI $(D warningcf))
    $(LI $(D errorcf))
    $(LI $(D criticalcf))
    $(LI $(D fatalcf))

    These method behave exactly like $(D tracecf) with the exception of a
    different $(D LogLevel) used for logging the data.
    */
    public ref Logger tracec(int line = __LINE__, string file = __FILE__,
        string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(const bool cond, lazy A args) @trusted
    {
        if (cond && LogLevel.trace >= globalLogLevel
                && globalLogLevel != LogLevel.off
                && this.logLevel_ != LogLevel.off)
        {
            this.logMessage(file, line, funcName, prettyFuncName, moduleName,
                LogLevel.trace, cond, Logger.buildLogString(args));
        }

        return this;
    }

    /** This method logs data in a printf style manner with $(D LogLevel)
    $(D trace).

    In order for the data to be processed the $(D bool) must be $(D true), the
    $(D LogLevel) of the Logger must be smaller equal to $(D LogLevel.trace)
    and the global $(D LogLevel) must also be smaller equal to $(D
    LogLevel.trace).

    Params:
    msg = The $(D string) that is used to format the additional data.
    args = The data that should be logged.

    Returns: The logger used by the logging function as reference.

    Examples:
    --------------------
    auto l = new StdIOLogger();
    l.tracef("%d %s", 1337, "is number");
    --------------------

    Additionally, to $(D tracecf) there are the method.
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
        string moduleName = __MODULE__, A...)(string msg, lazy A args) @trusted
    {
        if (LogLevel.trace >= globalLogLevel
                && globalLogLevel != LogLevel.off
                && this.logLevel_ != LogLevel.off)
        {

            this.logMessage(file, line, funcName, prettyFuncName, moduleName,
                LogLevel.trace, true, format(msg, args));
        }

        return this;
    }

    /** This method logs data in a printf style manner with $(D LogLevel)
    $(D trace), a $(D condition) is passed explicitly.

    This method takes a $(D bool) as first argument. In order for the data to be processed the
    $(D bool) must be $(D true), the $(D LogLevel) of the Logger must be
    smaller equal to $(D LogLevel.trace) and the global $(D LogLevel) must also be
    smaller equal to $(D LogLevel.trace).

    Params:
    cond = Only if this $(D bool) is $(D true) will the data be logged.
    msg = The $(D string) that is used to format the additional data.
    args = The data that should be logged.

    Returns: The logger used by the logging function as reference.

    Examples:
    --------------------
    auto l = new StdIOLogger();
    l.tracecf(false, "%d %s", 1337, "is number");
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
        if (cond && LogLevel.trace >= globalLogLevel
                && globalLogLevel != LogLevel.off
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
	+/

    private LogLevel logLevel_ = LogLevel.info;
    private string name_;
    private void delegate() fatalHandler;
}

/** This method returns the default $(D Logger).

The Logger is returned as a reference. This means it can be rassigned,
thus changing the defaultLogger.

Example:
-------------
defaultLogger = new StdIOLogger;
-------------
The example sets a new $(D StdIOLogger) as new defaultLogger.
*/
public @property ref Logger defaultLogger() @trusted
{
    static __gshared Logger logger;
    if(logger is null)
    {
        logger = new
            StdIOLogger(globalLogLevel());
    }
    return logger;
}

private ref LogLevel globalLogLevelImpl() @trusted
{
    static __gshared LogLevel ll = LogLevel.all;
    return ll;
}

/** This method returns the global $(D LogLevel). */
public @property LogLevel globalLogLevel() @trusted
{
    return globalLogLevelImpl();
}

/** This method sets the global $(D LogLevel).

Every log message with a $(D LogLevel) lower as the global $(D LogLevel)
will be discarded before it reaches $(D writeLogMessage) method.
*/
public static @property void globalLogLevel(LogLevel ll) @trusted
{
    if(defaultLogger !is null) {
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

    ml.removeLogger(tl1.name);
    ml.removeLogger(tl2.name);
    assertThrown!Exception(ml.removeLogger(tl1.name));
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

// testing more possible log conditions
@safe unittest
{
    auto mem = new TestLogger("tl");

    scope(exit)
    {
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
            foreach(cond; [true, false])
            {
                mem.logLevel = ll;

                bool gllVSll = LogLevel.trace >= globalLogLevel;
                bool gllOff = globalLogLevel != LogLevel.off;
                bool llOff = mem.logLevel != LogLevel.off;
                bool test = gllVSll && gllOff && llOff && cond;

                mem.line = -1;
                /*writefln("%3d %3d %3d %b g %b go %b lo %b %b %b", LogLevel.trace,
                          mem.logLevel, globalLogLevel, LogLevel.trace >= mem.logLevel,
                        gllVSll, gllOff, llOff, cond, test);
                */

                mem.trace(__LINE__); int line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.tracec(cond, __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.tracef("%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.tracecf(cond, "%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                gllVSll = LogLevel.trace >= globalLogLevel;
                test = gllVSll && gllOff && llOff && cond;

                mem.info(__LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.infoc(cond, __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.infof("%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.infocf(cond, "%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                gllVSll = LogLevel.trace >= globalLogLevel;
                test = gllVSll && gllOff && llOff && cond;

                mem.warning(__LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.warningc(cond, __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.warningf("%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.warningcf(cond, "%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                gllVSll = LogLevel.trace >= globalLogLevel;
                test = gllVSll && gllOff && llOff && cond;

                mem.critical(__LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.criticalc(cond, __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.criticalf("%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;

                mem.criticalcf(cond, "%d", __LINE__); line = __LINE__;
                assert(test ? mem.line == line : true); line = -1;
            }
        }
    }
}

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

    foreach(gll; [LogLevel.all, LogLevel.trace,
            LogLevel.info, LogLevel.warning, LogLevel.error,
            LogLevel.critical, LogLevel.fatal, LogLevel.off])
    {

        globalLogLevel = gll;

        foreach(cond; [true, false])
        {
            bool gllVSll = LogLevel.trace >= globalLogLevel;
            bool gllOff = globalLogLevel != LogLevel.off;
            bool llOff = mem.logLevel != LogLevel.off;
            bool test = gllVSll && gllOff && llOff && cond;

            mem.line = -1;
            /*writefln("%3d %3d %3d %b g %b go %b lo %b %b %b", LogLevel.trace,
                      mem.logLevel, globalLogLevel, LogLevel.trace >= mem.logLevel,
                    gllVSll, gllOff, llOff, cond, test);
            */

            trace(__LINE__); int line = __LINE__;
            assert(test ? mem.line == line : true); line = -1;

            tracec(cond, __LINE__); line = __LINE__;
            assert(test ? mem.line == line : true); line = -1;

            tracef("%d", __LINE__); line = __LINE__;
            assert(test ? mem.line == line : true); line = -1;

            tracecf(cond, "%d", __LINE__); line = __LINE__;
            assert(test ? mem.line == line : true); line = -1;

            gllVSll = LogLevel.trace >= globalLogLevel;
            test = gllVSll && gllOff && llOff && cond;

            info(__LINE__); line = __LINE__;
            assert(test ? mem.line == line : true); line = -1;

            infoc(cond, __LINE__); line = __LINE__;
            assert(test ? mem.line == line : true); line = -1;

            infof("%d", __LINE__); line = __LINE__;
            assert(test ? mem.line == line : true); line = -1;

            infocf(cond, "%d", __LINE__); line = __LINE__;
            assert(test ? mem.line == line : true); line = -1;

            gllVSll = LogLevel.trace >= globalLogLevel;
            test = gllVSll && gllOff && llOff && cond;

            warning(__LINE__); line = __LINE__;
            assert(test ? mem.line == line : true); line = -1;

            warningc(cond, __LINE__); line = __LINE__;
            assert(test ? mem.line == line : true); line = -1;

            warningf("%d", __LINE__); line = __LINE__;
            assert(test ? mem.line == line : true); line = -1;

            warningcf(cond, "%d", __LINE__); line = __LINE__;
            assert(test ? mem.line == line : true); line = -1;

            gllVSll = LogLevel.trace >= globalLogLevel;
            test = gllVSll && gllOff && llOff && cond;

            critical(__LINE__); line = __LINE__;
            assert(test ? mem.line == line : true); line = -1;

            criticalc(cond, __LINE__); line = __LINE__;
            assert(test ? mem.line == line : true); line = -1;

            criticalf("%d", __LINE__); line = __LINE__;
            assert(test ? mem.line == line : true); line = -1;

            criticalcf(cond, "%d", __LINE__); line = __LINE__;
            assert(test ? mem.line == line : true); line = -1;
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
