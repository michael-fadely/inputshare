module buttons;

version (Windows) import core.sys.windows.windows;
else version (Linux)
{

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
}

VirtualButton fromNative(int vcode) nothrow
{
	version (Windows)
	{
		return vcode;
	}
}
