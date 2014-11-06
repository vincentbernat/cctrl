; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{86DDE49A-CB27-4B64-A816-887A13C06D58}
AppName=cnh
AppVerName=cnh-1.14.0
AppPublisher=cloudControl GmbH
AppPublisherURL=https://www.cloudcontrol.com
AppSupportURL=https://www.cloudcontrol.com
AppUpdatesURL=https://www.cloudcontrol.com
DefaultDirName={pf}\cnh
DefaultGroupName=cnh
AllowNoIcons=yes
SourceDir=..\
OutputDir=win32setup
OutputBaseFilename=cnh-1.14.0-setup
Compression=lzma
SolidCompression=yes
ChangesEnvironment=yes
InfoAfterFile=win32\readme.txt

[Tasks]
Name: modifypath; Description: &Add application directory to your system path;

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "dist\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\{cm:ProgramOnTheWeb,control}"; Filename: "https://www.cloudcontrol.com"
Name: "{group}\{cm:UninstallProgram,control}"; Filename: "{uninstallexe}"

[Code]
function ModPathDir(): TArrayOfString;
var
  Dir:	TArrayOfString;
begin
  setArrayLength(Dir, 1)
  Dir[0] := ExpandConstant('{app}');
  Result := Dir;
end;

// ----------------------------------------------------------------------------
//
// Inno Setup Ver:  5.3.9
// Script Version:  1.3.2
// Author:          Jared Breland <jbreland@legroom.net>
// Homepage:		http://www.legroom.net/software
//
// Script Function:
//	Enable modification of system path directly from Inno Setup installers
//
// Instructions:
//	Copy modpath.iss to the same directory as your setup script
//
//	Add this statement to your [Setup] section
//		ChangesEnvironment=yes
//
//	Add this statement to your [Tasks] section
//	You can change the Description or Flags, but the Name must be modifypath
//		Name: modifypath; Description: &Add application directory to your system path; Flags: unchecked
//
//	Add the following to the end of your [Code] section
//	setArrayLength must specify the total number of dirs to be added
//	Dir[0] contains first directory, Dir[1] contains second, etc.
//		function ModPathDir(): TArrayOfString;
//		var
//			Dir:	TArrayOfString;
//		begin
//			setArrayLength(Dir, 1)
//			Dir[0] := ExpandConstant('{app}');
//			Result := Dir;
//		end;
//		#include "modpath.iss"
// ----------------------------------------------------------------------------

procedure ModPath();
var
	oldpath:	String;
	newpath:	String;
	pathArr:	TArrayOfString;
	aExecFile:	String;
	aExecArr:	TArrayOfString;
	i, d:		Integer;
	pathdir:	TArrayOfString;
begin

	// Get array of new directories and act on each individually
	pathdir := ModPathDir();
	for d := 0 to GetArrayLength(pathdir)-1 do begin

		// Modify WinNT path
		if UsingWinNT() = true then begin

			// Get current path, split into an array
			RegQueryStringValue(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 'Path', oldpath);
			oldpath := oldpath + ';';
			i := 0;
			while (Pos(';', oldpath) > 0) do begin
				SetArrayLength(pathArr, i+1);
				pathArr[i] := Copy(oldpath, 0, Pos(';', oldpath)-1);
				oldpath := Copy(oldpath, Pos(';', oldpath)+1, Length(oldpath));
				i := i + 1;

				// Check if current directory matches app dir
				if pathdir[d] = pathArr[i-1] then begin
					// if uninstalling, remove dir from path
					if IsUninstaller() = true then begin
						continue;
					// if installing, abort because dir was already in path
					end else begin
						abort;
					end;
				end;

				// Add current directory to new path
				if i = 1 then begin
					newpath := pathArr[i-1];
				end else begin
					newpath := newpath + ';' + pathArr[i-1];
				end;
			end;

			// Append app dir to path if not already included
			if IsUninstaller() = false then
				newpath := newpath + ';' + pathdir[d];

			// Write new path
			RegWriteStringValue(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 'Path', newpath);

		// Modify Win9x path
		end else begin

			// Convert to shortened dirname
			pathdir[d] := GetShortName(pathdir[d]);

			// If autoexec.bat exists, check if app dir already exists in path
			aExecFile := 'C:\AUTOEXEC.BAT';
			if FileExists(aExecFile) then begin
				LoadStringsFromFile(aExecFile, aExecArr);
				for i := 0 to GetArrayLength(aExecArr)-1 do begin
					if IsUninstaller() = false then begin
						// If app dir already exists while installing, abort add
						if (Pos(pathdir[d], aExecArr[i]) > 0) then
							abort;
					end else begin
						// If app dir exists and = what we originally set, then delete at uninstall
						if aExecArr[i] = 'SET PATH=%PATH%;' + pathdir[d] then
							aExecArr[i] := '';
					end;
				end;
			end;

			// If app dir not found, or autoexec.bat didn't exist, then (create and) append to current path
			if IsUninstaller() = false then begin
				SaveStringToFile(aExecFile, #13#10 + 'SET PATH=%PATH%;' + pathdir[d], True);

			// If uninstalling, write the full autoexec out
			end else begin
				SaveStringsToFile(aExecFile, aExecArr, False);
			end;
		end;

		// Write file to flag modifypath was selected
		//   Workaround since IsTaskSelected() cannot be called at uninstall and AppName and AppId cannot be "read" in Code section
		if IsUninstaller() = false then
			SaveStringToFile(ExpandConstant('{app}') + '\uninsTasks.txt', WizardSelectedTasks(False), False);
	end;
end;

/////////////////////////////////////////////////////////////////////
function GetUninstallString(): String;
var
  sUnInstPath: String;
  sUnInstallString: String;
begin
  sUnInstPath := ExpandConstant('Software\Microsoft\Windows\CurrentVersion\Uninstall\{{86DDE49A-CB27-4B64-A816-887A13C06D58}_is1');
  sUnInstallString := '';
  if not RegQueryStringValue(HKLM, sUnInstPath, 'UninstallString', sUnInstallString) then
    RegQueryStringValue(HKCU, sUnInstPath, 'UninstallString', sUnInstallString);
  Result := sUnInstallString;
end;

/////////////////////////////////////////////////////////////////////
function UnInstallOldVersion(): Integer;
var
  sUnInstallString: String;
  iResultCode: Integer;
begin
// Return Values:
// 1 - uninstall string is empty
// 2 - error executing the UnInstallString
// 3 - successfully executed the UnInstallString

  // default return value
  Result := 0;

  // get the uninstall string of the old app
  sUnInstallString := GetUninstallString();
  if sUnInstallString <> '' then begin
    sUnInstallString := RemoveQuotes(sUnInstallString);
    if Exec(sUnInstallString, '/SILENT /NORESTART /SUPPRESSMSGBOXES','', SW_HIDE, ewWaitUntilTerminated, iResultCode) then
//    if Exec(sUnInstallString, '/NORESTART','', SW_HIDE, ewWaitUntilTerminated, iResultCode) then
      Result := 3
    else
      Result := 2;
  end else
    Result := 1;
end;


/////////////////////////////////////////////////////////////////////
function IsUpgrade(): Boolean;
begin
  Result := (GetUninstallString() <> '');
end;


procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
    if IsUpgrade() then
      UnInstallOldVersion();
	if CurStep = ssPostInstall then
		if IsTaskSelected('modifypath') then
			ModPath();
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
	appdir:			String;
	aSelectedTasks:	TArrayOfString;
	i:				Integer;
begin
	appdir := ExpandConstant('{app}')
	if CurUninstallStep = usUninstall then begin
		if LoadStringsFromFile(appdir + '\uninsTasks.txt', aSelectedTasks) then
			for i := 0 to GetArrayLength(aSelectedTasks)-1 do
				if aSelectedTasks[i] = 'modifypath' then
					ModPath();
		DeleteFile(appdir + '\uninsTasks.txt')
	end;
end;

function NeedRestart(): Boolean;
begin
	if IsTaskSelected('modifypath') and not UsingWinNT() then begin
		Result := True;
	end else begin
		Result := False;
	end;
end;
