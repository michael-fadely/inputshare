module simulator;

version (Windows)
{
	import core.sys.windows.windows;
}
else version (Posix)
{
	import xdo;
}

public import buttons;
public import vector;

enum Direction : ubyte
{
	Up    = 1 << 0,
	Down  = 1 << 1,
	Left  = 1 << 2,
	Right = 1 << 3
}

Direction getMouseDirection(int x, int y, int width, int height)
{
	Direction result;
	
	if (x > (width / 2))
	{
		result |= Direction.Right;
	}
	else
	{
		result |= Direction.Left;
	}

	if (y > (height / 2))
	{
		result |= Direction.Down;
	}
	else
	{
		result |= Direction.Up;
	}

	return result;
}


class Simulator
{
	version (Posix) xdo_t* handle;

public:
	version (Posix)
	{
		this()
		{
			handle = xdo_new(null);
		}
		~this()
		{
			xdo_free(handle);
		}
	}

	version (Posix)
	{
		Vector2!int getMousePosition()
		{
			Vector2!int result;
			int screen_num;
			xdo_get_mouse_location(handle, &result.x, &result.y, &screen_num);
			return result;
		}

		Vector2!uint getScreenDimensions()
		{
			Vector2!int cursor;
			int screen_num;
			xdo_get_mouse_location(handle, &cursor.x, &cursor.y, &screen_num);

			Vector2!uint result;
			xdo_get_viewport_dimensions(handle, &result.x, &result.y, screen_num);
			return result;
		}
	}

	void moveCursor(int dx, int dy)
	{
		version (Windows)
		{
			INPUT input;

			input.type       = INPUT_MOUSE;
			input.mi.dwFlags = MOUSEEVENTF_MOVE;
			input.mi.dx      = dx;
			input.mi.dy      = dy;

			SendInput(1, &input, input.sizeof);
		}
		else version (Posix)
		{
			xdo_move_mouse_relative(handle, dx, dy);
		}
		else
		{
			static assert(false, "Platform not supported.");
		}
	}

	void setCursorPosition(int x, int y, int width, int height) nothrow
	{
		version (Windows)
		{
			INPUT input;
		
			input.type       = INPUT_MOUSE;
			input.mi.dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE;
			input.mi.dx      = cast(LONG)(ushort.max * (x / cast(double)width));
			input.mi.dy      = cast(LONG)(ushort.max * (y / cast(double)height));

			SendInput(1, &input, input.sizeof);
		}
		else version (Posix)
		{
			xdo_move_mouse(handle, x, y, /* TODO: screen number? */ 0);
		}
		else
		{
			static assert(false, "Platform not supported.");
		}
	}

	void pressMouseButton(VirtualButton button, bool down) nothrow
	{
		version (Windows)
		{
			INPUT input;

			with (input)
			{
				type = INPUT_MOUSE;

				switch (button)
				{
					case VK_LBUTTON:
						mi.dwFlags = (down ? MOUSEEVENTF_LEFTDOWN : MOUSEEVENTF_LEFTUP);
						break;

					case VK_RBUTTON:
						mi.dwFlags = (down ? MOUSEEVENTF_RIGHTDOWN : MOUSEEVENTF_RIGHTUP);
						break;

					case VK_MBUTTON:
						mi.dwFlags = (down ? MOUSEEVENTF_MIDDLEDOWN : MOUSEEVENTF_MIDDLEUP);
						break;

					case VK_XBUTTON1:
						mi.dwFlags = (down ? MOUSEEVENTF_XDOWN : MOUSEEVENTF_XUP);
						mi.mouseData = XBUTTON1;
						break;

					case VK_XBUTTON2:
						mi.dwFlags = (down ? MOUSEEVENTF_XDOWN : MOUSEEVENTF_XUP);
						mi.mouseData = XBUTTON2;
						break;

					default: // TODO
						break;
				}
			}

			SendInput(1, &input, input.sizeof);
		}
		else version (Posix)
		{
			// apparently mouse "button" 4 and 5 are scroll up and down ???
			int mouseButton;

			switch (mouseButton)
			{
				default:
				case VK_LBUTTON:
					mouseButton = 1;
					break;

				case VK_MBUTTON:
					mouseButton = 2;
					break;

				case VK_RBUTTON:
					mouseButton = 3;
					break;
			}

			if (down)
			{
				xdo_mouse_down(handle, CURRENTWINDOW, mouseButton);
			}
			else
			{
				xdo_mouse_up(handle, CURRENTWINDOW, mouseButton);
			}
		}
		else
		{
			static assert(false, "Platform not supported.");
		}
	}

	void scrollMouseWheel(short amount, bool horizontal) nothrow
	{
		version (Windows)
		{
			INPUT input;

			input.type         = INPUT_MOUSE;
			input.mi.dwFlags   = horizontal ? /*MOUSEEVENTF_HWHEEL*/ 0x1000 : MOUSEEVENTF_WHEEL;
			input.mi.mouseData = amount;

			SendInput(1, &input, input.sizeof);
		}
		else version (Posix)
		{
			xdo_click_window_multiple(handle, CURRENTWINDOW, horizontal ? 5 : 4, cast(int)amount, 0);
		}
		else
		{
			static assert(false, "Platform not supported.");
		}
	}

	void pressKeyboardButton(VirtualButton button, bool down) nothrow
	{
		version (Windows)
		{
			INPUT input;

			auto nativeKey = button.toNative();

			input.type       = INPUT_KEYBOARD;
			input.ki.wScan   = cast(WORD)MapVirtualKey(nativeKey, MAPVK_VK_TO_VSC);
			input.ki.dwFlags = KEYEVENTF_SCANCODE;

			if ((nativeKey > 32 && nativeKey < 47) || (nativeKey > 90 && nativeKey < 94))
			{
				input.ki.dwFlags |= KEYEVENTF_EXTENDEDKEY;
			}

			if (!down)
			{
				input.ki.dwFlags |= KEYEVENTF_KEYUP; // 0 indicates pressed
			}

			SendInput(1, &input, input.sizeof);
		}
		else version (Posix)
		{
			// TODO !!!
			//static assert(false, "TODO");
		}
		else
		{
			static assert(false, "Platform not supported.");
		}
	}
}
