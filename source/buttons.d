module buttons;

version (Windows)
{
	 import core.sys.windows.windows;
}
else version (Posix)
{
	const int XK_leftarrow                     = 0x08fb;  /* U+2190 LEFTWARDS ARROW */
	const int XK_uparrow                       = 0x08fc;  /* U+2191 UPWARDS ARROW */
	const int XK_rightarrow                    = 0x08fd;  /* U+2192 RIGHTWARDS ARROW */
	const int XK_downarrow                     = 0x08fe;  /* U+2193 DOWNWARDS ARROW */
	const int XK_3270_Duplicate                = 0xfd01;
	const int XK_3270_FieldMark                = 0xfd02;
	const int XK_3270_Right2                   = 0xfd03;
	const int XK_3270_Left2                    = 0xfd04;
	const int XK_3270_BackTab                  = 0xfd05;
	const int XK_3270_EraseEOF                 = 0xfd06;
	const int XK_3270_EraseInput               = 0xfd07;
	const int XK_3270_Reset                    = 0xfd08;
	const int XK_3270_Quit                     = 0xfd09;
	const int XK_3270_PA1                      = 0xfd0a;
	const int XK_3270_PA2                      = 0xfd0b;
	const int XK_3270_PA3                      = 0xfd0c;
	const int XK_3270_Test                     = 0xfd0d;
	const int XK_3270_Attn                     = 0xfd0e;
	const int XK_3270_CursorBlink              = 0xfd0f;
	const int XK_3270_AltCursor                = 0xfd10;
	const int XK_3270_KeyClick                 = 0xfd11;
	const int XK_3270_Jump                     = 0xfd12;
	const int XK_3270_Ident                    = 0xfd13;
	const int XK_3270_Rule                     = 0xfd14;
	const int XK_3270_Copy                     = 0xfd15;
	const int XK_3270_Play                     = 0xfd16;
	const int XK_3270_Setup                    = 0xfd17;
	const int XK_3270_Record                   = 0xfd18;
	const int XK_3270_ChangeScreen             = 0xfd19;
	const int XK_3270_DeleteWord               = 0xfd1a;
	const int XK_3270_ExSelect                 = 0xfd1b;
	const int XK_3270_CursorSelect             = 0xfd1c;
	const int XK_3270_PrintScreen              = 0xfd1d;
	const int XK_3270_Enter                    = 0xfd1e;

	import xdo;
	import x11.keysym;

	enum
	{
		VK_LBUTTON             = 0x01,
		VK_RBUTTON             = 0x02,
		VK_CANCEL              = 0x03,
		VK_MBUTTON             = 0x04,
		VK_XBUTTON1            = 0x05,
		VK_XBUTTON2            = 0x06,
		VK_BACK                = 0x08,
		VK_TAB                 = 0x09,
		VK_CLEAR               = 0x0C,
		VK_RETURN              = 0x0D,
		VK_SHIFT               = 0x10,
		VK_CONTROL             = 0x11,
		VK_MENU                = 0x12,
		VK_PAUSE               = 0x13,
		VK_CAPITAL             = 0x14,
		VK_KANA                = 0x15,
		VK_HANGEUL             = 0x15,
		VK_HANGUL              = 0x15,
		VK_JUNJA               = 0x17,
		VK_FINAL               = 0x18,
		VK_HANJA               = 0x19,
		VK_KANJI               = 0x19,
		VK_ESCAPE              = 0x1B,
		VK_CONVERT             = 0x1C,
		VK_NONCONVERT          = 0x1D,
		VK_ACCEPT              = 0x1E,
		VK_MODECHANGE          = 0x1F,
		VK_SPACE               = 0x20,
		VK_PRIOR               = 0x21,
		VK_NEXT                = 0x22,
		VK_END                 = 0x23,
		VK_HOME                = 0x24,
		VK_LEFT                = 0x25,
		VK_UP                  = 0x26,
		VK_RIGHT               = 0x27,
		VK_DOWN                = 0x28,
		VK_SELECT              = 0x29,
		VK_PRINT               = 0x2A,
		VK_EXECUTE             = 0x2B,
		VK_SNAPSHOT            = 0x2C,
		VK_INSERT              = 0x2D,
		VK_DELETE              = 0x2E,
		VK_HELP                = 0x2F,
		VK_LWIN                = 0x5B,
		VK_RWIN                = 0x5C,
		VK_APPS                = 0x5D,
		VK_SLEEP               = 0x5F,
		VK_NUMPAD0             = 0x60,
		VK_NUMPAD1             = 0x61,
		VK_NUMPAD2             = 0x62,
		VK_NUMPAD3             = 0x63,
		VK_NUMPAD4             = 0x64,
		VK_NUMPAD5             = 0x65,
		VK_NUMPAD6             = 0x66,
		VK_NUMPAD7             = 0x67,
		VK_NUMPAD8             = 0x68,
		VK_NUMPAD9             = 0x69,
		VK_MULTIPLY            = 0x6A,
		VK_ADD                 = 0x6B,
		VK_SEPARATOR           = 0x6C,
		VK_SUBTRACT            = 0x6D,
		VK_DECIMAL             = 0x6E,
		VK_DIVIDE              = 0x6F,
		VK_F1                  = 0x70,
		VK_F2                  = 0x71,
		VK_F3                  = 0x72,
		VK_F4                  = 0x73,
		VK_F5                  = 0x74,
		VK_F6                  = 0x75,
		VK_F7                  = 0x76,
		VK_F8                  = 0x77,
		VK_F9                  = 0x78,
		VK_F10                 = 0x79,
		VK_F11                 = 0x7A,
		VK_F12                 = 0x7B,
		VK_F13                 = 0x7C,
		VK_F14                 = 0x7D,
		VK_F15                 = 0x7E,
		VK_F16                 = 0x7F,
		VK_F17                 = 0x80,
		VK_F18                 = 0x81,
		VK_F19                 = 0x82,
		VK_F20                 = 0x83,
		VK_F21                 = 0x84,
		VK_F22                 = 0x85,
		VK_F23                 = 0x86,
		VK_F24                 = 0x87,
		VK_NUMLOCK             = 0x90,
		VK_SCROLL              = 0x91,
		VK_LSHIFT              = 0xA0,
		VK_RSHIFT              = 0xA1,
		VK_LCONTROL            = 0xA2,
		VK_RCONTROL            = 0xA3,
		VK_LMENU               = 0xA4,
		VK_RMENU               = 0xA5,
		VK_BROWSER_BACK        = 0xA6,
		VK_BROWSER_FORWARD     = 0xA7,
		VK_BROWSER_REFRESH     = 0xA8,
		VK_BROWSER_STOP        = 0xA9,
		VK_BROWSER_SEARCH      = 0xAA,
		VK_BROWSER_FAVORITES   = 0xAB,
		VK_BROWSER_HOME        = 0xAC,
		VK_VOLUME_MUTE         = 0xAD,
		VK_VOLUME_DOWN         = 0xAE,
		VK_VOLUME_UP           = 0xAF,
		VK_MEDIA_NEXT_TRACK    = 0xB0,
		VK_MEDIA_PREV_TRACK    = 0xB1,
		VK_MEDIA_STOP          = 0xB2,
		VK_MEDIA_PLAY_PAUSE    = 0xB3,
		VK_LAUNCH_MAIL         = 0xB4,
		VK_LAUNCH_MEDIA_SELECT = 0xB5,
		VK_LAUNCH_APP1         = 0xB6,
		VK_LAUNCH_APP2         = 0xB7,
		VK_OEM_1               = 0xBA,
		VK_OEM_PLUS            = 0xBB,
		VK_OEM_COMMA           = 0xBC,
		VK_OEM_MINUS           = 0xBD,
		VK_OEM_PERIOD          = 0xBE,
		VK_OEM_2               = 0xBF,
		VK_OEM_3               = 0xC0,
		VK_OEM_4               = 0xDB,
		VK_OEM_5               = 0xDC,
		VK_OEM_6               = 0xDD,
		VK_OEM_7               = 0xDE,
		VK_OEM_8               = 0xDF,
		VK_OEM_102             = 0xE2,
		VK_PROCESSKEY          = 0xE5,
		VK_PACKET              = 0xE7,
		VK_ATTN                = 0xF6,
		VK_CRSEL               = 0xF7,
		VK_EXSEL               = 0xF8,
		VK_EREOF               = 0xF9,
		VK_PLAY                = 0xFA,
		VK_ZOOM                = 0xFB,
		VK_NONAME              = 0xFC,
		VK_PA1                 = 0xFD,
		VK_OEM_CLEAR           = 0xFE,
	}
}

alias VirtualButton = int;

bool isMouse(VirtualButton button) nothrow
{
	switch (button)
	{
		case VK_LBUTTON, VK_RBUTTON, VK_MBUTTON, VK_XBUTTON1, VK_XBUTTON2:
			return true;

		default:
			return false;
	}
}

int toNative(VirtualButton button) nothrow
{
	version (Windows)
	{
		return button;
	}
	else version (Posix)
	{
		switch (button)
		{
			default:
				return XK_VoidSymbol;

			case 'A': .. case 'Z':
				return button;
				
			case VK_LBUTTON:
			case VK_RBUTTON:
			case VK_MBUTTON:
			case VK_XBUTTON1:
			case VK_XBUTTON2:
				return button; // TODO?

			case VK_CANCEL:
				return XK_Cancel;
			case VK_BACK:
				return XK_BackSpace;
			case VK_TAB:
				return XK_Tab;
			case VK_CLEAR:
				return XK_Clear;
			case VK_RETURN:
				return XK_Return;
			case VK_SHIFT:
				return XK_Shift_L; // TODO?
			case VK_CONTROL:
				return XK_Control_L; // TODO?
			case VK_MENU:
				return XK_Menu;
			case VK_PAUSE:
				return XK_Pause;
			case VK_CAPITAL:
				return XK_Caps_Lock;

			case VK_KANA:
				return XK_Kana_Lock; // TODO: probably wrong

			case VK_JUNJA:
			case VK_FINAL:
				return button; // TODO

			case VK_KANJI:
				return XK_Kanji;
			case VK_ESCAPE:
				return XK_Escape;
			
			case VK_CONVERT:
			case VK_NONCONVERT:
			case VK_ACCEPT:
			case VK_MODECHANGE:
				return button; // TODO

			case VK_SPACE:
				return XK_space;
			case VK_PRIOR:
				return XK_Prior;
			case VK_NEXT:
				return XK_Next;
			case VK_END:
				return XK_End;
			case VK_HOME:
				return XK_Home;
			case VK_LEFT:
				return XK_leftarrow;
			case VK_UP:
				return XK_uparrow;
			case VK_RIGHT:
				return XK_rightarrow;
			case VK_DOWN:
				return XK_downarrow;
			case VK_SELECT:
				return XK_Select;
			case VK_PRINT:
				return XK_Print;
			case VK_EXECUTE:
				return XK_Execute;
			case VK_SNAPSHOT:
				return XK_3270_PrintScreen;
			case VK_INSERT:
				return XK_Insert;
			case VK_DELETE:
				return XK_Delete;
			case VK_HELP:
				return XK_Help;
			case VK_LWIN:
				return XK_Super_L;
			case VK_RWIN:
				return XK_Super_R;
			
			case VK_APPS:
			case VK_SLEEP:
				return button; // TODO
			case VK_NUMPAD0:
				return XK_KP_0;
			case VK_NUMPAD1:
				return XK_KP_1;
			case VK_NUMPAD2:
				return XK_KP_2;
			case VK_NUMPAD3:
				return XK_KP_3;
			case VK_NUMPAD4:
				return XK_KP_4;
			case VK_NUMPAD5:
				return XK_KP_5;
			case VK_NUMPAD6:
				return XK_KP_6;
			case VK_NUMPAD7:
				return XK_KP_7;
			case VK_NUMPAD8:
				return XK_KP_8;
			case VK_NUMPAD9:
				return XK_KP_9;
			case VK_MULTIPLY:
				return XK_KP_Multiply;
			case VK_ADD:
				return XK_KP_Add;
			case VK_SEPARATOR:
				return XK_KP_Separator;
			case VK_SUBTRACT:
				return XK_KP_Subtract;
			case VK_DECIMAL:
				return XK_KP_Decimal;
			case VK_DIVIDE:
				return XK_KP_Divide;
			case VK_F1:
				return XK_F1;
			case VK_F2:
				return XK_F2;
			case VK_F3:
				return XK_F3;
			case VK_F4:
				return XK_F4;
			case VK_F5:
				return XK_F5;
			case VK_F6:
				return XK_F6;
			case VK_F7:
				return XK_F7;
			case VK_F8:
				return XK_F8;
			case VK_F9:
				return XK_F9;
			case VK_F10:
				return XK_F10;
			case VK_F11:
				return XK_F11;
			case VK_F12:
				return XK_F12;
			case VK_F13:
				return XK_F13;
			case VK_F14:
				return XK_F14;
			case VK_F15:
				return XK_F15;
			case VK_F16:
				return XK_F16;
			case VK_F17:
				return XK_F17;
			case VK_F18:
				return XK_F18;
			case VK_F19:
				return XK_F19;
			case VK_F20:
				return XK_F20;
			case VK_F21:
				return XK_F21;
			case VK_F22:
				return XK_F22;
			case VK_F23:
				return XK_F23;
			case VK_F24:
				return XK_F24;
			case VK_NUMLOCK:
				return XK_Num_Lock;
			case VK_SCROLL:
				return XK_Scroll_Lock;
			case VK_LSHIFT:
				return XK_Shift_L;
			case VK_RSHIFT:
				return XK_Shift_R;
			case VK_LCONTROL:
				return XK_Control_L;
			case VK_RCONTROL:
				return XK_Control_R;
			case VK_LMENU:
			case VK_RMENU:
				return XK_Menu; // TODO

			case VK_BROWSER_BACK:
			case VK_BROWSER_FORWARD:
			case VK_BROWSER_REFRESH:
			case VK_BROWSER_STOP:
			case VK_BROWSER_SEARCH:
			case VK_BROWSER_FAVORITES:
			case VK_BROWSER_HOME:
				return button; // TODO

			case VK_VOLUME_MUTE:
			case VK_VOLUME_DOWN:
			case VK_VOLUME_UP:
			case VK_MEDIA_NEXT_TRACK:
			case VK_MEDIA_PREV_TRACK:
			case VK_MEDIA_STOP:
			case VK_MEDIA_PLAY_PAUSE:
				return button; // TODO;
			case VK_LAUNCH_MAIL:
			case VK_LAUNCH_MEDIA_SELECT:
			case VK_LAUNCH_APP1:
			case VK_LAUNCH_APP2:
				return button; // TODO
			case VK_OEM_1:
				return XK_semicolon;
			case VK_OEM_PLUS:
				return XK_plus;
			case VK_OEM_COMMA:
				return XK_comma;
			case VK_OEM_MINUS:
				return XK_minus;
			case VK_OEM_PERIOD:
				return XK_period;
			case VK_OEM_2:
				return XK_question;
			case VK_OEM_3:
				return XK_asciitilde;
			case VK_OEM_4:
				return XK_bracketleft;
			case VK_OEM_5:
				return XK_bar;
			case VK_OEM_6:
				return XK_bracketright;
			case VK_OEM_7:
				return XK_quotedbl;
			case VK_OEM_8:
				return button;
			case VK_OEM_102:
				return XK_backslash;
			case VK_PROCESSKEY:
			case VK_PACKET:
				return button; // TODO
			case VK_ATTN:
				return XK_3270_Attn;
			case VK_CRSEL:
				return XK_3270_CursorSelect;
			case VK_EXSEL:
				return XK_3270_ExSelect;
			case VK_EREOF:
				return XK_3270_EraseEOF;
			case VK_PLAY:
				return XK_3270_Play;
			case VK_ZOOM:
				return button; // TODO
			case VK_NONAME:
				return button; // TODO
			case VK_PA1:
				return XK_3270_PA1;
			case VK_OEM_CLEAR:
				return XK_Clear;
		}
	}
	else
	{
		static assert(false, "Platform not supported.");
	}
}

VirtualButton toVirtual(int vcode) nothrow
{
	version (Windows)
	{
		return vcode;
	}
	else version (Posix)
	{
		switch (vcode)
		{
			default:
				return vcode;

			case XK_Cancel:
				return VK_CANCEL;
			case XK_BackSpace:
				return VK_BACK;
			case XK_Tab:
				return VK_TAB;
			case XK_Clear:
				return VK_CLEAR;
			case XK_Return:
				return VK_RETURN;
			case XK_Menu:
				return VK_MENU;
			case XK_Pause:
				return VK_PAUSE;
			case XK_Caps_Lock:
				return VK_CAPITAL;

			case XK_Kana_Lock:
				return VK_KANA; // TODO: probably wrong

			case XK_Kanji:
				return VK_KANJI;
			case XK_Escape:
				return VK_ESCAPE;

			case XK_space:
				return VK_SPACE;
			case XK_Prior:
				return VK_PRIOR;
			case XK_Next:
				return VK_NEXT;
			case XK_End:
				return VK_END;
			case XK_Home:
				return VK_HOME;
			case XK_leftarrow:
				return VK_LEFT;
			case XK_uparrow:
				return VK_UP;
			case XK_rightarrow:
				return VK_RIGHT;
			case XK_downarrow:
				return VK_DOWN;
			case XK_Select:
				return VK_SELECT;
			case XK_Print:
				return VK_PRINT;
			case XK_Execute:
				return VK_EXECUTE;
			case XK_3270_PrintScreen:
				return VK_SNAPSHOT;
			case XK_Insert:
				return VK_INSERT;
			case XK_Delete:
				return VK_DELETE;
			case XK_Help:
				return VK_HELP;
			case XK_Super_L:
				return VK_LWIN;
			case XK_Super_R:
				return VK_RWIN;
				
			case XK_KP_0:
				return VK_NUMPAD0;
			case XK_KP_1:
				return VK_NUMPAD1;
			case XK_KP_2:
				return VK_NUMPAD2;
			case XK_KP_3:
				return VK_NUMPAD3;
			case XK_KP_4:
				return VK_NUMPAD4;
			case XK_KP_5:
				return VK_NUMPAD5;
			case XK_KP_6:
				return VK_NUMPAD6;
			case XK_KP_7:
				return VK_NUMPAD7;
			case XK_KP_8:
				return VK_NUMPAD8;
			case XK_KP_9:
				return VK_NUMPAD9;
			case XK_KP_Multiply:
				return VK_MULTIPLY;
			case XK_KP_Add:
				return VK_ADD;
			case XK_KP_Separator:
				return VK_SEPARATOR;
			case XK_KP_Subtract:
				return VK_SUBTRACT;
			case XK_KP_Decimal:
				return VK_DECIMAL;
			case XK_KP_Divide:
				return VK_DIVIDE;
			case XK_F1:
				return VK_F1;
			case XK_F2:
				return VK_F2;
			case XK_F3:
				return VK_F3;
			case XK_F4:
				return VK_F4;
			case XK_F5:
				return VK_F5;
			case XK_F6:
				return VK_F6;
			case XK_F7:
				return VK_F7;
			case XK_F8:
				return VK_F8;
			case XK_F9:
				return VK_F9;
			case XK_F10:
				return VK_F10;
			case XK_F11:
				return VK_F11;
			case XK_F12:
				return VK_F12;
			case XK_F13:
				return VK_F13;
			case XK_F14:
				return VK_F14;
			case XK_F15:
				return VK_F15;
			case XK_F16:
				return VK_F16;
			case XK_F17:
				return VK_F17;
			case XK_F18:
				return VK_F18;
			case XK_F19:
				return VK_F19;
			case XK_F20:
				return VK_F20;
			case XK_F21:
				return VK_F21;
			case XK_F22:
				return VK_F22;
			case XK_F23:
				return VK_F23;
			case XK_F24:
				return VK_F24;
			case XK_Num_Lock:
				return VK_NUMLOCK;
			case XK_Scroll_Lock:
				return VK_SCROLL;
			case XK_Shift_L:
				return VK_LSHIFT;
			case XK_Shift_R:
				return VK_RSHIFT;
			case XK_Control_L:
				return VK_LCONTROL;
			case XK_Control_R:
				return VK_RCONTROL;
			case XK_semicolon:
				return VK_OEM_1;
			case XK_plus:
				return VK_OEM_PLUS;
			case XK_comma:
				return VK_OEM_COMMA;
			case XK_minus:
				return VK_OEM_MINUS;
			case XK_period:
				return VK_OEM_PERIOD;
			case XK_question:
				return VK_OEM_2;
			case XK_asciitilde:
				return VK_OEM_3;
			case XK_bracketleft:
				return VK_OEM_4;
			case XK_bar:
				return VK_OEM_5;
			case XK_bracketright:
				return VK_OEM_6;
			case XK_quotedbl:
				return VK_OEM_7;
			case XK_backslash:
				return VK_OEM_102;
			case XK_3270_Attn:
				return VK_ATTN;
			case XK_3270_CursorSelect:
				return VK_CRSEL;
			case XK_3270_ExSelect:
				return VK_EXSEL;
			case XK_3270_EraseEOF:
				return VK_EREOF;
			case XK_3270_Play:
				return VK_PLAY;
			case XK_3270_PA1:
				return VK_PA1;
		}

	}
	else
	{
		static assert(false, "Platform not supported.");
	}
}
