import std.experimental.logger;

/**

  This will not work

*/

unittest {
	import std.conv : to;
	auto tl = new TestLogger(LogLevel.trace);
	tl.trace(); int line = __LINE__;
	tl.info();

	assert(tl.line == line, to!string(tl.line));
}

unittest
{
	static assert( isLoggingActiveAt!(LogLevel.trace));
	static assert(!isLoggingActiveAt!(LogLevel.info));
	static assert( isLoggingActiveAt!(LogLevel.warning));
	static assert( isLoggingActiveAt!(LogLevel.error));
	static assert( isLoggingActiveAt!(LogLevel.critical));
	static assert( isLoggingActiveAt!(LogLevel.fatal));
}
