import std.concurrency;

import std.experimental.logger;

void foo() { return; }

void main()
{
	auto id = spawn(&foo);
}
