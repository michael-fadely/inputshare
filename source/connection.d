module connection;

import std.exception;
import std.socket;
import std.algorithm;
import std.array;
import std.concurrency;
import core.time;

debug import std.stdio : stdout, stderr;

import buttons;
import listener;
import packet;
import socket;
import vector;
import simulator;

enum MessageType : ubyte
{
	None,
	TakeControl,
	GiveControl,
	ButtonDown,
	ButtonUp,
	MouseMove,
	MouseSet,
	ScrollVertical,
	ScrollHorizontal
}

struct Message
{
	MessageType    type;
	VirtualButton  button;
	Direction      direction;
	Vector2!int    mouse;
	Vector2!double mouseRatio;
	short          wheel;
}

class Connections
{
private:
	Object sync = new Object();
	SocketSet set;
	Packet packet = new Packet();
	Socket[] sockets;

public:
	this()
	{
		set = new SocketSet();
	}

	@property auto count() const { synchronized (sync) return sockets.length; }

	void add(Socket socket)
	{
		enforce(socket.isAlive, "Socket is dead!");

		synchronized (sync)
		{
			sockets ~= socket;
		}
	}

	void giveControl(in Vector2!double screenRatio, Direction dir)
	{
		synchronized (sync)
		{
			if (sockets.empty)
			{
				return;
			}

			packet.put(MessageType.GiveControl);
			sendDirAndRatio(screenRatio, dir);
		}
	}

	void takeControl(in Vector2!double screenRatio, Direction dir)
	{
		synchronized (sync)
		{
			if (sockets.empty)
			{
				return;
			}

			packet.put(MessageType.TakeControl);
			sendDirAndRatio(screenRatio, dir);
		}
	}

	private void sendDirAndRatio(in Vector2!double screenRatio, Direction dir)
	{
		packet.put(dir);
		packet.put(screenRatio.x);
		packet.put(screenRatio.y);
	}

	void button(bool pressed, VirtualButton button)
	{
		synchronized (sync)
		{
			if (sockets.empty)
			{
				return;
			}

			with (MessageType) packet.put(pressed ? ButtonDown : ButtonUp);
			packet.put(button);
		}
	}

	void mouseMove(int dx, int dy)
	{
		synchronized (sync)
		{
			if (sockets.empty)
			{
				return;
			}

			if (!dx && !dy)
			{
				return;
			}

			packet.put(MessageType.MouseMove);
			packet.put(dx);
			packet.put(dy);
		}
	}

	void mouseSet(int x, int y)
	{
		synchronized (sync)
		{
			if (sockets.empty)
			{
				return;
			}

			packet.put(MessageType.MouseSet);
			packet.put(x);
			packet.put(y);
		}
	}

	void scrollVertical(short amount)
	{
		synchronized (sync)
		{
			if (sockets.empty)
			{
				return;
			}

			if (!amount)
			{
				return;
			}

			packet.put(MessageType.ScrollVertical);
			packet.put(amount);
		}
	}

	void scrollHorizontal(short amount)
	{
		synchronized (sync)
		{
			if (sockets.empty)
			{
				return;
			}

			if (!amount)
			{
				return;
			}

			packet.put(MessageType.ScrollHorizontal);
			packet.put(amount);
		}
	}

	void finalize()
	{
		synchronized (sync)
		{
			if (sockets.empty || packet.empty)
			{
				return;
			}

			Socket[] failed;
			foreach (socket; sockets)
			{
				auto n = socket.send(packet.data);
				if (!n || n == Socket.ERROR)
				{
					failed ~= socket;
				}
			}

			if (!failed.empty)
			{
				debug stdout.writeln("Lost connection to some sockets or something");
				foreach (socket; failed)
				{
					socket.disconnect();
					sockets = sockets.remove!(x => x is socket);
				}
			}

			packet.clear();
		}
	}

	void read(void delegate(ref in Message) dg)
	{
		synchronized (sync)
		{
			if (sockets.empty)
			{
				return;
			}

			sockets.each!(x => set.add(x));
			Socket.select(set, null, null, 1.msecs);
		
			Socket[] failed;

			foreach (socket; sockets)
			{
				if (!set.isSet(socket))
				{
					continue;
				}

				MessageType type;

			read_loop:
				for (ptrdiff_t n = socket.read(type); n != 0; n = socket.read(type))
				{
					if (n == Socket.ERROR)
					{
						debug stdout.writeln("error");
						failed ~= socket;
						break;
					}

					if (!n)
					{
						debug stdout.writeln("!n");
						break;
					}

					Message message;
					message.type = type;

					switch (message.type) with (MessageType)
					{
						case TakeControl:
						case GiveControl:
							socket.read(message.direction);
							socket.read(message.mouseRatio.x);
							socket.read(message.mouseRatio.y);
							break;

						case ButtonDown:
						case ButtonUp:
							socket.read(message.button);
							break;

						case MouseMove:
						case MouseSet:
							socket.read(message.mouse.x);
							socket.read(message.mouse.y);
							break;

						case ScrollVertical:
						case ScrollHorizontal:
							socket.read(message.wheel);
							break;

						default:
							debug stdout.writeln("default");
							break read_loop;
					}

					//debug stdout.writeln("Received message type: ", type);
					dg(message);
				}
			}

			foreach (socket; failed)
			{
				debug stdout.writeln("Lost connection to some sockets or something");

				socket.disconnect();
				sockets = sockets.remove!(x => x is socket);
			}
		}
	}
}
