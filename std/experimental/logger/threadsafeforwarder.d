module std.experimental.logger.threadsafeforwarder;

import std.experimental.logger.core;

/** The $(D ThreadSafeForwarder) will forward all log calls to its assinged
destination, in a thread safe way. 
*/
class ThreadSafeForwarder : Logger
{
	import std.concurrency;
	import std.datetime;
	import core.sync.mutex;

	Logger destination;

    ubyte[__traits(classInstanceSize, Mutex)] mutexBuffer;
	Mutex mutex;

    /** The default constructor for the $(D ThreadSafeForwarder).

    Params:
		dest = The Logger this Logger forwards all calls to
    */
    this(Logger dest)
    {
		import std.conv : emplace;
        super(dest.logLevel);
		this.destination = dest;
        this.mutex = emplace!Mutex(mutexBuffer);
    }
	
    override @property LogLevel logLevel() const pure @trusted @nogc
    {
        return this.destination.logLevel;
    }

    override @property void logLevel(const LogLevel lv) pure @safe @nogc
    {
		this.destination.logLevel = lv;
    }

    override @property void delegate() fatalHandler() const pure @safe @nogc
    {
        return this.destination.fatalHandler;
    }

    override @property void fatalHandler(void delegate() fh) pure @safe @nogc
    {
        this.destination.fatalHandler = fh;
    }

    override void beginLogMsg(string file, int line, string funcName,
        string prettyFuncName, string moduleName, LogLevel logLevel,
        Tid threadId, SysTime timestamp, Logger logger)
		@safe
    {
		( () @trusted => this.mutex.lock() )();

		static if (isLoggingActive)
		{
			this.destination.beginLogMsg(file, line, funcName, prettyFuncName,
					moduleName, logLevel, threadId, timestamp, logger);
		}
    }

    override void logMsgPart(const(char)[] msg)
    {
		static if (isLoggingActive)
		{
			this.destination.logMsgPart(msg);
		}
    }

    override void finishLogMsg()
    {
		scope(exit) this.mutex.unlock();

		static if (isLoggingActive)
		{
			this.destination.finishLogMsg();
		}
    }
}

///
unittest
{
    auto t = new TestLogger;
    auto a = new ThreadSafeForwarder(t);
	a.logf("%s", 10);
	assert(t.msg == "10");
	a.logf("%s", 11);
	assert(t.msg == "11");

	a.logLevel = LogLevel.critical;
	assert(t.logLevel == LogLevel.critical);
}

unittest {
	import core.thread;
	import std.algorithm.sorting : sort;
	import std.format : format;

    class TestLogger2 : Logger
    {
		import std.concurrency;
		import core.thread;
		import std.datetime;

		string[10] buf;
		int i = 0;

        this(const LogLevel lv = LogLevel.info)
        {
            super(lv);
        }

    	protected override void beginLogMsg(string file, int line, string funcName,
    	    string prettyFuncName, string moduleName, LogLevel logLevel,
    	    Tid threadId, SysTime timestamp, Logger logger)
    	    @safe
    	{
    	}

    	/** Logs a part of the log message. */
    	protected override void logMsgPart(const(char)[] msg)
    	{
			this.buf[i] ~= msg;
    	}

    	/** Signals that the message has been written and no more calls to
    	$(D logMsgPart) follow. */
    	protected override void finishLogMsg()
    	{
			this.i++;
    	}
    }

	class T : Thread {
		Logger l;
		int i;
		this(Logger l, int i) {
			super(&run);
			this.l = l;
			this.i = i;
		}

		void run() {
			this.l.logf("%0d", this.i);
		}
	}

    auto t = new TestLogger2;
    auto a = new ThreadSafeForwarder(t);

	Thread[10] ts;
	for(int i = 0; i < 10; ++i) {
		ts[i] = new T(a, i).start();
	}

	foreach(it; ts) {
		it.join();
	}

	assert(t.i == 10);
	sort(t.buf[]);
	for(int i = 0; i < 10; ++i) {
		assert(t.buf[i] == format("%0d", i), 
			format("%d %0d %s", i, i, t.buf[i])
		);
	}
}
