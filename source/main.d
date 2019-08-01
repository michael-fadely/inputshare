import core.thread;
import core.time;
import std.getopt;
import std.socket;
import std.stdio;
import std.string;

import connection;
import listener;
import socket;

/// Number of bind retries before giving up.
const ushort bindRetry = 100;

bool isClient, isServer;

string address;
ushort port = 5029;

__gshared Listener ioListener;

version (Windows)
{
	import core.sys.windows.windows;

extern (Windows):
	LRESULT KeyboardProc(int nCode, WPARAM wParam, LPARAM lParam) nothrow
	{
		try
		{
			return ioListener.runKeyboardHook(nCode, wParam, lParam);
		}
		catch (Exception ex)
		{
			try
			{
				stderr.writeln(ex);
			}
			catch (Exception)
			{
				// ignored
			}

			return CallNextHookEx(null, nCode, wParam, lParam);
		}
	}

	LRESULT MouseProc(int nCode, WPARAM wParam, LPARAM lParam) nothrow
	{
		try
		{
			return ioListener.runMouseHook(nCode, wParam, lParam);
		}
		catch (Exception ex)
		{
			try
			{
				stderr.writeln(ex);
			}
			catch (Exception)
			{
				// ignored
			}

			return CallNextHookEx(null, nCode, wParam, lParam);
		}
	}

	BOOL ScreenRatioFromCursor(HMONITOR hMonitor, HDC hdcMonitor, LPRECT lprcMonitor, LPARAM dwData) nothrow
	{
		return ioListener.screenRatioFromCursor(hMonitor, hdcMonitor, lprcMonitor, dwData);
	}
}

int main(string[] args)
{
	stdout.writeln("Build: ", __TIMESTAMP__);

	try
	{
		auto help = getopt(args,
		                   "h|host",
		                   "Host an input share server.",
		                   &isServer,

		                   "c|connect",
		                   "Connect to an input share server.",
		                   &isClient,
		                   
		                   "a|address",
		                   "Address to connect to.",
		                   &address,
		                   
		                   "p|port",
		                   "Port to host on or connect on.",
		                   &port
		                   );

		if (help.helpWanted)
		{
			defaultGetoptPrinter("Usage:", help.options);
			return 0;
		}

		if (isServer && isClient)
		{
			throw new Exception("You can't be the server and the client!");
		}

		if (isClient && address.empty)
		{
			throw new Exception("You must specify an address to connect to with --address or -a");
		}
	}
	catch (Exception ex)
	{
		stderr.writeln(ex.msg);
		return -1;
	}

	auto connections = new Connections();

	version (Windows)
	{
		ioListener = new Listener(connections, &KeyboardProc, &MouseProc, &ScreenRatioFromCursor);
	}
	else
	{
		ioListener = new Listener(connections);
	}

	Socket socket;

	if (isServer)
	{
		socket = new Socket(AddressFamily.INET, SocketType.STREAM);
		socket.blocking = true;

		for (size_t i; i <= bindRetry; i++)
		{
			try
			{
				socket.bind(new InternetAddress(InternetAddress.ADDR_ANY, port));
				socket.listen(1);
				break;
			}
			catch (Exception ex)
			{
				if (i < bindRetry)
				{
					stderr.writeln(ex.msg);
					stderr.writefln("[IPv4] Retrying... [%d/%d]", i + 1, bindRetry);
					Thread.sleep(1.seconds);
				}
				else
				{
					stderr.writeln(ex.msg);
					stderr.writeln("Aborting.");
					return -1;
				}
			}
		}
	}
	else if (isClient)
	{
		stdout.writeln(address, ':', port);

		while (true)
		{
			try
			{
				auto addr = new InternetAddress(address, port);

				socket = new Socket(AddressFamily.INET, SocketType.STREAM);
				socket.blocking = true;

				socket.connect(addr);
				stdout.writeln("connected???");

				connections.add(socket);
				break;
			}
			catch (SocketOSException ex)
			{
				stderr.writeln(ex.msg);
				stderr.writeln(ex.errorCode);
				//return -1;
			}
		}
	}
	else
	{
		stderr.writeln("have you considered being a client or a server");
		return -1;
	}

	ioListener.start();
	auto set = new SocketSet();

	while (ioListener.isRunning)
	{
		if (isClient && !socket.isAlive)
		{
			ioListener.stop();
			socket.disconnect();
			break;
		}

		Thread.sleep(125.msecs);

		if (isServer)
		{
			set.add(socket);
			Socket.select(set, null, null, 1.msecs);

			if (set.isSet(socket))
			{
				stdout.writeln("Accepting connection!");
				connections.add(socket.accept());
			}
		}
	}

	try
	{
		ioListener.join();
		return 0;
	}
	catch (Exception ex)
	{
		stderr.writeln(ex.msg);
		return -1;
	}

	//return 0;
}
