module std.logger.filelogger;

import std.stdio;
import std.string;
import std.logger.core;
import std.logger.templatelogger;

/** This $(D Logger) implementation writes log messages to the associated
file. The name of the file has to be passed on construction time. If the file
is already present new log messages will be append at its end.
*/
class FileLogger : TemplateLogger!(File.LockingTextWriter, defaultFormatter, 
    (a) => true)
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
		import std.exception : enforce;
        super(name, lv);
        this.filename = fn;
        this.file_.open(this.filename, "a");
        enforce(this.file.isOpen, "Unable to open file: \"" ~ this.filename ~
            "\" for logging.");
    }

	override File.LockingTextWriter getSink() 
	{
		return this.file_.lockingTextWriter();
	}

    /** The file written to is accessible by this method.*/
    public @property ref File file() @trusted
    {
        return this.file_;
    }

    private File file_;
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

    l.file.flush();
    auto file = File(filename, "r");
	string readLine = file.readln();
    assert(readLine.indexOf(written) != -1, readLine);
	readLine = file.readln();
    assert(readLine.indexOf(notWritten) == -1, readLine);
}
