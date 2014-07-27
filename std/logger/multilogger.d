module std.logger.multilogger;

import std.logger.core;
import std.logger.stdiologger;
import std.container : Array;
import std.range : isRandomAccessRange;
import std.functional : binaryFun;

ptrdiff_t binarySearchIndex(Range, V, alias pred = "a < b")
	(Range _input, V value) if (isRandomAccessRange!Range)
{
	return binarySearchIndex!(Range, V, pred, pred)(_input, value);
}

ptrdiff_t binarySearchIndex(Range, V, 
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

abstract class MultiLoggerBase : Logger
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
    this(const LogLevel lv = LogLevel.info) @safe
    {
        this("", lv);
    }

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
    this(string name, const LogLevel lv = LogLevel.info) @trusted
    {
        super(name, lv);
		this.logger.reserve(16);
    }

    /** This member holds all important data of the $(D MultiLogger).

    As mentioned earlier a $(D MultiLogger) is map, this associative array is
    the mapping.
    */
    //Logger[string] logger;
	Array!Logger logger;

	void insertLogger(Logger);
    Logger removeLogger(Logger loggerName);

    override void writeLogMsg(ref LoggerPayload payload) @trusted {
        version(DisableMultiLogging)
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
                const bool ll = payload.logLevel >= it.logLevel;
                if (ll)
                {
                    it.writeLogMsg(payload);
                }
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
    this(const LogLevel lv = LogLevel.info) @safe
    {
        this("", lv);
    }

    this(string name, const LogLevel lv = LogLevel.info) @safe
    {
        super(name, lv);
    }

    /** This method inserts a new Logger into the Multilogger.
    */
    override void insertLogger(Logger newLogger) @trusted
    {
        import std.array;
		import std.range : assumeSorted;
		import std.algorithm : sort, isSorted;
        if (newLogger.name.empty)
        {
            throw new Exception("A Logger must have a name to be inserted " ~
                "into the MulitLogger");
        }
        else if (logger[].assumeSorted.contains(newLogger))
        {
            throw new Exception(
                "This MultiLogger instance already holds a  Logger named '" ~
                   newLogger.name ~ "'");
        }
        else
        {
            //logger[newLogger.name] = newLogger;
			this.logger.insertBack(newLogger);
			this.logger[].sort();
			assert(this.logger[].isSorted);
        }
    }

    ///
    unittest
    {
        auto l1 = new MultiLogger;
        auto l2 = new StdioLogger("some_logger");

        l1.insertLogger(l2);

        assert(l1.removeLogger(l2) is l2);
    }

    unittest
    {
		import std.exception : assertThrown;
        auto l1 = new MultiLogger;
        auto l2 = new StdioLogger();
        assertThrown(l1.insertLogger(l2));
    }

    /** This method removes a Logger from the Multilogger.

    See_Also: std.logger.MultiLogger.insertLogger
    */
    override Logger removeLogger(Logger toRemove) @trusted
    {
		import std.range : assumeSorted;
		import std.stdio;

		auto sorted = this.logger[].assumeSorted;
        if (!sorted.contains(toRemove))
        {
			foreach(it; this.logger[])
				writeln(it.name);
            throw new Exception(
                "This MultiLogger instance does not hold a Logger named '" ~
                toRemove.name ~ "'");
        }
        else
        {
            auto found = sorted.equalRange(toRemove);
			assert(!found.empty);
			auto ret = found.front;

			auto idx = sorted.binarySearchIndex(toRemove);
			assert(idx < this.logger.length);
			auto slize = this.logger[idx .. idx+1];
			assert(!slize.empty);
            this.logger.linearRemove(slize);
            return ret;
        }
    }

    /** This method returns a $(D Logger) if it is present in the $(D
    MultiLogger), otherwise a $(D RangeError) will be thrown.
    */
    Logger opIndex(string key) @trusted
    {
		import std.range : assumeSorted;
        auto sortedArray = this.logger[].assumeSorted;
		auto idx = binarySearchIndex!(typeof(this.logger[]), string, 
			"a.name<b","a<b.name")(this.logger[], key);

		return this.logger[idx];
    }

    ///
    unittest
    {
        auto ml = new MultiLogger();
        auto sl = new StdioLogger("some_name");

        ml.insertLogger(sl);

        assert(ml["some_name"] is sl);
    }
}

class ArrayLogger : MultiLoggerBase {
    this(const LogLevel lv = LogLevel.info) @safe
    {
        this("", lv);
    }

    this(string name, const LogLevel lv = LogLevel.info) @safe
    {
        super(name, lv);
    }

    override void insertLogger(Logger newLogger) @trusted
    {
		this.logger.insertBack(newLogger);
	}

    override Logger removeLogger(Logger toRemove) @trusted
    {
		import std.algorithm : find;
		import std.range : take;
		auto r = this.logger[].find(toRemove);
		if (r.empty)
		{
            throw new Exception(
                "This MultiLogger instance does not hold a Logger named '" ~
                toRemove.name ~ "'");
		}

		auto ret = r.front();
		this.logger.linearRemove(r.take(1));
		return ret;
	}
}

unittest
{
	import std.logger.nulllogger;
	import std.exception : assertThrown;
	auto a = new ArrayLogger;
	auto n0 = new NullLogger("zero");
	auto n1 = new NullLogger("one");
	a.insertLogger(n0);
	a.insertLogger(n1);

	auto n0_1 = a.removeLogger(n0);
	assert(n0_1 is n0);
    assertThrown!Exception(a.removeLogger(n0));

	auto n1_1 = a.removeLogger(n1);
	assert(n1_1 is n1);
    assertThrown!Exception(a.removeLogger(n1));
}

unittest
{
	auto a = new ArrayLogger;
	auto n0 = new TestLogger("zero");
	auto n1 = new TestLogger("one");
	a.insertLogger(n0);
	a.insertLogger(n1);

	a.log("Hello TestLogger"); int line = __LINE__;
	assert(n0.msg == "Hello TestLogger");
	assert(n0.line == line);
	assert(n1.msg == "Hello TestLogger");
	assert(n0.line == line);
}
