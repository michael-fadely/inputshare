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
	bool forwardInput;
	bool simulating;
	int screenLeft, screenTop, screenWidth, screenHeight;

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

		Vector2!int mouse;
	}

public:
	this(Connections connections, KeyboardHook keyboardHook, MouseHook mouseHook,
			MonitorCallback monitorCallback)
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
						if (forwardInput)
						{
							connections.button(true, fromNative(keyboard.vkCode));
						}
						break;

					case WM_KEYUP:
						if (forwardInput)
						{
							connections.button(false, fromNative(keyboard.vkCode));
						}
						break;

					case WM_SYSKEYDOWN:
						if (forwardInput)
						{
							connections.button(true, fromNative(keyboard.vkCode));
						}
						break;

					case WM_SYSKEYUP:
						if (forwardInput)
						{
							connections.button(false, fromNative(keyboard.vkCode));
						}
						break;
				}

				connections.finalize();
			}
			catch (Exception ex)
			{
				try
				{
					//stderr.writeln(ex.msg);
				}
				catch (Exception)
				{
					// ignored
				}
			}

			if (nCode < 0)
			{
				return CallNextHookEx(null, nCode, wParam, lParam);
			}

			return forwardInput ? 1 : 0;
		}

		LRESULT runMouseHook(int nCode, WPARAM wParam, LPARAM lParam) nothrow
		{
			try
			{
				if (simulating || connections.count == 0)
				{
					return CallNextHookEx(null, nCode, wParam, lParam);
				}

				//auto llMouse = cast(MSLLHOOKSTRUCT*)lParam;

				switch (wParam)
				{
					default:
						break;

					case WM_LBUTTONDOWN:
						if (forwardInput)
						{
							connections.button(true, VK_LBUTTON);
						}
						break;

					case WM_LBUTTONUP:
						if (forwardInput)
						{
							connections.button(false, VK_LBUTTON);
						}
						break;

					case WM_MOUSEMOVE:
						POINT p;
						GetCursorPos(&p);

						auto x = p.x;
						auto y = p.y;
						auto dx = mouse.x - x;
						auto dy = mouse.y - y;

						mouse.x = x;
						mouse.y = y;

						x -= screenLeft;
						y -= screenTop;

						if (!forwardInput && isOffScreen(x, y, MARGIN))
						{
							forwardInput = true;

							Vector2!double ratio;
							ratio.x = 0.0;
							ratio.y = 0.0;

							getScreenRatio(ratio);
							connections.giveControl(ratio, getMouseDirection(x, y,
									screenWidth, screenHeight));
						}

						if (forwardInput)
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
						if (forwardInput)
						{
							connections.button(true, VK_RBUTTON);
						}
						break;

					case WM_RBUTTONUP:
						if (forwardInput)
						{
							connections.button(false, VK_RBUTTON);
						}
						break;

					case WM_MBUTTONDOWN:
						if (forwardInput)
						{
							connections.button(true, VK_MBUTTON);
						}
						break;

					case WM_MBUTTONUP:
						if (forwardInput)
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
			}
			catch (Exception ex)
			{
				// ignored
			}

			if (nCode < 0)
			{
				return CallNextHookEx(null, nCode, wParam, lParam);
			}

			return forwardInput ? 1 : 0;
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

		auto getScreenRatio(ref Vector2!double thing)
		{
			return EnumDisplayMonitors(null, null, monitorCallback, cast(LPARAM)&thing);
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
		return ((x > (screenWidth - margin)) || (x < margin)); // return ((x > (screenWidth - margin)) || (x < margin)) || ((y > (screenHeight - margin)) || (y < margin));
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

			updateScreenMetrics();

			bool quit;
			MSG msg;

			while (!quit)
			{
				simulating = false;

				// TODO: VK_PACKET
				if (PeekMessage(&msg, null, 0, 0, 0))
				{
					for (int result = GetMessage(&msg, null, 0, 0); result != 0; result = GetMessage(&msg,
							null, 0, 0))
					{
						if (msg.message == WM_QUIT)
						{
							quit = true;
						}

						TranslateMessage(&msg);
						DispatchMessage(&msg);
					}
				}

				simulating = true;

				foreach (Message message; connections.read())
				{
					switch (message.type) with (MessageType)
					{
						case GiveControl:
							forwardInput = false;
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
							continue;
					}
				}

				yield();
				sleep(1.msecs);
			}

			UnhookWindowsHookEx(keyboardHookLL);
			UnhookWindowsHookEx(mouseHookLL);
		}
	}
}
