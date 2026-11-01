#!/usr/bin/env pwsh
<##
 # @file install-tools.ps1
 # 
 # @brief Install the prebuilt mmd2html executable to `$HOME/.local/bin/`.
 # 
 # @details
 # 1. Ask the user to confirm the installation (y/N).
 # 2. Call `Install-Mmd2Html`, which downloads the latest Linux release package of mmd2html from GitHub, and extracts the executable into the install dir.
 # 
 # @note
 # - Only Linux x86_64 is supported, since that is the only prebuilt package.
 # - The package is saved to a temp file first, because older PowerShell versions break binary data piped between native commands.
 # - The install dir can be set by the `-install_dir` parameter, default to `$HOME/.local/bin/`.
 # - Exit code is 0 on success, and non-zero if the user declines or the installation fails.
 # 
 # @author [claude, madpang]
 # 
 # @date [created: 2026-10-30, updated: 2026-10-31]
##>

param(
	[Parameter(Position = 1)][string]$install_dir = (Join-Path -Path $HOME -ChildPath '.local/bin')
)

# === Internal functions
<##
 # @brief Download the prebuilt mmd2html package and install the executable to the given dir.
 # 
 # @param install_dir The dir to install the executable in.
 # 
 # @return The full path to the installed executable.
 # 
 # @note Throws on failure.
##>
function Install-Mmd2Html {
	param(
		[Parameter(Mandatory = $True, Position = 1)][string]$install_dir
	)

	$tool_name = 'mmd2html'
	$package_url = 'https://github.com/madpang/mmd2html/releases/latest/download/mmd2html-linux-x86_64.tar.gz'
	$tool_path = Join-Path -Path $install_dir -ChildPath $tool_name

	# --- Check the platform
	if (-not $IsLinux) {
		throw "Only Linux is supported by the prebuilt $tool_name package."
	}
	if (-not (Get-Command 'curl' -ErrorAction SilentlyContinue)) {
		throw "curl is required to download $tool_name."
	}

	# --- Download and extract the package
	if (-not (Test-Path $install_dir)) {
		New-Item -ItemType Directory -Path $install_dir | Out-Null
	}

	$path2package = [System.IO.Path]::GetTempFileName()
	try {
		curl -fsSL -o $path2package $package_url
		if ($LASTEXITCODE -ne 0) {
			throw "Failed to download $package_url"
		}
		tar -xzf $path2package -C $install_dir $tool_name
		if ($LASTEXITCODE -ne 0) {
			throw "Failed to extract $tool_name to $install_dir"
		}
	} finally {
		Remove-Item -Path $path2package -ErrorAction SilentlyContinue
	}

	# --- Verify the installation
	if (-not (Test-Path $tool_path)) {
		throw "Installation did not produce expected file: $tool_path"
	}
	return $tool_path
}

# === Ask the user to confirm
$answer = Read-Host -Prompt "Install mmd2html to ${install_dir}? [y/N]"
if ($answer -notmatch '^(y|yes)$') {
	"Installation of mmd2html skipped." | Write-Host
	exit 1
}

# === Install
try {
	$tool_path = Install-Mmd2Html -install_dir $install_dir
} catch {
	$_.Exception.Message | Write-Error
	exit -1
}

"mmd2html installed to $tool_path" | Write-Host
if (-not (($env:PATH -split [System.IO.Path]::PathSeparator) -contains $install_dir)) {
	"NOTE: $install_dir is not in your PATH." | Write-Host
}
exit 0
