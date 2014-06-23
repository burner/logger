module std.logger.filelogger;

import std.stdio;
import std.string;
import std.logger.core;
import std.logger.templatelogger;

/** This $(D Logger) implementation writes log messages to the associated
file. The name of the file has to be passed on construction time. If the file
is already present new log messages will be append at its end.
*/
class FileLogger : TemplateLogger!(File.LockingTextWriter, defaultFormatter)
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
        super(stdout.lockingTextWriter(), name, lv);
        this.filename = fn;
        this.file_.open(this.filename, "a");
        sink = this.file.lockingTextWriter();
    }


    /** The file written to is accessible by this method.*/
    public @property ref File file() @trusted
    {
        return this.file_;
    }

    private __gshared File file_;
    private string filename;
}

unittest // file logger test
{
    import std.file;
    import std.random;
    import std.array : empty;

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
    l.logl(LogLevel.warning, notWritten);
    l.logl(LogLevel.critical, written);

    l.file.flush();
    l.file.close();

    auto file = File(filename, "r");
    assert(!file.eof);

    string readLine = file.readln();
    assert(readLine.indexOf(written) != -1);
    assert(readLine.indexOf(notWritten) == -1);
    file.close();

    l = new FileLogger(filename);
    l.loglc(LogLevel.critical, false, notWritten);
    l.loglc(LogLevel.fatal, true, written);
    l.file.close();

    file = File(filename, "r");
    file.readln();
    readLine = file.readln();
    string nextFile = file.readln();
    assert(nextFile.empty, nextFile);
    assert(readLine.indexOf(written) != -1);
    assert(readLine.indexOf(notWritten) == -1);
}
