Specify which display to use and how to use it.

Syntax
      MONSWITCH /Option

Options

       /primary     Switch to use the primary display only.
       1            All other connected displays will be disabled.

       /secondary   Switch to the external display only (second screen).
       2            The current main display will be disabled.

       /clone       The primary display will be mirrored on a second screen.
       3        

       /extend      Expand the Desktop to a secondary display.
       4            This allows one desktop to span multiple displays. (Default).

Running MonSwitch.exe without any options will open a GUI.

Examples
Mirror the current Desktop on a secondary display:

C:\> MonSwitch /clone

Extend the Desktop to a secondary display:

C:\> MonSwitch 4
