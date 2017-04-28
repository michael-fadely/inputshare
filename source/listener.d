module listener;

import core.thread;
import core.time;
import std.exception;
import std.math;

debug import std.stdio;

import buttons;
import connection;
import util;

/// Number of pixels from the screen edge before forwarding input.
enum MARGIN = 8;

version (Windows) import core.sys.windows.windows;

class Listener : Thread
{
private:
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
	this(Connections connections, KeyboardHook keyboardHook, MouseHook mouseHook, MonitorCallback monitorCallback)
	{
		super(&run);

		this.connections     = connections;
		this.keyboardHook    = keyboardHook;
		this.mouseHook       = mouseHook;
		this.monitorCallback = monitorCallback;
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
		LRESULT runKeyboardHook(int nCode, WPARAM wParam, LPARAM lParam) nothrow
		{
			try
			{
				if (simulating || connections.count == 0)
				{
					return CallNextHookEx(null, nCode, wParam, lParam);
				}

				auto keyboard = cast(KBDLLHOOKSTRUCT*)lParam;

				switch (wParam)
				{
					default:
						break;

					case WM_KEYDOWN:
						if (isSending)
						{
							connections.button(true, fromNative(keyboard.vkCode));
						}
						break;

					case WM_KEYUP:
						if (isSending)
						{
							connections.button(false, fromNative(keyboard.vkCode));
						}
						break;

					case WM_SYSKEYDOWN:
						if (isSending)
						{
							connections.button(true, fromNative(keyboard.vkCode));
						}
						break;

					case WM_SYSKEYUP:
						if (isSending)
						{
							connections.button(false, fromNative(keyboard.vkCode));
						}
						break;
				}
			}
			catch (Exception ex)
			{
				debug
				{
					try
					{
						stderr.writeln(ex.msg);
					}
					catch (Exception)
					{
						// ignored
					}
				}

				return CallNextHookEx(null, nCode, wParam, lParam);
			}

			return isSending && nCode >= 0 ? 1 : CallNextHookEx(null, nCode, wParam, lParam);
		}

		LRESULT runMouseHook(int nCode, WPARAM wParam, LPARAM lParam) nothrow
		{
			try
			{
				if (connections.count == 0)
				{
					return CallNextHookEx(null, nCode, wParam, lParam);
				}

				auto llMouse = cast(MSLLHOOKSTRUCT*)lParam;

				switch (wParam)
				{
					default:
						break;

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
						POINT p = llMouse.pt;

						auto x = llMouse.pt.x;
						auto y = llMouse.pt.y;
						auto dx = x - mouse.x;
						auto dy = y - mouse.y;

						if (!simulating)
						{
							POINT pt;
							GetCursorPos(&pt);

							mouse.x = pt.x;
							mouse.y = pt.y;
						}

						x -= screenLeft;
						y -= screenTop;

						if (isOffScreen(x, y, MARGIN))
						{
							if (!simulating && !isSending)
							{
								if (!isReceiving)
								{
									//debug stdout.writeln("taking");
									isSending = true;
									connections.takeControl(screenRatio,
										getMouseDirection(x, y, screenWidth, screenHeight));
								}
							}
							else if (isReceiving)
							{
								//debug stdout.writeln("giving");
								connections.giveControl(screenRatio,
									getMouseDirection(x, y, screenWidth, screenHeight));

								isReceiving = false;
							}
						}

						if (!simulating && isSending)
						{
							connections.mouseMove(dx, dy);
						}
						break;

					case WM_MOUSEWHEEL: // TODO
						break;

						// horizontal wheel
					case 0x020E: // TODO
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
			}
			catch (Exception ex)
			{
				debug
				{
					try
					{
						stderr.writeln(ex.msg);
					}
					catch (Exception)
					{
						// ignored
					}
				}

				return CallNextHookEx(null, nCode, wParam, lParam);
			}

			return isSending && nCode >= 0 ? 1 : CallNextHookEx(null, nCode, wParam, lParam);
		}

		BOOL screenRatioFromCursor(HMONITOR hMonitor, HDC hdcMonitor, LPRECT lprcMonitor, LPARAM dwData) nothrow
		{
			// If the cursor is within the bounds of this monitor...
			if ((mouse.x >= lprcMonitor.left && mouse.x < lprcMonitor.right)
					&& (mouse.y >= lprcMonitor.top && mouse.y < lprcMonitor.bottom))
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

		auto getScreenRatio()
		{
			return EnumDisplayMonitors(null, null, monitorCallback, cast(LPARAM)&screenRatio);
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

	void pressButton(in Message message) nothrow
	{
		bool pressed = (message.type == MessageType.ButtonDown);

		if (message.button.isMouse())
		{
			pressMouseButton(message.button, pressed);
		}
		else
		{
			pressKeyboardButton(message.button, pressed);
		}
	}

	private void displaySwitchCursor(in Message message)
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

		setMousePosition(x, y, true);
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
			simulating = false;

			// Windows message queue dispatching
			version (Windows)
			{
				// TODO: VK_PACKET
				MSG msg;
				if (PeekMessage(&msg, null, 0, 0, 0))
				{
					int result;
					while ((result = GetMessage(&msg, null, 0, 0)) != 0)
					{
						if (msg.message == WM_QUIT)
						{
							quit = true;
						}

						TranslateMessage(&msg);
						DispatchMessage(&msg);
						connections.finalize();
					}
				}
			}

			connections.finalize();
			simulating = true;

			screenRatio.x = 0.0;
			screenRatio.y = 0.0;
			getScreenRatio();

			foreach (Message message; connections.read())
			{
				switch (message.type) with (MessageType)
				{
					// A machine is taking control of this client.
					case TakeControl:
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
						setMousePosition(message.mouse.x, message.mouse.y, true);
						break;

					case MouseMove:
						setMousePosition(message.mouse.x, message.mouse.y, false);
						break;

					default:
						debug stderr.writeln("unknown message type???");
						break;
				}
			}

			yield();
			sleep(1.msecs);
		}

		version (Windows)
		{
			UnhookWindowsHookEx(keyboardHookLL);
			UnhookWindowsHookEx(mouseHookLL);
		}
	}
}
