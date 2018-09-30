module listener;

import core.thread;
import core.time;
import std.exception;
import std.math;

debug import std.stdio;

import buttons;
import connection;
import vector;
import simulator;

version (Windows)
{
	import core.sys.windows.windows;
}
else version (Posix)
{
	import x11.Xlib;
}
else
{
	static assert("Platform not supported.");
}

/// Number of pixels from the screen edge before forwarding input.
enum MARGIN = 8;

class Listener : Thread
{
private:
	Simulator simulator;

	Connections connections;

	bool isSending;
	bool isReceiving;

	bool simulating;
	int screenLeft, screenTop, screenWidth, screenHeight;

	Vector2!int mouse;
	Vector2!double screenRatio;

	version (Windows)
	{
		alias HookProc = extern (Windows) LRESULT function(int, WPARAM, LPARAM) nothrow;
		alias MonitorCallback = extern (Windows) BOOL function(HMONITOR, HDC, LPRECT, LPARAM) nothrow;

		alias KeyboardHook = HookProc;
		alias MouseHook = HookProc;

		HHOOK keyboardHookLL;
		HHOOK mouseHookLL;

		HookProc keyboardHook, mouseHook;
		MonitorCallback monitorCallback;

	}

public:
	version (Windows)
	{
		this(Connections connections, KeyboardHook keyboardHook, MouseHook mouseHook, MonitorCallback monitorCallback)
		{
			simulator = new Simulator();

			this.connections     = connections;
			this.keyboardHook    = keyboardHook;
			this.mouseHook       = mouseHook;
			this.monitorCallback = monitorCallback;

			super(&run);
		}
	}
	else
	{
		this(Connections connections)
		{
			simulator = new Simulator();
			this.connections = connections;
			super(&run);
		}
	}

	~this()
	{
		stop();
	}

	void stop()
	{
		if (!isRunning)
		{
			return;
		}

		version (Windows)
		{
			PostThreadMessage(id, WM_QUIT, 0, 0);
		}

		join(true);
	}

	version (Windows)
	{
		LRESULT runKeyboardHook(int nCode, WPARAM wParam, LPARAM lParam) 
		{
			if (simulating || connections.count == 0)
			{
				return CallNextHookEx(null, nCode, wParam, lParam);
			}

			auto keyboard = *cast(KBDLLHOOKSTRUCT*)lParam;

			switch (wParam)
			{
				default:
					break;

				case WM_KEYDOWN:
					if (isSending)
					{
						connections.button(true, toVirtual(keyboard.vkCode));
						connections.finalize();
					}
					break;

				case WM_KEYUP:
					if (isSending)
					{
						connections.button(false, toVirtual(keyboard.vkCode));
						connections.finalize();
					}
					break;

				case WM_SYSKEYDOWN:
					if (isSending)
					{
						connections.button(true, toVirtual(keyboard.vkCode));
						connections.finalize();
					}
					break;

				case WM_SYSKEYUP:
					if (isSending)
					{
						connections.button(false, toVirtual(keyboard.vkCode));
						connections.finalize();
					}
					break;
			}

			return isSending && nCode >= 0 ? 1 : CallNextHookEx(null, nCode, wParam, lParam);
		}

		LRESULT runMouseHook(int nCode, WPARAM wParam, LPARAM lParam)
		{
			if (connections.count == 0)
			{
				return CallNextHookEx(null, nCode, wParam, lParam);
			}

			auto llMouse = *cast(MSLLHOOKSTRUCT*)lParam;

			switch (wParam)
			{
				default:
					return CallNextHookEx(null, nCode, wParam, lParam);

				case WM_LBUTTONDOWN:
					if (!simulating && isSending)
					{
						connections.button(true, VK_LBUTTON);
					}
					break;

				case WM_LBUTTONUP:
					if (!simulating && isSending)
					{
						connections.button(false, VK_LBUTTON);
					}
					break;

				case WM_MOUSEMOVE:
					auto x = llMouse.pt.x;
					auto y = llMouse.pt.y;
					auto dx = x - mouse.x;
					auto dy = y - mouse.y;

					POINT pt;
					GetCursorPos(&pt);

					mouse.x = pt.x;
					mouse.y = pt.y;

					if (!dx && !dy)
					{
						break;
					}

					x -= screenLeft;
					y -= screenTop;

					if (isOffScreen(x, y, MARGIN))
					{
						if (!simulating && !isSending)
						{
							if (!isReceiving)
							{
								isSending = true;
								connections.takeControl(screenRatio,
									getMouseDirection(x, y, screenWidth, screenHeight));
							}
						}
						else if (isReceiving)
						{
							isReceiving = false;
							connections.giveControl(screenRatio,
								getMouseDirection(x, y, screenWidth, screenHeight));
						}
					}

					if (!simulating && isSending)
					{
						connections.mouseMove(dx, dy);
					}
					break;

				case WM_MOUSEWHEEL:
					if (!simulating && isSending)
					{
						connections.scrollVertical(HIWORD(llMouse.mouseData));
					}
					break;

					// horizontal wheel
				case 0x020E:
					if (!simulating && isSending)
					{
						connections.scrollHorizontal(HIWORD(llMouse.mouseData));
					}
					break;

				case WM_RBUTTONDOWN:
					if (!simulating && isSending)
					{
						connections.button(true, VK_RBUTTON);
					}
					break;

				case WM_RBUTTONUP:
					if (!simulating && isSending)
					{
						connections.button(false, VK_RBUTTON);
					}
					break;

				case WM_MBUTTONDOWN:
					if (!simulating && isSending)
					{
						connections.button(true, VK_MBUTTON);
					}
					break;

				case WM_MBUTTONUP:
					if (!simulating && isSending)
					{
						connections.button(false, VK_MBUTTON);
					}
					break;

				case WM_XBUTTONDOWN: // TODO
					break;

				case WM_XBUTTONUP: // TODO
					break;

				case WM_XBUTTONDBLCLK: // TODO?
					break;
			}

			connections.finalize();
			return isSending && nCode >= 0 ? 1 : CallNextHookEx(null, nCode, wParam, lParam);
		}

		BOOL screenRatioFromCursor(HMONITOR hMonitor, HDC hdcMonitor, LPRECT lprcMonitor, LPARAM dwData) nothrow
		{
			// If the cursor is within the bounds of this monitor...
			if ((mouse.x >= lprcMonitor.left && mouse.x < lprcMonitor.right) &&
			    (mouse.y >= lprcMonitor.top && mouse.y < lprcMonitor.bottom))
			{
				// Give the calling function the handle and stop enumeration.
				if (dwData != 0) // NULL
				{
					auto ratio = cast(Vector2!(double)*)dwData;
					const width = lprcMonitor.right - lprcMonitor.left;
					const height = lprcMonitor.bottom - lprcMonitor.top;

					auto relativeMouse = mouse;

					relativeMouse.x -= lprcMonitor.left;
					relativeMouse.y -= lprcMonitor.top;

					ratio.x = cast(double)relativeMouse.x / cast(double)width;
					ratio.y = cast(double)relativeMouse.y / cast(double)height;
				}

				return FALSE;
			}
			else
			{
				return TRUE;
			}
		}
	}

	auto getScreenRatio()
	{
		version (Windows)
		{
			return EnumDisplayMonitors(null, null, monitorCallback, cast(LPARAM)&screenRatio);
		}
		else version (Posix)
		{
			auto position = simulator.getMousePosition();
			auto dimensions = simulator.getScreenDimensions();

			screenRatio.x = cast(double)position.x / cast(double)dimensions.x;
			screenRatio.y = cast(double)position.y / cast(double)dimensions.y;
		}
		else
		{
			static assert("Platform not supported.");
		}
	}

private:
	void updateScreenMetrics() nothrow
	{
		version (Windows)
		{
			screenLeft   = GetSystemMetrics(SM_XVIRTUALSCREEN);
			screenTop    = GetSystemMetrics(SM_YVIRTUALSCREEN);
			screenWidth  = GetSystemMetrics(SM_CXVIRTUALSCREEN);
			screenHeight = GetSystemMetrics(SM_CYVIRTUALSCREEN);
		}
	}

	bool isOffScreen(int x, int y, int margin) nothrow
	{
		return ((x > (screenWidth - margin)) || (x < margin));
	}

	void pressButton(in Message message)
	{
		bool pressed = (message.type == MessageType.ButtonDown);

		if (message.button.isMouse())
		{
			simulator.pressMouseButton(message.button, pressed);
		}
		else
		{
			simulator.pressKeyboardButton(message.button, pressed);
		}
	}

	void displaySwitchCursor(in Message message)
	{
		updateScreenMetrics();

		const margin = (MARGIN + 1);

		auto x = cast(int)(screenLeft + (screenWidth - (message.mouseRatio.x * screenWidth)));
		auto y = cast(int)(screenTop + (screenHeight - (message.mouseRatio.y * screenHeight)));

		if (message.direction & Direction.Left)
		{
			x -= margin;
		}
		else
		{
			x += margin;
		}

		if (message.direction & Direction.Up)
		{
			y -= margin;
		}
		else
		{
			y += margin;
		}

		simulator.setCursorPosition(x, y, screenWidth, screenHeight);
	}

	void run()
	{
		version (Windows)
		{
			keyboardHookLL = SetWindowsHookEx(WH_KEYBOARD_LL, keyboardHook, null, 0);
			enforce(keyboardHookLL !is null, "Failed to initialize keyboard hook.");

			mouseHookLL = SetWindowsHookEx(WH_MOUSE_LL, mouseHook, null, 0);
			enforce(mouseHookLL !is null, "Failed to initialize mouse hook.");

			POINT point;
			GetCursorPos(&point);
			mouse.x = point.x;
			mouse.y = point.y;
		}

		updateScreenMetrics();

		bool quit;
		while (!quit)
		{
			// Windows message queue dispatching
			version (Windows)
			{
				// TODO: VK_PACKET
				MSG msg;

				while (PeekMessage(&msg, null, 0, 0, 1))
				{
					if (msg.message == WM_QUIT)
					{
						quit = true;
					}

					TranslateMessage(&msg);
					DispatchMessage(&msg);
				}
			}

			screenRatio.x = 0.0;
			screenRatio.y = 0.0;
			getScreenRatio();

			simulating = true;

			connections.read((ref in Message message)
			{
				switch (message.type) with (MessageType)
				{
					// A machine is taking control of this client.
					case TakeControl:
						isSending = false;
						isReceiving = true;
						displaySwitchCursor(message);
						break;

					// A machine which is under control of another is restoring
					// input to its controller.
					case GiveControl:
						isSending = false;
						displaySwitchCursor(message);
						break;

					case ButtonDown:
					case ButtonUp:
						pressButton(message);
						break;

					case MouseSet:
						simulator.setCursorPosition(message.mouse.x, message.mouse.y, screenWidth, screenHeight);
						break;

					case MouseMove:
						simulator.moveCursor(message.mouse.x, message.mouse.y);
						break;

					case ScrollVertical:
						simulator.scrollMouseWheel(message.wheel, false);
						break;

					case ScrollHorizontal:
						simulator.scrollMouseWheel(message.wheel, true);
						break;

					default:
						debug stderr.writeln("unknown message type???");
						break;
				}
			});

			simulating = false;

			super.yield();
			super.sleep(1.msecs);
		}

		simulator.destroy();

		version (Windows)
		{
			UnhookWindowsHookEx(keyboardHookLL);
			UnhookWindowsHookEx(mouseHookLL);
		}
	}
}
