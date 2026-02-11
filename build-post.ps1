#! /usr/bin/env pwsh -NoProfile
<#
	@file: pd-phronesis/build-post.ps1
	
	@brief: Build a single HTML post from the manuscript.

	@details:
	1. Read the template HTML file.
	2. Use the mmd2html tool to convert the source text to HTML, and insert it into the anchor point in the template.
	3. Write the output to the target HTML file.

	@note:
	- The template file path is hardcoded, since it is part of the framework.
	- In step [2], the mmd2html need a temporary output file to store the converted HTML content, which will be read back to insert into the template.
	- The temporary file will be placed alongside the target HTML file, with a ".tmp" suffix.
	- This script assumes path arguments do not contain spaces.
	- It is better to work with absolute paths.

	@author: madpang

	@date: [created: 2025-05-18, updated: 2026-02-11]
#>

param(
	[Parameter(Mandatory = $True, Position = 1)][string]$path2html,     # @output
	[Parameter(Mandatory = $True, Position = 2)][string]$path2txt       # @input
)

$is_debug = $false

# === Verify the tool path exists
$script_root = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$tool_path = Join-Path -Path $script_root -ChildPath 'tools/mmd2html/app/build/libs/mmd2html.jar'
if (-not (Test-Path $tool_path)) {
	@("HTML conversion tool not found.", "Expected converter path: $tool_path", "Make sure submodule is initialized.") -join [Environment]::NewLine | Write-Error
	exit -1
}

# === Verify the template file exists
$path2template = Join-Path -Path $script_root -ChildPath 'templates/post-template.html'
if (-not (Test-Path $path2template)) {
	"Template file not found: $path2template" | Write-Error
	exit -3
}

# === Convert the source text to HTML

# --- Create the containing folder of the HTML post if it does not exist
$post_dir = Split-Path -Path $path2html -Parent
if (-not (Test-Path $post_dir)) {
	try {
		New-Item -ItemType Directory -Path $post_dir | Out-Null
	} catch {
		"Failed to create output directory: $post_dir" | Write-Error
		exit -4
	}
}

# --- Prepare temporary output file path
$path2converted = $path2html + ".tmp";

$cmd = @('java', '-jar', $tool_path, $path2txt, $path2converted) -join ' '

if ($is_debug) {
	@("[DEBUG] Converting source text to HTML:", "> $cmd") -join [Environment]::NewLine | Write-Host
}

# --- Invoke the conversion command
Invoke-Expression $cmd

$tool_exit_code = $LASTEXITCODE
if ($tool_exit_code -ne 0) {
	"Conversion failed with exit code $tool_exit_code." | Write-Error
	exit $tool_exit_code
}

if (-not (Test-Path $path2converted)) {
	"Conversion did not generate expected output file: $path2converted" | Write-Error
	exit -2
}

# === Assemble the final HTML file

$formatted_lines = Get-Content -Path $path2converted -Encoding utf8

# --- Extract h1 heading (for display in the web browser tab)
$browser_tab_title = $null
foreach ($line in $formatted_lines) {
	if ($line -match '<h1>(.*)</h1>') {
		$browser_tab_title = $Matches[1]
		break
	}
}

if (-not $browser_tab_title) {
	"Article must have a title." | Write-Error
	exit -10
}

# --- Read the template HTML file
$template_lines = Get-Content -Path $path2template -Encoding utf8

# --- Assemble the output HTML file
$author_info = "MadPang"
$is_in_blk_comment = $false
$output_lines = @()
for ($ii = 0; $ii -lt $template_lines.Count; $ii++) {
	$line = $template_lines[$ii]
	# Check if the line is a block comment start, assuming only world character, `@`, and `:` are allowed
	if ($line -match '^<!--\s*(?<id>[@:\w]+)\s*$') {
		$is_in_blk_comment = $true
		$id = $Matches['id']
		if ($id -eq '@ANCHOR:NULL') {
			$output_lines += '<!-- @note: This file is auto-generated. MANUAL EDITS WILL BE LOST -->'
		}
		continue
	}
	if ($line -match '^-->$') {
		$is_in_blk_comment = $false
		continue
	}
	if ($is_in_blk_comment) {
		# Skip the block comment
		continue
	}
	if ($line -match '^<!--\s*@ANCHOR:TITLE\s*-->$') {
		# Insert the title text into the anchor point
		$output_lines += "$browser_tab_title | $author_info"
		continue
	}
	if ($line -match "^<!--\s*@ANCHOR:ARTICLE\s*-->$") {
		# Insert the formatted lines into the anchor point
		$output_lines += $formatted_lines
		continue
	}

	# Add normal line to the output
	$output_lines += $line
}

# === Cleanup temporary files
if (Test-Path $path2converted) {
	if ($is_debug) {
		Write-Host "[DEBUG] Cleaning up temporary file: $path2converted"
	}
	Remove-Item -Path $path2converted
}

# === Write the output to HTML file
try {
	if ($is_debug) {
		"[DEBUG] Writing output HTML file: $path2html" | Write-Host
	}	
	Set-Content -Path $path2html -Value $output_lines -Encoding utf8
	exit 0
} catch {
	"Failed to write output file: $path2html" | Write-Error
	exit -5
}
