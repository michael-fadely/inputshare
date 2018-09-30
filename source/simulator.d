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

			switch (button)
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

	version (Posix) static string xdoBullshit(int posixButton)
	{
		import buttons;
		import x11.keysym;
		import std.conv : to;

		switch (posixButton)
		{
			default: return null;

			case 'A': .. case 'Z':
			case 'a': .. case 'z':
				import std.string;
				string str = [ cast(const char)posixButton ];
				return toLower(str);

			case '0': .. case '9':
				return to!string(posixButton);

			case XK_3270_Attn:         return "Attn";
			case XK_3270_CursorSelect: return "CursorSelect";
			case XK_3270_EraseEOF:     return "EraseEOF";
			case XK_3270_ExSelect:     return "ExSelect";
			case XK_3270_PA1:          return "PA1";
			case XK_3270_Play:         return "Play";
			case XK_3270_PrintScreen:  return "PrintScreen";
			case XK_asciitilde:        return "asciitilde";
			case XK_backslash:         return "backslash";
			case XK_BackSpace:         return "BackSpace";
			case XK_bar:               return "bar";
			case XK_bracketleft:       return "bracketleft";
			case XK_bracketright:      return "bracketright";
			case XK_Cancel:            return "Cancel";
			case XK_Caps_Lock:         return "Caps_Lock";
			case XK_Clear:             return "Clear";
			case XK_comma:             return "comma";
			case XK_Control_L:         return "Control_L";
			case XK_Control_R:         return "Control_R";
			case XK_Delete:            return "Delete";
			case XK_downarrow:         return "downarrow";
			case XK_End:               return "End";
			case XK_Escape:            return "Escape";
			case XK_Execute:           return "Execute";
			case XK_F1:                return "F1";
			case XK_F10:               return "F10";
			case XK_F11:               return "F11";
			case XK_F12:               return "F12";
			case XK_F13:               return "F13";
			case XK_F14:               return "F14";
			case XK_F15:               return "F15";
			case XK_F16:               return "F16";
			case XK_F17:               return "F17";
			case XK_F18:               return "F18";
			case XK_F19:               return "F19";
			case XK_F2:                return "F2";
			case XK_F20:               return "F20";
			case XK_F21:               return "F21";
			case XK_F22:               return "F22";
			case XK_F23:               return "F23";
			case XK_F24:               return "F24";
			case XK_F3:                return "F3";
			case XK_F4:                return "F4";
			case XK_F5:                return "F5";
			case XK_F6:                return "F6";
			case XK_F7:                return "F7";
			case XK_F8:                return "F8";
			case XK_F9:                return "F9";
			case XK_Help:              return "Help";
			case XK_Home:              return "Home";
			case XK_Insert:            return "Insert";
			case XK_Kana_Lock:         return "Kana_Lock";
			case XK_Kanji:             return "Kanji";
			case XK_KP_0:              return "KP_0";
			case XK_KP_1:              return "KP_1";
			case XK_KP_2:              return "KP_2";
			case XK_KP_3:              return "KP_3";
			case XK_KP_4:              return "KP_4";
			case XK_KP_5:              return "KP_5";
			case XK_KP_6:              return "KP_6";
			case XK_KP_7:              return "KP_7";
			case XK_KP_8:              return "KP_8";
			case XK_KP_9:              return "KP_9";
			case XK_KP_Add:            return "KP_Add";
			case XK_KP_Decimal:        return "KP_Decimal";
			case XK_KP_Divide:         return "KP_Divide";
			case XK_KP_Multiply:       return "KP_Multiply";
			case XK_KP_Separator:      return "KP_Separator";
			case XK_KP_Subtract:       return "KP_Subtract";
			case XK_leftarrow:         return "leftarrow";
			case XK_Menu:              return "Menu";
			case XK_minus:             return "minus";
			case XK_Next:              return "Next";
			case XK_Num_Lock:          return "Num_Lock";
			case XK_Pause:             return "Pause";
			case XK_period:            return "period";
			case XK_plus:              return "plus";
			case XK_Print:             return "Print";
			case XK_Prior:             return "Prior";
			case XK_question:          return "question";
			case XK_quotedbl:          return "quotedbl";
			case XK_rightarrow:        return "rightarrow";
			case XK_Scroll_Lock:       return "Scroll_Lock";
			case XK_Select:            return "Select";
			case XK_semicolon:         return "semicolon";
			case XK_Shift_L:           return "Shift_L";
			case XK_Shift_R:           return "Shift_R";
			case XK_space:             return "space";
			case XK_Super_L:           return "Super_L";
			case XK_Super_R:           return "Super_R";
			case XK_Tab:               return "Tab";
			case XK_uparrow:           return "uparrow";
		}
	}

	void pressKeyboardButton(VirtualButton button, bool down)
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
			import std.string;
			auto bullshit = xdoBullshit(toNative(button));
			auto superBullshit = bullshit.toStringz();

			import std.stdio : stdout;
			try
			{
				stdout.writeln("pressing: ", bullshit);
			}
			catch (Exception) {}

			if (down)
			{
				xdo_send_keysequence_window_down(handle, CURRENTWINDOW, superBullshit, 1);
			}
			else
			{
				xdo_send_keysequence_window_up(handle, CURRENTWINDOW, superBullshit, 1);
			}
		}
		else
		{
			static assert(false, "Platform not supported.");
		}
	}
}
