module socket;

import std.socket;
import std.exception;

template read(T)
{
	ptrdiff_t read(Socket socket, out T value)
	{
		enforce(socket.isAlive, "Cannot read from dead socket.");

		ubyte[T.sizeof] buffer;
		auto n = socket.receive(buffer);

		if (n != T.sizeof)
		{
			return n;
		}

		static if (is(T : ubyte) || is(t == ubyte) || is(T : byte) || is(t == byte))
		{
			value = cast(T)buffer[0];
		}
		else
		{
			value = *cast(T*)buffer.ptr;
		}

		return n;
	}
}

void disconnect(Socket socket)
{
	if (socket !is null)
	{
		socket.shutdown(SocketShutdown.BOTH);
		socket.close();
	}
}
