import std.experimental.logger;

/**

  This will not work

*/

unittest {
	import std.conv : to;
	auto tl = new TestLogger(LogLevel.trace);
	tl.info(); int line = __LINE__;
	tl.warning();

	assert(tl.line == line, to!string(tl.line));
}

unittest
{
	static assert( isLoggingActive!(LogLevel.trace));
	static assert( isLoggingActive!(LogLevel.info));
	static assert(!isLoggingActive!(LogLevel.warning));
	static assert( isLoggingActive!(LogLevel.error));
	static assert( isLoggingActive!(LogLevel.critical));
	static assert( isLoggingActive!(LogLevel.fatal));
}
