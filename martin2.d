private struct MakeType(LogLevel.Value v) { enum val = v; alias val this; }

/// LogLevel
struct LogLevel
{
    // make one type per log level to allow compile time disabling of logging
    // each loglevel value implicitly converts to the runtime enum value
    enum debug_ = MakeType!(Value.debug_)();
    enum info = MakeType!(Value.info)();
    enum error = MakeType!(Value.error)();

    this(Value v)(MakeType!v val) { this(val.val); }
    this(Value val) { _val = val; }

private:
    // runtime loglevel value
    enum Value : ubyte {
        debug_,
        info,
        error,
   }

    Value _val;
    alias _val this;
}

/// Logger concept
enum isLogger(T) = is(typeof({
    LogLevel v = T.init.minLogLevel;
    LogEntry e;
    T.init.write(e);
}));

/// Logger interface for dynamic binding
interface Logger {
    LogLevel minLogLevel() const;
    void write(in LogEntry);
}
static assert(isLogger!Logger);

/// create a Logger interface shim
Logger loggerObject(T)(T t) if (isLogger!T) {
    static class Impl {
        T t;
        LogLevel minLogLevel() const { return T.minLogLevel; }
        void write(in LogEntry e) { t.write(e); }
    }
    return new Impl(t);
}

/// a log entry
struct LogEntry { string file; int line; string msg; }

/// log with compile-time LogLevel
void log(Logger, LogLevel.Value level, int line = __LINE__, string file = __FILE__, Args...)(ref Logger logger, MakeType!level, lazy Args args) if (level >= logger.minLogLevel) {
    import std.conv : text;
    logger.write(LogEntry(file, line, text(args)));
}
/// log with compile-time LogLevel, optimized out
void log(Logger, LogLevel.Value level, int line = __LINE__, string file = __FILE__, Args...)(ref Logger logger, MakeType!level, lazy Args args) if (level < logger.minLogLevel) {
}

// runtime LogLevel
void log(Logger, string file=__FILE__, int line=__LINE__, Args...)(ref Logger logger, LogLevel level, lazy Args args) {
    if (level < logger.minLogLevel) return;
    import std.conv : text;
    logger.write(LogEntry(file, line, text(args)));
}

unittest
{
    static struct TestLogger
    {
        enum minLogLevel = LogLevel.error;
        void write(in LogEntry e) { _entries ~= e; }

        const(LogEntry)[] _entries;
    }
    static assert(isLogger!TestLogger);

    TestLogger logger;
    // compile time log level
    logger.log(LogLevel.debug_, "bar", 0);
    assert(!logger._entries.length);
    logger.log(LogLevel.error, "foo", 1);
    assert(logger._entries == [LogEntry(__FILE__, __LINE__ - 1, "foo1")]);

    logger._entries.clear();

    // runtime log level
    LogLevel level = LogLevel.debug_;
    logger.log(level, "bar", 2);
    assert(!logger._entries.length);
    level = __ctfe ? LogLevel.info : LogLevel.error;
    logger.log(level, "foo", 3);
    assert(logger._entries == [LogEntry(__FILE__, __LINE__ - 1, "foo3")]);
}

void main()
{
}
