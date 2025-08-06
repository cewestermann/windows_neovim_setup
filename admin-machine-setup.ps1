$ErrorActionPreference = "Stop"

# Ensure that we are in Administrator mode
function Assert-Admin {
	$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).
		IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
	if (-not $isAdmin) { throw "Please run script in an **elevated** PowerShell." } 
} 

Assert-Admin

# Ensure winget exists
try { winget --version | Out-Null } catch {
	throw "winget is required."
} 

# Silently accept agreements
$common = $("--silent","--accept-package-agreements","--accept-source-agreements", "-e")


winget install Neovim.Neovim --scope machine @common
# We manually add to path, so lets override that
winget install LLVM.LLVM --scope machine @common --override "ADD_TO_PATH=0"


$llvm_bin = "C:\Program Files\LLVM\bin"
if (-not (Test-Path (Join-Path $llvm_bin "clang.exe"))) {
	throw "clang.exe not found at '$llvm_bin'. Verify LLVM installed correctly."
} 

# Add clang to path
$machine_path = [Environment]::GetEnvironmentVariable("Path","Machine")
if ($machine_path -notlike "*$llvm_bin*") {
	[Environment]::SetEnvironmentVariable("Path", ($machine_path.TrimEnd(';') + ";" + $llvm_bin), "Machine")
} 

# Notifiy running apps that environment variables have changed
$code = @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
	[DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
	public static extern IntPtr SendMessageTimeout(IntPtr hWnd, int Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
} 
"@

Add-Type $code -ErrorAction SilentlyContinue | Out-Null
[UIntPtr]$result = [UIntPtr]::Zero
try { [void][Win32]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]0, "Environment", 2, 5000, [ref]$result) } catch {}

Write-Host "`nDone. Open a **new** terminal and run: clang --version" -ForegroundColor Green 


