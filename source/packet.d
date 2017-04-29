module packet;

import std.array;
import std.conv;

class Packet
{
private:
	size_t _size;
	Appender!(ubyte[]) buffer;

public:
	@property auto data() { return buffer.data[0 .. size]; }
	@property bool empty() { return !_size; }
	@property auto size() { return _size; }

	void clear()
	{
		buffer.clear();
		_size = 0;
	}

	void put(ubyte value)
	{
		buffer.put(value);
		++_size;
	}

	void put(T)(T value)
	{
		auto b = (cast(ubyte*)&value)[0 .. T.sizeof].idup;
		buffer.put(b);
		_size += T.sizeof;
	}
}
