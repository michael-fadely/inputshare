import std.getopt;
import std.stdio;

bool isClient, isServer;
string address;
ushort port;

int main(string[] args)
{
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
	}
	catch (Exception ex)
	{
		stderr.writeln(ex.msg);
		return -1;
	}

	return 0;
}
