[CmdletBinding()]
param($Interval = (Get-Random -Minimum 2950 -Maximum 4250), [switch]$RightClick, [switch]$NoMove)
 
[Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
$DebugViewWindow_TypeDef = @'
[DllImport("user32.dll")]
public static extern IntPtr FindWindow(string ClassName, string Title);
[DllImport("user32.dll")]
public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll")]
public static extern bool SetCursorPos(int X, int Y);
[DllImport("user32.dll")]
public static extern bool GetCursorPos(out System.Drawing.Point pt);
 
[DllImport("user32.dll", CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall)]
public static extern void mouse_event(long dwFlags, long dx, long dy, long cButtons, long dwExtraInfo);
 
private const int MOUSEEVENTF_LEFTDOWN = 0x02;
private const int MOUSEEVENTF_LEFTUP = 0x04;
private const int MOUSEEVENTF_RIGHTDOWN = 0x08;
private const int MOUSEEVENTF_RIGHTUP = 0x10;
 
public static void LeftClick(){
    mouse_event(MOUSEEVENTF_LEFTDOWN | MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
}
 
public static void RightClick(){
    mouse_event(MOUSEEVENTF_RIGHTDOWN | MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0);
}
'@

Add-Type -MemberDefinition $DebugViewWindow_TypeDef -Namespace AutoClicker -Name Temp -ReferencedAssemblies System.Drawing

Add-Type -AssemblyName System.Windows.Forms
 
$pt = New-Object System.Drawing.Point

if ([AutoClicker.Temp]::GetCursorPos([ref]$pt)) {
    Write-host "Clicking at $($pt.X), $($pt.Y) every ${Interval}ms until Ctrl^C" -NoNewline
    $InitialX = $pt.X
    $IntiialY = $pt.Y
    while($true) {
        $X = [System.Windows.Forms.Cursor]::Position.X
        $Y = [System.Windows.Forms.Cursor]::Position.Y
        $pt.X = Get-Random -Minimum ($InitialX - 1) -Maximum ($InitialX + 1)
        $pt.Y = Get-Random -Minimum ($IntiialY - 1) -Maximum ($IntiialY + 1)
        $start = [AutoClicker.Temp]::FindWindow("ImmersiveLauncher", "Start menu")
        $fg = [AutoClicker.Temp]::GetForegroundWindow()
 
        if ($start -eq $fg) { 
            Write-Host "Start opened. Exiting"
            return 
        }
 
        if (!$NoMove) {
            [AutoClicker.Temp]::SetCursorPos($pt.X, $pt.Y) | Out-Null
        }
 
        if ($RightClick) {
            [AutoClicker.Temp]::RightClick()
        } else {    
            Write-Host $pt.X
            Write-Host $pt.Y
            [AutoClicker.Temp]::LeftClick()
            [Windows.Forms.Cursor]::Position = "$($X),$($Y)"
        }
        sleep -Milliseconds $Interval
    }
}
