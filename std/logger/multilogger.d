module std.logger.multilogger;

import std.container : Array;
import std.functional : binaryFun;
import std.logger.core;
import std.logger.filelogger;
import std.range : isRandomAccessRange;
import std.stdio : stdout;

ptrdiff_t binarySearchIndex(Range, V, alias pred = "a < b")
    (Range _input, V value) if (isRandomAccessRange!Range)
{
    return binarySearchIndex2!(Range, V, pred, pred)(_input, value);
}

ptrdiff_t binarySearchIndex2(Range, V,
    alias predA = "a < b", alias predB = "a < b")(Range _input, V value)
    if (isRandomAccessRange!Range)
{
    alias predFunA = binaryFun!predA;
    alias predFunB = binaryFun!predB;

    size_t first = 0, count = _input.length;
    while (count > 0)
    {
        immutable step = count / 2, it = first + step;
        if (predFunA(_input[it], value))
        {
            // Less than value, bump left bound up
            first = it + 1;
            count -= step + 1;
        }
        else if (predFunB(value, _input[it]))
        {
            // Greater than value, chop count
            count = step;
        }
        else
        {
            // Found!!!
            return cast(ptrdiff_t)it;
        }
    }
    return -1;
}

unittest
{
    auto a = [1,2,3,4,5,6];
    auto idx = a.binarySearchIndex(1);
    assert(idx == 0);
    idx = a.binarySearchIndex(6);
    assert(idx == 5);
}

struct MultiLoggerEntry
{
    string name;
    Logger logger;
}

abstract class MultiLoggerBase : Logger
{
    /** A constructor for the $(D MultiLogger) Logger.

    Params:
      name = The name of the logger. Compare to $(D FileLogger.insertLogger).
      lv = The $(D LogLevel) for the $(D MultiLogger). By default the
      $(D LogLevel) for $(D MultiLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto l1 = new MultiLogger("loggerName");
    auto l2 = new MultiLogger("loggerName", LogLevel.fatal);
    -------------
    */
    this(const LogLevel lv = LogLevel.info)
    {
        super(lv);
        this.logger.reserve(16);
    }

    /** This member holds all important data of the $(D MultiLogger).

    As mentioned earlier a $(D MultiLogger) is map, this associative array is
    the mapping.
    */
    //Logger[string] logger;
    Array!MultiLoggerEntry logger;

    void insertLogger(string name, Logger logger);
    Logger removeLogger(string loggerName);

    override void writeLogMsg(ref LogEntry payload) @trusted {
        foreach (it; logger)
        {
            /* The LogLevel of the Logger must be >= than the LogLevel of
            the payload. Usually this is handled by the log functions. As
            they are not called in this case, we have to handle it by hand
            here.
            */
            const bool ll = payload.logLevel >= it.logger.logLevel;
            if (ll)
            {
                it.logger.writeLogMsg(payload);
            }
        }
    }
}

/** MultiLogger logs to multiple logger.

It can be used to construct arbitrary, tree like structures. Basically a $(D
MultiLogger) is a map. It maps $(D Logger)s to $(D strings)s. By adding a $(D
MultiLogger) into another $(D MultiLogger) a non leaf nodes is added into the
tree. The map is implemented as an associated array by the mapper
$(D MultiLogger.logger).

Example:
--------------
/+

root -> node -> b
|       |
|       |-> c
|-> a

+/

auto root = new MultiLogger("root", LogLevel.trace);
auto node = new MultiLogger("Node", LogLevel.warning);

auto a = new StdioLogger("a", LogLevel.trace);
auto b = new StdioLogger("b", LogLevel.info);
auto c = new StdioLogger("c", LogLevel.info);

root.insert(node);
root.insert(a);

node.insert(b);
node.insert(c);
--------------
*/
class MultiLogger : MultiLoggerBase {
    this(const LogLevel lv = LogLevel.info)
    {
        super(lv);
    }

    /** This method inserts a new Logger into the Multilogger.
    */
    override void insertLogger(string name, Logger newLogger)
    {
        import std.array;
        import std.range : assumeSorted;
        import std.algorithm : sort, isSorted, canFind;
        if (name.empty)
        {
            throw new Exception("A Logger must have a name to be inserted " ~
                "into the MulitLogger");
        }
        else if (logger[].assumeSorted!"a.name < b.name".canFind!"a.name == b"(name))
        {
            throw new Exception(
                "This MultiLogger instance already holds a  Logger named '" ~
                   name ~ "'");
        }
        else
        {
            //logger[newLogger.name] = newLogger;
            this.logger.insertBack(MultiLoggerEntry(name, newLogger));
            this.logger[].sort!("a.name < b.name")();
            assert(this.logger[].isSorted!"a.name < b.name");
        }
    }

    ///
    unittest
    {
        auto l1 = new MultiLogger;
        auto l2 = new FileLogger(stdout);

        l1.insertLogger("someName", l2);

        assert(l1.removeLogger("someName") is l2);
    }

    unittest
    {
        import std.exception : assertThrown;
        auto l1 = new MultiLogger;
        auto l2 = new FileLogger(stdout);
        assertThrown(l1.insertLogger("", l2));
    }

    /** This method removes a Logger from the Multilogger.

    See_Also: std.logger.MultiLogger.insertLogger
    */
    override Logger removeLogger(string toRemove)
    {
        import std.range : assumeSorted;
        import std.stdio;
        import std.algorithm : canFind;

        auto sorted = this.logger[].assumeSorted!"a.name < b.name";
        if (!sorted.canFind!"a.name == b"(toRemove))
        {
            foreach(it; this.logger[])
                writeln(it.name);
            throw new Exception(
                "This MultiLogger instance does not hold a Logger named '" ~
                toRemove ~ "'");
        }
        else
        {
            MultiLoggerEntry dummy;
            dummy.name = toRemove;
            auto found = sorted.equalRange(dummy);
            assert(!found.empty);
            auto ret = found.front;

            alias predFunA = binaryFun!"a.name < b";
            alias predFunB = binaryFun!"a < b.name";

            auto idx = binarySearchIndex2!(typeof(this.logger[]), string,
                "a.name<b","a<b.name")(this.logger[], toRemove);

            assert(idx < this.logger.length);
            auto slize = this.logger[idx .. idx+1];
            assert(!slize.empty);
            this.logger.linearRemove(slize);
            return ret.logger;
        }
    }

    /** This method returns a $(D Logger) if it is present in the $(D
    MultiLogger), otherwise a $(D RangeError) will be thrown.
    */
    Logger opIndex(string key)
    {
        import std.range : assumeSorted;
        auto sortedArray = this.logger[].assumeSorted!"a.name < b.name";
        auto idx = binarySearchIndex2!(typeof(this.logger[]), string,
            "a.name<b","a<b.name")(this.logger[], key);

        return this.logger[idx].logger;
    }

    ///
    unittest
    {
        auto ml = new MultiLogger;
        auto sl = new FileLogger(stdout);

        ml.insertLogger("some_name", sl);

        assert(ml["some_name"] is sl);
    }
}

class ArrayLogger : MultiLoggerBase {
    this(const LogLevel lv = LogLevel.info)
    {
        super(lv);
    }

    override void insertLogger(string name, Logger newLogger)
    {
        this.logger.insertBack(MultiLoggerEntry(name, newLogger));
    }

    override Logger removeLogger(string toRemove)
    {
        import std.algorithm : find;
        import std.range : take;
        auto r = this.logger[].find!"a.name == b"(toRemove);
        if (r.empty)
        {
            throw new Exception(
                "This MultiLogger instance does not hold a Logger named '" ~
                toRemove ~ "'");
        }

        auto ret = r.front();
        this.logger.linearRemove(r.take(1));
        return ret.logger;
    }
}

unittest
{
    import std.logger.nulllogger;
    import std.exception : assertThrown;
    auto a = new ArrayLogger;
    auto n0 = new NullLogger();
    auto n1 = new NullLogger();
    a.insertLogger("zero", n0);
    a.insertLogger("one", n1);

    auto n0_1 = a.removeLogger("zero");
    assert(n0_1 is n0);
    assertThrown!Exception(a.removeLogger("zero"));

    auto n1_1 = a.removeLogger("one");
    assert(n1_1 is n1);
    assertThrown!Exception(a.removeLogger("one"));
}

unittest
{
    auto a = new ArrayLogger;
    auto n0 = new TestLogger;
    auto n1 = new TestLogger;
    a.insertLogger("zero", n0);
    a.insertLogger("one", n1);

    a.log("Hello TestLogger"); int line = __LINE__;
    assert(n0.msg == "Hello TestLogger");
    assert(n0.line == line);
    assert(n1.msg == "Hello TestLogger");
    assert(n0.line == line);
}

unittest // issue 16
{
    import std.stdio : File;
    import std.string : indexOf;
    auto logName = randomString(32) ~ ".log";
    auto logFileOutput = File(logName, "w");
    scope(exit)
    {
        import std.file : remove;
        logFileOutput.close();
        remove(logName);
    }
    auto traceLog = new FileLogger(logFileOutput, LogLevel.all);
    auto infoLog  = new TestLogger(LogLevel.info);

    auto root = new MultiLogger(LogLevel.all);
    root.insertLogger("fileLogger", traceLog);
    root.insertLogger("stdoutLogger", infoLog);

    string tMsg = "A trace message";
    root.trace(tMsg); int line1 = __LINE__;

    assert(infoLog.line != line1);
    assert(infoLog.msg != tMsg);

    string iMsg = "A info message";
    root.info(iMsg); int line2 = __LINE__;

    assert(infoLog.line == line2);
    assert(infoLog.msg == iMsg, infoLog.msg ~ ":" ~ iMsg);

    logFileOutput.close();
    logFileOutput = File(logName, "r");
    assert(logFileOutput.isOpen);
    assert(!logFileOutput.eof);

    auto line = logFileOutput.readln();
    assert(line.indexOf(tMsg) != -1, line ~ ":" ~ tMsg);
    assert(!logFileOutput.eof);
    line = logFileOutput.readln();
    assert(line.indexOf(iMsg) != -1, line ~ ":" ~ tMsg);
}

unittest
{
    auto dl = defaultLogger;
    assert(dl !is null);
    assert(dl.logLevel == LogLevel.all);
    assert(globalLogLevel == LogLevel.all);
}
