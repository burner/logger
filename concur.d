import std.concurrency;

import std.logger;

void foo() { return; }

void main()
{
	auto id = spawn(&foo);
}
