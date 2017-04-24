module util;

version (Windows) import core.sys.windows.windows;

public import buttons;

enum Direction : ubyte
{
	Up    = 1 << 0,
	Down  = 1 << 1,
	Left  = 1 << 2,
	Right = 1 << 3
}

struct Vector2(T = float)
{
	T x, y;
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

version (Windows)
{
	void setMousePosition(int x, int y, bool absolute) nothrow
	{
		INPUT input;
		
		if (absolute)
		{
			input.mi.dwFlags |= MOUSEEVENTF_ABSOLUTE;
		}

		input.type       = INPUT_MOUSE;
		input.mi.dx      = x;
		input.mi.dy      = y;
		input.mi.dwFlags |= MOUSEEVENTF_MOVE;

		SendInput(1, &input, input.sizeof);
	}

	void pressMouseButton(VirtualButton button, bool down) nothrow
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

	void pressKeyboardButton(VirtualButton button, bool down) nothrow
	{
		INPUT input;
	
		auto nativeKey = button.toNative();
		input.type     = INPUT_KEYBOARD;
		input.ki.wScan = cast(WORD)MapVirtualKey(nativeKey, MAPVK_VK_TO_VSC);

		input.ki.dwFlags = KEYEVENTF_SCANCODE;

		if ((nativeKey > 32 && nativeKey < 47) || (nativeKey > 90 && nativeKey < 94))
			input.ki.dwFlags |= KEYEVENTF_EXTENDEDKEY;

		if (!down)
		{
			input.ki.dwFlags |= KEYEVENTF_KEYUP; // 0 indicates pressed
		}
	
		SendInput(1, &input, input.sizeof);
	}
}
else version (Linux)
{
	static assert(false, "Nope.");
}
else
{
	static assert(false, "Platform not yet supported.");
}
