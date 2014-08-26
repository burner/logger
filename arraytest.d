import std.stdio;
import std.container;

abstract class A {
	void write() {}
}

class B : A {
	override void write() { writeln("Hello from B"); }
}

struct Pair {
	string name;
	A logger;
}

void main() {
	Array!Pair arr;
	arr.insertBack(Pair("a", new B));
	arr.insertBack(Pair("a", new B));

	foreach(it; arr) {
		it.logger.write();
	}
}
