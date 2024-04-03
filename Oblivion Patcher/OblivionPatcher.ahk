;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! this script must have: encoding: ANSI (Windows 1251) *����� ���������* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

#SingleInstance Force
AutoTrim, Off
SetBatchLines, -1


; ���������� ������ ������ � �� ��������
{
	Patches := []
	Patches[0] := "1.00.0"
	Patches[1] := "1.00.1"
	Patches[2] := "1.00.2"
	Patches[3] := "1.00.3"
	Patches[4] := "1.00.4"
	Patches[5] := "1.00.4a"
	Patches[6] := "v1.1.0_pre1"
	Patches[7] := "v1.1.0"
	Patches[8] := "v1.1.1_pre1"
	Patches[9] := "v1.1.1"
	Patches[10] := "v1.1.2"
	Patches[11] := "v1.1.3_pre1"
	Patches[12] := "v1.1.3"
	
	PatchesCount := Patches.MaxIndex() + 1
	PatchesMaxIndex := Patches.MaxIndex()
}

; ����������� ������ ������ �������: 0 - ��������� �����, 1 - ��������� �����
{
	APPLICATION_MODE := ""
	IfExist, %A_ScriptDir%\LOCAL_MARK
	{
		FileRead, Multistring, *P1251, %A_ScriptDir%\LOCAL_MARK
		if (Multistring == "gwse57xkszw36llzw78cr68cr6t8cr68")
		{
			APPLICATION_MODE := 0
			; ����������� ������� �����
			ApplicationDir = %A_ScriptDir%
		}
	}
	else
		APPLICATION_MODE := 1
}

; ��� ������ ������� � ��������� ������
if (APPLICATION_MODE == 0)
{
	ApplicationDir = %A_ScriptDir%
	GetInstalledPatchIndex()
	gosub InstallPatch
	
	return
} ; ��������� ����� ����� ����������
else if (APPLICATION_MODE == 1)
{
	{
		; ���� �� ������� ����� �� ���������
		RegRead, ApplicationDir, HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Bethesda Softworks\Oblivion, Installed Path
		; FileRead, ApplicationDir, *P1251, %A_ScriptDir%\_patch_data\TEST_ApplicationDir.txt
		GetInstalledPatchIndex()
		
		; �������� ������������� ������ ������
		if (PatchesMaxIndex < OBLIVION_PATCHER_MINIMUM_PATCH_INDEX)
		{
			msgbox ������ ����� ������ ��� ����� ������ ������`n��������� ����������
			exitapp
		}

		Gui, Show, X200 Y200 W500 H200, OblivionPatcher
		Gui, Add, Text,, % Patches[PatchesMaxIndex]
		Gui, Add, Text,,
		Gui, Add, Button, gSelectGamePath, ������� ����������������� ����
		Gui, Add, Text,, ���� � ����:
		Gui, Add, Text, W500 vPath
		Gui, Add, Text,,
		Gui, Add, Button, gApplyPat�h vApplyPat�h, ��������� ����
		Gui, Add, Text, W500 vState
		Gui, Show, Autosize

		CheckApplicationDir("")
		
		return
	}
	
	ApplyPat�h:
	{
		GuiControl, Disable, ApplyPat�h
		gosub InstallPatch
		
		return
	}

	SelectGamePath:
	{
		FileSelectFolder, SelectedPath
		if SelectedPath
		{
			; ���������� ������� �����
			ApplicationDir := SelectedPath
			; Folder = D:\Games\Oblivion
			CheckApplicationDir("select")
		}
		return
	}

	CheckApplicationDir(Mode)
	{
		global ApplicationDir
		global Patches

		GuiControl, Text, Path
		GuiControl, Disable, ApplyPat�h
		BasicOblibionFilesFoundCount := 0
		IfExist, %ApplicationDir%\Oblivion.exe
			BasicOblibionFilesFoundCount++
		IfExist, %ApplicationDir%\obse_loader.exe
			BasicOblibionFilesFoundCount++
		if (BasicOblibionFilesFoundCount != 2)
		{
			if (Mode == "select")
			{
				msgbox � ��������� ����� �� ������� �������� ����������� ����� (Oblivion.exe, obse_loader.exe)
			}
			else
			{
				msgbox �� ���������� ������������� ����� ����, ���������� ������� ����� ���� �������
			}
		}
		else if (BasicOblibionFilesFoundCount == 2)
		{
			GetInstalledPatchIndex()
			GuiControl, Text, Path, %ApplicationDir%
			
			msgbox ���� ����������, ����� ���������� � ��������� �����
			GuiControl, Enable, ApplyPat�h
		}
	}
}

GuiClose:
ExitApp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


InstallPatch:
{
	; ����������� ����������� ������� �������� �� ������ �� ���������� �����
	FilesAndDates := ""
	Loop, Files, %ApplicationDir%\Data\*.*, F
	{
		if ((A_LoopFileExt == "esp") || (A_LoopFileExt == "esm") && (A_LoopFileName != "oblivion.esm"))
		{
			; !!! ���� �� ������������ !!!
			; ������������ ������, ������� ����� �� ���� � ������ - ������� ����� ��� ����� � FilesAndDates
			; if (A_LoopFileName == "Gloves.esp")
				; continue
			
			FileGetTime, FileDateModified , %A_LoopFileFullPath%, M
			if (FilesAndDates == "")
				FilesAndDates = %FilesAndDates%%FileDateModified%:%A_LoopFileName%
			else
				FilesAndDates = %FilesAndDates%`n%FileDateModified%:%A_LoopFileName%
			
			; !!! ���� �� ������������ !!!
			; ������������ ������, ������� ����� �� ���� � ������ - ��������� ������ ����� ����� ����� �� ������������ ������ (�� "������-������")
			; if (A_LoopFileName == "SupremeMagicka.esp")
			; {
				; FakeFileDateModified := FileDateModified + 1
				; FilesAndDates = %FilesAndDates%`n%FakeFileDateModified%:Gloves.esp
			; }
		}
		else
			continue
	}
	Sort FilesAndDates, N D`n

	;����������� ������ ����� (.esp, .esm � 1 .txt)
	if (APPLICATION_MODE == 1)
	{
		GuiControl, Text, State, ������� �����
		Loop, Files, %A_ScriptDir%\files\*.*, R
		{
			;�������� ������ ����� � ������������� ������������
			if (A_LoopFileExt == "esp") || (A_LoopFileExt == "esm") || (A_LoopFileName == "Oblivion Enhancer - ����������.txt") || (A_LoopFileName == "Oblivion Enhancer - ��������.txt")
			{
			}
			else
				continue
			
			PatchFileFullPath = %A_LoopFileLongPath%
			ScriptPath = %A_ScriptDir%\files
			FileFullPath := StrReplace(PatchFileFullPath, ScriptPath, "")
			GameFileFullPath = %ApplicationDir%%FileFullPath%
			FileCopy, %A_LoopFileLongPath%, %GameFileFullPath%, 1
		}
	}

	; ����������� �������� �� ����������� ������� ����� ��������� �� ���� �����������
	Loop, Parse, FilesAndDates, `n
	{
		Hr := Floor(A_Index/60)
		Min := A_Index - Hr*60
		
		StrHr := ""
		StrMin := ""
		if (Hr < 10)
			StrHr = 0%Hr%
		else
			StrHr = %Hr%
		if (Min < 10)
			StrMin = 0%Min%
		else
			StrMin = %Min%
		ReadedLine = %A_LoopField%
		Loop, Parse, ReadedLine, :
		{
			if (A_Index == 2)
			{
				ReadedLine = %A_LoopField%
				break
			}
		}
		FileDateModified = 20100101%StrHr%%StrMin%00
		FileSetTime, %FileDateModified%, %ApplicationDir%\Data\%ReadedLine%, M
	}
	
	;;;;;;;;;;	����� (���������� ���������, �����, ������ � �.�.)
	{
		;[0] - ��� � ���������� ����� �������� ����
		;[1] - ������ ����� (������ Patches)
		;[2] - ����:
		;	0 - �� ������� ���������
		;	1 - �������� �������� �� ��������� (�������� ������, ���� �������� ������������� �������� �� ���������)
		;	2 - �������� ������ �� ������
		;	3 - �������� ����� �������
		;	4 - �������� ����� ������
		;	5 - �������� � ������ �����
		;	6 - �������� � ����� �����
		;[3] - ������� ������-�����, ������������ ������� � ����� �������������� ���������
		;[4] - �����������/���������� ������
		;[5] - �������������� ������ � ��������� - ����� ������
		;[10] - ������� � �������/�� ������� ��������� ��� ������ � ����

		Changes := []
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 6
		ChangeArr[2] := 2
		ChangeArr[3] := "`;����� ����� ������� ��� ������� �������� KSE"
		ChangeArr[4] := ""
		StringsArr := []
		StringsArr.Push("`;------------------------------------------------------------------------")
		StringsArr.Push("`;����� ����� �������� ��� ������� �������� KSE")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 6
		ChangeArr[2] := 2
		ChangeArr[3] := "set KeaAddPCDamage to 0.03"
		ChangeArr[4] := "set OEKSEAddDamageMultPC to 0.075			`;float (0.075) ���� > 0, �� ��������������� ����������� ���������� ���� �� ������, � ���������� ���� ���� ������ ���������� �������� ������������ �����-�� ���������. 0.075 ��������, ���, ���� ���������� ���� �� ������ ��� ����� 7.5% �������� �������� ����� ������, �� ���� ���������� 7.5%, ���� �� ���� ������ 7.5%, �� �������� ����� �� �������������. ������ ������ ���������� (�����, ����� � �.�.) ������� �������� �� ���� ��������. ���� ���� �� ������ �������� (�.�. ��� �� ���� � ��� � ����� �� �������� ���������), �� ����� �������������� ���� �������� ������ ��� ������."
		Changes.Push(ChangeArr)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 1
		ChangeArr[3] := "set KeaRSMABaseCost to 0	"
		ChangeArr[4] := "set KeaRSMABaseCost to 0.3					`;float (0.5) ���� ������ ""0"" - ������� ��������� ������� ������������� ����� ��������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 2
		ChangeArr[3] := "setgs fArrowSpeedMult to 2000"
		ChangeArr[4] := "setgs fArrowSpeedMult 2000					`;float (v:1500, kse:2000) �������� �����."
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 2
		ChangeArr[3] := "set KeaRandomWeaponPowerMod	to 1.0"
		ChangeArr[4] := "set KeaRandomWeaponPowerMod to 1.0			`;float (1.0) ����������� �������� ������, ���������� �� �������� ������������ � ����������� ���� ����������������� ������ (�������� ������������ �������� �� ����� ���� ������ +10%, ����������� - +0%)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 4
		ChangeArr[3] := "set KeaRapidFire"
		ChangeArr[4] := "`nset OEKSEAmplifyingSystemBowPCDuration to 6			`;short (6)	����� �������� ""������� ����"" ��� ������. ������ ������������, ���� ���������� ������� �������� �� �����"
		StringsArr := []
		StringsArr.Push("`;[3..50]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 4
		ChangeArr[3] := "set KeaRapidFire"
		ChangeArr[4] := "set OEKSEAmplifyingSystemBowActorDuration to 5		`;short (5)	�� ��, �� ��� ���"
		StringsArr := []
		StringsArr.Push("`;[3..50]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 4
		ChangeArr[3] := "set KeaArmorAbsorbPercent"
		ChangeArr[4] := "`nset OEKSEArmorAbsorbSkillLimitPC to 1		`;short (1) ��� 1 ""����� �����"" ������� ������ ����� ������� �� ������ �������� ���� ������ - ������ ��� ������"
		StringsArr := []
		StringsArr.Push("`;[0,1]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 4
		ChangeArr[3] := "set KeaLongSwordAbilSkillChanceMOD"
		ChangeArr[4] := "`nset OEKSEDaggerIgnoreMult to 0.45			`;float (0.45) ����, ���������� ��������, ����� ������������ 45% ����� ������ ��� ���������� � ����� � ����/��� ��������������� ������"
		StringsArr := []
		StringsArr.Push("`;[0.0..1.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 4
		ChangeArr[3] := "set KeaLongSwordAbilSkillChanceMOD"
		ChangeArr[4] := "set OEKSEShortBladeIgnoreMult to 0.35		`;float (0.35) �� �� �����, �� ��� ��������� ����"
		StringsArr := []
		StringsArr.Push("`;[0.0..1.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 4
		ChangeArr[3] := "set KeaLongSwordAbilSkillChanceMOD"
		ChangeArr[4] := "set OEKSELongBladeIgnoreMult to 0.25		`;float (0.25) �� �� �����, �� ��� �������� ����"
		StringsArr := []
		StringsArr.Push("`;[0.0..1.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 4
		ChangeArr[3] := "set KeaLongSwordAbilSkillChanceMOD"
		ChangeArr[4] := "set OEKSETwoHandBladeIgnoreMult to 0.1		`;float (0.1) �� �� �����, �� ��� ���������� ����"
		StringsArr := []
		StringsArr.Push("`;[0.0..1.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEAddDamageMultPC"
		ChangeArr[4] := "set OEKSEAddDamageCritChancePC to 20		`;short (20) ���� ����, ��� ����, ��������� ����������� ���������� ���� �� ������, ����� ����������� (�1.5)"
		StringsArr := []
		StringsArr.Push("`;[0..100]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEAddDamageMultPC"
		ChangeArr[4] := "set OEKSEAddDamagePowCritChancePC to 10		`;short (10) ���� ����, ��� ����, ��������� ����������� ���������� ���� �� ������, ����� ��������� ����������� (�2.0), � �� ������� �����������"
		StringsArr := []
		StringsArr.Push("`;[0..100]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 4
		ChangeArr[3] := "set KeaRSMABaseCost"
		ChangeArr[4] := "set OEKSERSMAConstEffEnchFactor to 9.0		`;float (9) ���� ������ 0, �� �������� ����������� ����������� (�������� �� ���� �����������) ������� ""������������� �����"". ������ ��� KeaRSMABaseCost > 0"
		StringsArr := []
		StringsArr.Push("`;�������: KeaMAGICresMOD * 3 * <������� ��������> + OEKSERSMAConstEffEnchFactor")
		StringsArr.Push("`;[0.0..50.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 1
		ChangeArr[3] := "set OESkillArmorerUse0 to 2.0"
		ChangeArr[4] := "set OESkillArmorerUse0 to 1.5						`;(1.5) ����������� ��� ������ ��������� (�������, ���� ���� ��������� ������� �� ������������ ����)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 1
		ChangeArr[3] := "set OESkillHeavyArmorUse0 to 2.0"
		ChangeArr[4] := "set OESkillHeavyArmorUse0 to 5.0					`;(5.0) ������� ������� (�������� ���� ���� �� ������ �������� ������� ������� �����)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 1
		ChangeArr[3] := "set OESkillLightArmorUse0 to 2.0"
		ChangeArr[4] := "set OESkillLightArmorUse0 to 5.0					`;(5.0) ������ ������� (�������� ���� ���� �� ������ �������� ������� ������ �����)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 1
		ChangeArr[3] := "set OESkillMercantileUse0 to 3.0"
		ChangeArr[4] := "set OESkillMercantileUse0 to 5.0					`;(5.0) �������� (��������� �������� ��������)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 1
		ChangeArr[3] := "set OESkillSecurityUse0 to 3.0"
		ChangeArr[4] := "set OESkillSecurityUse0 to 10.0						`;(10.0) ����� (�������� �����)"
		Changes.Push(ChangeArr)
		;
		;
		ChangeArr := []
		ChangeArr[0] := "SupremeMagicka.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 4
		ChangeArr[3] := "set SMNewSpells"
		ChangeArr[4] := "set SMNewSuitableSpells to 1				`;(1) ��� 1 ��������� �����, �� �������� �������, ���������� �� Supreme Magicka ���������, ��� 0 - ������� ��"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "SupremeMagicka.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 4
		ChangeArr[3] := "set SMNewSpells"
		ChangeArr[4] := "set SMAddRestorationSpellsForAnvilMG to 1	`;(1) ��� 1 ����������� ��������� ����� � ������� ����� ��������� ����� ���������� ��������������, ��� 0 - ����������� ���������� ����� ������� � ���������"
		Changes.Push(ChangeArr)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 8
		ChangeArr[2] := 2
		ChangeArr[3] := "set KeaRapidFire to 1"
		ChangeArr[4] := "set OEKSERapidFire to 1									`;short (1) ��������/��������� ������� ""������� ����"" ��� ��������. ���� ������� �������� �� ����� (������� �� � ��� � �� �� ��������), �� ������������� ������� ����� ���� �����. ����� ������� ��������� ������������� ��������, ��� �������� �������� �������������� ����, ����������� ����� ������. ��� ���� �������, ��� ���� �������������� ���� (�� ������������� �������). ����� ""������ �����"" ���������, ������� �������� ����� ������ ���� �� ����� ""������"" (1 �������), � ��� ����� ������ �������� (����������, �������, ������) ������������� ������ ��������������� �����. �������� � ��� ������, � ��� ��� �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 8
		ChangeArr[2] := 2
		ChangeArr[3] := "set OEKSEAmplifyingSystemBowPCDuration to 6"
		ChangeArr[4] := "set OEKSERapidFirePCDuration to 8						`;short (8)	����� �������� ""������� ����"" ��� ������. ���� ���������� ������� �������� �� �����, �� ������� ����� ���� ����� ����������� � ��� ���������� 0 ������ ���������� �����������. ��� ��� ������� ����������� ����� ������"
		Changes.Push(ChangeArr)
		;
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 8
		ChangeArr[2] := 2
		ChangeArr[3] := "set OEKSEAmplifyingSystemBowActorDuration to 5"
		ChangeArr[4] := "set OEKSERapidFireNPCDuration to 6						`;short (6)	�� ��, �� ��� ���/�������"
		Changes.Push(ChangeArr)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		ChangeArr := []
		ChangeArr[0] := "SupremeMagicka.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 1
		ChangeArr[3] := "Set QuestSpellLevelling to 1"
		ChangeArr[4] := "Set QuestSpellLevelling to 0		`;Setting to 1 makes the quest award spells finger of the mountain and wizards fury"
		Changes.Push(ChangeArr)
		;
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 1
		ChangeArr[3] := "set keaTimePenalties.KeaHMFRestHealthMin to 12	"
		ChangeArr[4] := "set keaTimePenalties.KeaHMFRestHealthMin to 5		`;short (12) ����� ��������� ����� �������� ��������������� 1 ��.������������/2���. ��� ������ ��� �������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 1
		ChangeArr[3] := "set keaTimePenalties.KeaHMFRestMagicMin to 8	"
		ChangeArr[4] := "set keaTimePenalties.KeaHMFRestMagicMin to 4		`;short (8) ����� ����� ����� �������� ��������������� 1 ��.���.�����/2���. ��� ������ ��� �������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 1
		ChangeArr[3] := "set keaTimePenalties.KeaHMFRestFatigueMin to 25	"
		ChangeArr[4] := "set keaTimePenalties.KeaHMFRestFatigueMin to 10		`;short (25) ����� ������� ����� �������� ��������������� 1 ��.���������/2���. ��� ������ ��� �������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 1
		ChangeArr[3] := "set KeaMagickaRestoreMult to 5.0	"
		ChangeArr[4] := "set KeaMagickaRestoreMult to 2.0			`;float (10.0) - ����������� �������������� �� ����� ������/��� ���� (����������� ���������)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 1
		ChangeArr[3] := "set OEKSEAddDamageMultPC to 0.075	"
		ChangeArr[4] := "set OEKSEAddDamageMultPC to 0.06			`;float (0.06) ���� > 0, �� ��������������� ����������� ���������� ���� �� ������, � ���������� ���� ���� ������ ���������� �������� ������������ �����-�� ���������. 0.06 ��������, ���, ���� ���������� ���� �� ������ ��� ����� 6% �������� �������� ����� ������, �� ���� ���������� 6%, ���� �� ���� ������ 6%, �� �������� ����� �� �������������. ������ ������ ���������� (�����, ����� � �.�.) ������� �������� �� ���� ��������. ���� ���� �� ������ �������� (�.�. ��� �� ���� � ��� � ����� �� �������� ���������), �� ����� �������������� ���� �������� ������ ��� ������."
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 1
		ChangeArr[3] := "set KeaResistNormWeapSystem to 1	"
		ChangeArr[4] := "set KeaResistNormWeapSystem to 0			`;short (1) ���/���� ������� ������������� �������� ������ KSE. ����=1 - ������ �������, "
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 2
		ChangeArr[3] := "set OEKSEArmorAbsorbSkillLimitPC"
		ChangeArr[4] := "set OEKSEArmorAbsorbSkillDependencePC to 1	`;short (1) ��� 1 ""����� �����"" ������� ������ ����� ������� �� ������ �������� ���� ������ - ������ ��� ������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFire"
		ChangeArr[4] := "`nset OEKSERapidFireDistance to 1200						`;short (1200) ������������ ��������� ����� �������� � �����, �� ������� ����� �������� ""������ �����"" (�.�. ����������� �������������� ���� � ����������� ������� ����� ���� �����)"
		StringsArr := []
		StringsArr.Push("`;[100..3000]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "`nset OEKSERapidFireBowExtraDamageMinSequence to 4		`;short (4) ����������� �������� �������� ����� ���� ��� ��������������� ����� ��� �������� �� ����"
		StringsArr := []
		StringsArr.Push("`;[1..50]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "`nset OEKSERapidFireLev1PCShortDistanceCounter to 1		`;short (1) ����� �������� ������������ � �������� ����� ���� ����� ��� ������ �� 1 ������ ����������� ��� ��������� �� ����� �� ������� ��������� (�� OEKSERapidFireDistance * 0.5). �� ��������� �� OEKSERapidFireDistance * 0.67 �� OEKSERapidFireDistance � �������� ������ ������������ 1, � ����� OEKSERapidFireDistance * 0.5 � OEKSERapidFireDistance * 0.67 ���� ���� �������� � �������� �� 1, � �������� OEKSERapidFireLev1PCShortDistanceCounter (��� ������ ���������, ��� ���� ����)"
		StringsArr := []
		StringsArr.Push("`;[1..10]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev2PCShortDistanceCounter to 2		`;short (2) --||-- �� 2 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1..10]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev3PCShortDistanceCounter to 3		`;short (3) --||-- �� 3 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1..10]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev4PCShortDistanceCounter to 3		`;short (3) --||-- �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1..10]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev1NPCShortDistanceCounter to 1		`;short (1) �� ��, �� ��� ���/�������"
		StringsArr := []
		StringsArr.Push("`;[1..10]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev2NPCShortDistanceCounter to 1		`;short (1) --||-- �� 2 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1..10]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev3NPCShortDistanceCounter to 2		`;short (2) --||-- �� 3 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1..10]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev4NPCShortDistanceCounter to 2		`;short (2) --||-- �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1..10]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "`nset OEKSERapidFireLev1BowExtraDamageMaxSequence to 8	`;short (8) ������������ �������� ����� ���� ����� ��� �������� �������� ��������������� ����� �� 1 ������ �����������. ����� ���� ���������� �����"
		StringsArr := []
		StringsArr.Push("`;[1..50]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev2BowExtraDamageMaxSequence to 12	`;short (12) --||-- �� 2 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1..50]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev3BowExtraDamageMaxSequence to 16	`;short (16) --||-- �� 3 ������ �����������. �������� 16 ������������� ���������� ��������������� �����, ������� ����� ���� + ����� ������, ������� ��������� � ���������"
		StringsArr := []
		StringsArr.Push("`;[1..50]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev4BowExtraDamageMaxSequence to 20	`;short (20) --||-- �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1..50]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "`nset OEKSERapidFirePCCritical to 1						`;short (1) ���� ����������� ������ ������� ����������� ���� ��� ��������� ��������������� �����"
		StringsArr := []
		StringsArr.Push("`;[0,1]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireNPCCritical to 0						`;short (0) �� �� �����, �� ��� ���/�������"
		StringsArr := []
		StringsArr.Push("`;[0,1]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "`nset OEKSERapidFireCriticalMinSequence to 10				`;short (10) ����������� �������� �������� ����� ���� ��� ��������������� ������������ ����� ��� �������� �� ����. ���� ������� ���� ����� ��������, ����������� ���� �� ���������"
		StringsArr := []
		StringsArr.Push("`;[1..50]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "`nset OEKSERapidFireLev1CriticalMod to 2.0				`;float (2.0) ����������� ��������������� ������������ ����� �� 1 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1.0..10.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev2CriticalMod to 2.5				`;float (2.5) --||-- �� 2 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1.0..10.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev3CriticalMod to 3.0				`;float (3.0) --||-- �� 3 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1.0..10.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev4CriticalMod to 3.5				`;float (3.5) --||-- �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1.0..10.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "`nset OEKSERapidFireMinCriticalChance to 25				`;short (25) ����������� ���� ������� ����������� ����"
		StringsArr := []
		StringsArr.Push("`;[0..100]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireMaxCriticalChance to 80				`;short (80) ������������ ���� ������� ����������� ����"
		StringsArr := []
		StringsArr.Push("`;[0..100]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "`nset OEKSERapidFireLev1PCCounterDecrease to 4			`;short (4) �� ����� �������� ���������� ������� ����� ���� ������ �� 1 ������ ����������� � ���, ���� ���������� ������� �������� �� ������ � ������� �������, ��������� � OEKSERapidFirePCDuration. ��� ��� ������� ����������� ������� �������"
		StringsArr := []
		StringsArr.Push("`;[1..10]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev2PCCounterDecrease to 3			`;short (3) --||-- �� 2 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1..10]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev3PCCounterDecrease to 2			`;short (2) --||-- �� 3 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1..10]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev4PCCounterDecrease to 2			`;short (2) --||-- �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1..10]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev1NPCCounterDecrease to 4			`;short (4) �� �� �����, �� ��� ���/�������"
		StringsArr := []
		StringsArr.Push("`;[1..10]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev2NPCCounterDecrease to 4			`;short (4) --||-- �� 2 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1..10]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev3NPCCounterDecrease to 3			`;short (3) --||-- �� 3 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1..10]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev4NPCCounterDecrease to 3			`;short (3) --||-- �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1..10]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set KeaBonWillpowerMod"
		ChangeArr[4] := "set OEKSEEmpAgilityMod to 5.0				`;float (5.0) ������� ���� ""�����������"" ������ ������� �������� (������� � 40 ��������) ��� �������� ����������� ""��������� �������"""
		StringsArr := []
		StringsArr.Push("`;[0.0..100.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 1
		ChangeArr[3] := "set OEKSEFortificationAbility to 1	"
		ChangeArr[4] := "set OEKSEFortificationAbility to 1								`;(1) ���� ������ � ����������� ""����������"". ��� ����������� ��������� �������-������ �������� ��� ����������� ������������� � �������, �� ������������ ���������� �����������. ��� ���� ����������� ������������ ""��������� ����������"". ��� ���������/���������� ����������� ���������� ������������ ���������� ""KSE: ����������"""
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 3
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := ""
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEFortificationAbKnockdown to 1							`;(1) ������������ ���� ������ ����������� ���������� ���������(��) �� ����� ��� ����� �� ��� ������� �������� ���"
		StringsArr := []
		StringsArr.Push("`;[0,1][short]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEFortificationAbBaseCooldownTime to 15					`;(15) ������� ����� ������ ����������� ���������� ������� � ��� ������. �� �������� ����� ������ ��������� ������� (���������� ������ ������, ������� ������ �� ����� ���� ������� � �.�.), �� ��������� ��� �� ���� ��������"
		StringsArr := []
		StringsArr.Push("`;[1..50][short]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEFortificationAbLev1Enemy1KnockdownChance to 100		`;(100) ���� ����, ��� ��� ����� �� ����� (����� ����, ��� ������ ������� ��������� ��������) ����� ����� � ��� �������� ���� ����� �� 1 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev2Enemy1KnockdownChance to 100		`;(100) ---||--- ����� ����� � ��� �������� ���� ����� �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev3Enemy1KnockdownChance to 100		`;(100) ---||--- ����� ����� � ��� �������� ���� ����� �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev4Enemy1KnockdownChance to 100		`;(100) ---||--- ����� ����� � ��� �������� ���� ����� �� 4 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev1Enemy2KnockdownChance to 0			`;(0) ���� ����, ��� ��� ����� �� ����� ����� ���� � ��� ������ ���� �� 1 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev2Enemy2KnockdownChance to 50			`;(50) ---||--- ����� ���� � ��� ������ ���� �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev3Enemy2KnockdownChance to 80			`;(80) ---||--- ����� ���� � ��� ������ ���� �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev4Enemy2KnockdownChance to 90			`;(90) ---||--- ����� ���� � ��� ������ ���� �� 4 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev1Enemy3KnockdownChance to 0			`;(0) ���� ����, ��� ��� ����� �� ����� ����� ���� � ��� ������ ���� �� 1 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev2Enemy3KnockdownChance to 10			`;(10) ---||--- ����� ���� � ��� ������ ���� �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev3Enemy3KnockdownChance to 20			`;(20) ---||--- ����� ���� � ��� ������ ���� �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev4Enemy3KnockdownChance to 35			`;(35) ---||--- ����� ���� � ��� ������ ���� �� 4 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev1Enemy4KnockdownChance to 0			`;(0) ���� ����, ��� ��� ����� �� ����� ����� ���� � ��� ��������� ���� �� 1 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev2Enemy4KnockdownChance to 0			`;(0) ---||--- ����� ���� � ��� ��������� ���� �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev3Enemy4KnockdownChance to 10			`;(10) ---||--- ����� ���� � ��� ��������� ���� �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev4Enemy4KnockdownChance to 20			`;(20) ---||--- ����� ���� � ��� ��������� ���� �� 4 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev1Enemy5KnockdownChance to 0			`;(0) ���� ����, ��� ��� ����� �� ����� ����� ���� � ��� ����� ���� �� 1 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev2Enemy5KnockdownChance to 0			`;(0) ---||--- ����� ���� � ��� ����� ���� �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev3Enemy5KnockdownChance to 0			`;(0) ---||--- ����� ���� � ��� ����� ���� �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev4Enemy5KnockdownChance to 10			`;(10) ---||--- ����� ���� � ��� ����� ���� �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[0..100][short] ���")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEFortificationAbBulletTime to 1							`;(1) ������������ ���������� � ���"
		StringsArr := []
		StringsArr.Push("`;[0,1][short]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEFortificationAbLev1Enemy1BulletTimeStrength to 0.8		`;(0.8) ������� ���������� ��� 1 ����� ���������� � 1 ������ �����������. �� 1 ������ ����������� ������� ���������� ������ ����� �� ����������� �� ������ ������� ���������� ����� ��. ��� � ��� 1 ����� ����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev2Enemy1BulletTimeStrength to 0.8		`;(0.8) ������� ���������� ��� 1 ����� ���������� � 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev3Enemy1BulletTimeStrength to 0.8		`;(0.8) ������� ���������� ��� 1 ����� ���������� � 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev4Enemy1BulletTimeStrength to 0.8		`;(0.8) ������� ���������� ��� 1 ����� ���������� � 4 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev2Enemy2BulletTimeStrength to 0.7		`;(0.7) ������� ���������� ��� 2 ������ ���������� � 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] :=    "set OEKSEFortificationAbility"
		ChangeArr[4] :=    "set OEKSEFortificationAbLev3Enemy2BulletTimeStrength to 0.7		`;(0.7) ������� ���������� ��� 2 ������ ���������� � 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev4Enemy2BulletTimeStrength to 0.7		`;(0.7) ������� ���������� ��� 2 ������ ���������� � 4 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev3Enemy3BulletTimeStrength to 0.65	`;(0.65) ������� ���������� ��� 3 ������ ���������� � 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev4Enemy3BulletTimeStrength to 0.65	`;(0.65) ������� ���������� ��� 3 ������ ���������� � 4 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev4Enemy4BulletTimeStrength to 0.6		`;(0.6) ������� ���������� ��� 4 ������ ���������� � 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[0.5..0.95][float] ���, � ����� 0.05")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEFortificationAbFortify to 1							`;(1) ������������ ������������� ����������� ������ (�������������� ��������, ������������� � �.�.) �� ������"
		StringsArr := []
		StringsArr.Push("`;[0,1][short]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEFortificationPlayRechargeEffect to 1					`;(1) ��������/��������� ������ ����������� ������� ���������� ���������� ����� ����������� � ���"
		StringsArr := []
		StringsArr.Push("`;[0,1][short]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`n`nset OEKSEArcaneArcherAbility to 1								`;(1) ���� ������ � ����������� ""��������� �������"". ��� ����������� ��������� �������-�������� ������������� � ��������� ������. � ������������ ��������� ������ ��� ������������ ����� (�������������, �������, ��������� � �.�.) ��� ������ �������� ��� ���� ��� ��� ������� � �����������, ������� �� ���� �������� - ��������� ������� ��������� ������� ������ �� ����������. ��� ���������/���������� ����������� ���������� ������������ ���������� ""KSE: ��������� �������"". ������������� ���� ����������� �� ��������� ������������� ������� �����. �.�. ��������������� � ����������� ������ ����� % �� ����� ����, �� ���������� ���������� ��������� �������� �� ����������� �� ������ ������ ��������� �� �������. ���� ���� ������ �� ������ �������� ������� - ��� ���� ����������� ������������ ����������� ���� �� ��������. ������������ ��������� ������, ��������� ����, ����������� ������ � ������� ���������� �������. ���� ���� ��������� ����� � �������� � ������� ������, �� ������ �� ���������, ����� ��� �� ��������� �� ����� � ����������� � �����"
		StringsArr := []
		StringsArr.Push("`;[0,1][short]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherDebuffDuration to 3.0						`;(3.0) ������� ������������ ������ �� ������, �.�. ������� ������� ��������� ���������� ��� ��������� �����. ���� ���������� ������� �������� �� �����, �� ������ ��������� ����������� � ���� �����������"
		StringsArr := []
		StringsArr.Push("`;[1.0..10.0][float]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherLev1ContinuousDebuffDuration to 3			`;(3) ����� ������ �������� �������� � ����, ������� ��� ��� ��������� ��� ��������� ������, �� ������ ������� ������������ ����� ����������� ��� ��������. ��� �������������� ������������ �� 1 ������ ����������� - �� ��������� ��� ����� ������� ������������. ��� ������������ ����������� ������ � ��� ������, ���� ���� ��������� �� ������� ��� ������� ��������� �� ������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev2ContinuousDebuffDuration to 5			`;(5) --||-- �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev3ContinuousDebuffDuration to 6			`;(6) --||-- �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev4ContinuousDebuffDuration to 7			`;(7) --||-- �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[0..20][short] ���")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherLev1ExtraContinuousDebuffDuration to 3		`;(3) �������������� ������������ �� 1 ������ ����������� ��� ��� �������, ����� ���� ������� ������� ������ � �������� ����������� ��������������� ������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev2ExtraContinuousDebuffDuration to 7		`;(7) --||-- �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev3ExtraContinuousDebuffDuration to 9		`;(8) --||-- �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev4ExtraContinuousDebuffDuration to 11	`;(11) --||-- �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[0..20][short] ���")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherShortDistanceValue to 500					`;(500) ������� �������� �������� ���������. ���� ���������� �� ����� ����� ��� ������, �� ����������� ��������������� ������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLongDistanceValue to 1000					`;(1000) ������� �������� ������� ���������. ���� ���������� �� ����� ����� ��� ������, �� ����������� ����������� ������ ������� ����. ���� ���� �������� �� ���������� �� OEKSEArcaneArcherShortDistanceValue �� OEKSEArcaneArcherLongDistanceValue, �� ���������, ��� �� �� ������� ��������� � ����������� ������� ����������� ������"
		StringsArr := []
		StringsArr.Push("`;[100..2000][short] ���")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherShortDistanceSpellCostMod to 0.3			`;(0.3) ����������� ��������� ������, ����������� �� �������� ���������. ��������� ������ = ����� ���������� ���� * �����������, �.�. ��� ������������� ������ ���������� ������� (30%) �� ������ ���������� ����! ��� ���� ����������� ���������� ������� �� ������� �� ������ ���������� ����. ��������������, ��� ������ ����, ��� ���� ����������� ������ ���������� ������� - � ��������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherAverageDistanceSpellCostMod to 0.15		`;(0.15) ����������� ��������� ������, ����������� �� ������� ���������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLongDistanceSpellCostMod to 0.075			`;(0.075) ����������� ��������� ������, ����������� �� ������� ���������"
		StringsArr := []
		StringsArr.Push("`;[0.0..1.0][float] ���")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherLev1CounterAttackCostMod to 1.0			`;(1.0) ����������� ��������� ������, ����������� �� ����� ����� ����� �� 1 ������ �����������. �� ��������� ��� 1 ������ ��������� * 1, �.�. �� ��������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev2CounterAttackCostMod to 0.5			`;(0.5) --||-- �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev3CounterAttackCostMod to 0.45			`;(0.45) --||-- �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev4CounterAttackCostMod to 0.4			`;(0.4) --||-- �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[0.0..5.0][float] ���")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherLev1RepeatCostMod to 0.8					`;(0.8) ����������� ��������� ������ ��� ���������� �� �����, ������� ��� ��������� ��� ������������ ������ ���������� �������, �� 1 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev2RepeatCostMod to 0.7					`;(0.7) --||-- �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev3RepeatCostMod to 0.65					`;(0.65) --||-- �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev4RepeatCostMod to 0.6					`;(0.6) --||-- �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[0.0..5.0][float] ���")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherLev1LevelDiffCostMod to 2.0				`;(2.0) ����������� ��������� ������ ��� ���������� �� �����, ������� ����������� ��������� ������ �� ������, �� 1 ������ �����������. ��������� ������ ������ ������� � ������� � 5 �������, ��� ������� � 15 ������� � ���� ��������� �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev2LevelDiffCostMod to 1.5				`;(1.5) --||-- �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev3LevelDiffCostMod to 1.25				`;(1.25) --||-- �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev4LevelDiffCostMod to 1.0				`;(1.0) --||-- �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1.0..5.0][float] ���")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherLev1AdditionalTargets to 0					`;(0) ������� �������������� ����� ����� �������� ��������������� ��� ����������� ������ �� 1 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev2AdditionalTargets to 1					`;(1) --||-- �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev3AdditionalTargets to 2					`;(2) --||-- �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev4AdditionalTargets to 3					`;(3) --||-- �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[0..10][short] ���")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherLev1DebuffArea to 0						`;(0) ������� ��������� ������ �� 1 ������ �����������. �� ��������� �� 1 ������ ����������� ������ ���� ������ �� �������� ����"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev2DebuffArea to 150						`;(150) --||-- �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev3DebuffArea to 175						`;(175) --||-- �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev4DebuffArea to 200						`;(200) --||-- �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[0..1000][short] ���")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherIgnoreWeakActors to 1						`;(1) ������������ ������ ����������� (����, ������ � �.�.) ��� ���������� ������"
		StringsArr := []
		StringsArr.Push("`;[0,1][short]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherMagickaReturnMult to 0.05					`;(0.05) �����������, ���������� �� ����������� ���� - ��� �� ������, ��� ������ ����������� ���� � ��������"
		StringsArr := []
		StringsArr.Push("`;[0.001..1.00][float]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`n`nset OEKSEBattleMagicAbility to 1								`;(1) ���� ������ � ����������� ""������ �����"". ��� � � ������ � ��������, �����, �������� �� ����, ������ ���� ��������, ���� ������ �� �� ���������� �����. �.�. ���� �� ����������, �� ����� ����� ��� � ��������� �� ��������� �� ���� ������� ������ ������, ��������������, ��� ��� �������, ��� ��� ����, ���� ������� �� ������������ ������ � ������ � ���������� ������. ��� ����������� ��������� ������ ���� ���������� ���������� �����, �������� ������������ ������ ������� ��� ����� � ������ ��������� ����������� ����� ������� �������� ��� ����� ������������ (��� � ��������� ������) ����� ������� ���������� �������� ���� ���������� ��� � �������, ����� ����. ������������ ������ �������� ��� ��� ���� ��������� �������� ���������� ����, ������� � ��� � �.�. �� ���� ���������� �������������� ������ ������ ���������� ��� ���������� (������� ����) � ���� ������ ������. �������� ���� � ����� �������� ������� �� ���� ������������� �� ������. ���������� ���� ������������� ����� � �������� ������, ����� ����������� �������. ��������� OEKSEBattleMagic* �������� ������� �� ����� ������ �� ������"
		StringsArr := []
		StringsArr.Push("`;[0,1][short]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEBattleMagicBurnBaseDamage to 4.0						`;(4.0) ����������� �������� ���� ����������� �������������. ���� �������� �� �������, � ������ ������� ��������� ������������ ��������, � ��������� - 1 (���� ������� � �������). ��� ������� ������� ����������/���������� � ����� ������ ������ (� ��� ����� - ��-�� ������������ + % ���.) ������� ������������ ���� � ������� �������"
		StringsArr := []
		StringsArr.Push("`;[0.1..20.00][float]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEBattleMagicLev1Area to 200								`;(200) ������� �������� ����������� ������������� �� 1 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev2Area to 250								`;(250) --||-- �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev3Area to 300								`;(300) --||-- �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev4Area to 400								`;(400) --||-- �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[100..1000][short] ���")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEBattleMagicBurnBaseDuration to 10.0					`;(10.0) ������� ������������ ����������� �������������. ��� ������ ������������, ��� ������ ��������� ����� �� ���� ���������� ������� � ��� ����� ������� ������ ��������"
		StringsArr := []
		StringsArr.Push("`;[5.0..20.00][float]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEBattleMagicBurnLev1AdditionalDuration to 0.0			`;(0.0) �������������� ������������ ����������� ������������� �� 1 ������ �����������. �������� � ���� � ����� ��������, ����� ����� �� �������, �� ���� ����������� ������� ������ ��� ���"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicBurnLev2AdditionalDuration to 0.0			`;(0.0) --||-- �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicBurnLev3AdditionalDuration to 2.5			`;(2.5) --||-- �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicBurnLev4AdditionalDuration to 5.0			`;(5.0) --||-- �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[0.0..10.00][float]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEBattleMagicBurnMaxCooldownTime to 10					`;(10) ������������ ����� �������������� ����������� �������. ����� �������������� ����� ��������� �� ���� ����� ���� � ������������ ��������� ����"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicBurnMinCooldownTime to 6					`;(6) ����������� ����� �������������� ����������� �������, ����� �� �����������"
		StringsArr := []
		StringsArr.Push("`;[1..20][short] ���")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEBattleMagicLev1RepeatDamageMod to 0.5					`;(0.5) ����������� ����� ��� ��������� ���������� ������������ ����� � ��� �� ���� �� 1 ������ �����������. �� ��������� �� 1 ������ ����������� ��������� ������������� �� ���� ��������������� �����"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev2RepeatDamageMod to 0.85					`;(0.85)  --||-- �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev3RepeatDamageMod to 1.0					`;(1.0)  --||-- �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev4RepeatDamageMod to 1.15					`;(1.15)  --||-- �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[0.5..5.0][float] ���")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEBattleMagicBurnBlockStagger to 1						`;(1) ���� ����������� ��� ������������ ����� ������������ ���������� �������������� ���������� ������� ��� �� ����� �� �������� ���������� ������� � ������� �������� �� ��� ����������� ����������� �������"
		StringsArr := []
		StringsArr.Push("`;[0,1][short]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEBattleMagicBurnStagger to 1							`;(1) ���� ����������� ������������ �������� ����������� ���������� �������������� ����������� �� �����"
		StringsArr := []
		StringsArr.Push("`;[0,1][short]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEBattleMagicLev1PrimaryTargetStaggerChance to 35		`;(35) ��� ��������� ����� ������� �������� ��� ���� ���� �������������� ������� �� ����� ������� ���� ����������� ������������� (�.�. ����, �� ���� �������� ����) �� 1 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev2PrimaryTargetStaggerChance to 40		`;(40) --||-- �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev3PrimaryTargetStaggerChance to 50		`;(50) --||-- �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev4PrimaryTargetStaggerChance to 55		`;(55) --||-- �� 4 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev1SecondaryTargetStaggerChance to 15		`;(15) ��� ��������� ����� ������� �������� ��� ���� ���� �������������� ������� �� ����� �������������� ���� ����������� ������������� �� 1 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev2SecondaryTargetStaggerChance to 20		`;(20) --||-- �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev3SecondaryTargetStaggerChance to 25		`;(25) --||-- �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev4SecondaryTargetStaggerChance to 25		`;(25) --||-- �� 4 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev1BurnMinStaggerChance to 20				`;(20) ����������� ���� �������������� ������� �� ����� �����������, �� ������� ��������� ���������� ������������� �� 1 ������ �����������. ���� ������ � ������ �������� �, ����� ���������������� ������ ���������� �� �����, �� �� ��������� ������ �� ��������� ����� �������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev2BurnMinStaggerChance to 25				`;(25) --||-- �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev3BurnMinStaggerChance to 30				`;(30) --||-- �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev4BurnMinStaggerChance to 35				`;(35) --||-- �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[0..100][short] ���")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEBattleMagicDamageToImmune to 1							`;(1) ���� ����������� ����������� ������������� �������� ����������� ����������� � ����������� � ����� (100% �������������, ����������, ��������� �����)"
		StringsArr := []
		StringsArr.Push("`;[0,1][short]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEBattleMagicLev1DamageToImmuneMod to 0.0				`;(0.0) ����������� ����� ����������� ������������� �� �������� � ����� ����� �� 1 ������ �����������. �� ��������� �� 1 ������ ����������� ���������� ������������� �� ������� ����� ����� ����� �, � ��������, �� ��������� �� ���"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev2DamageToImmuneMod to 0.25				`;(0.25) --||-- �� 2 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev3DamageToImmuneMod to 0.35				`;(0.35) --||-- �� 3 ������ �����������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev4DamageToImmuneMod to 0.5				`;(0.5) --||-- �� 4 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[0.0..1.0][float] ���")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEBattleMagicSpentMagickaRechargeValue to 100			`;(100) ����� ���������� ����������� ���� ��������� ����������� ���������� �������������. ������� ���� ����� � ""��� �����"", � ����� ������ ��� ��������� �� ����� ���� ���������� ������ � ������� ��� ����� ����������� ����������� ������� ����� �������������� ����������� ������������� �� ��������� ������ ������"
		StringsArr := []
		StringsArr.Push("`;[10..1000][short]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEBattleMagicPlayRechargeEffect to 1						`;(1) ��������/��������� ������ ������ �����, ������� ������������� �� ��������� ����������� ����������� �������������"
		StringsArr := []
		StringsArr.Push("`;[0,1][short]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEAddTargetHealthAbsorbSpells to 1						`;(1) ��������� � ������� ���������� ���������� ����� �� ��������� ����"
		StringsArr := []
		StringsArr.Push("`;[0,1][short]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		;
		ChangeArr := []
		ChangeArr[0] := "Maskar's Oblivion Overhaul.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 1
		ChangeArr[3] := "set MOO.ini_add_graverobbers to 1"
		ChangeArr[4] := "set MOO.ini_add_graverobbers to 0			`;!"
		Changes.Push(ChangeArr)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 10
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireMaxCriticalChance"
		ChangeArr[4] := "`nset OEKSERapidFireCriticalChanceMod to 1				`;float (1) ����������� ����� ������� ����������� ����, ���������� �� (������� �������� �������� ����� ���� - ����������� �������� �������� ����� ����) � ������������ � ����������� ������ ������� ����������� ����"
		StringsArr := []
		StringsArr.Push("`;[1.0..10.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 10
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireLev1PCCounterDecrease"
		ChangeArr[4] := "set OEKSERapidFireLev2PCCounterDecrease to 3			`;short (3) --||-- �� 2 ������ �����������"
		StringsArr := []
		StringsArr.Push("`;[1..10]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer.ini"
		ChangeArr[1] := 10
		ChangeArr[2] := 1
		ChangeArr[3] := "set OESkillAthleticsUse0 to 2.0"
		ChangeArr[4] := "set OESkillAthleticsUse0 to 4.0						`;(4.0) �������� (������� ����)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer.ini"
		ChangeArr[1] := 10
		ChangeArr[2] := 1
		ChangeArr[3] := "set OESkillAthleticsUse1 to 2.0"
		ChangeArr[4] := "set OESkillAthleticsUse1 to 4.0						`;(4.0) �������� (������� ��������)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer.ini"
		ChangeArr[1] := 10
		ChangeArr[2] := 1
		ChangeArr[3] := "set OESkillMysticismUse1 to 2.0"
		ChangeArr[4] := "set OESkillMysticismUse1 to 1.25					`;(1.25) ��������� (������� ���� ����������� ����������)"
		Changes.Push(ChangeArr)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 11
		ChangeArr[2] := 2
		ChangeArr[3] := "set KeaPCToughtness to 1"
		ChangeArr[4] := "set OEKSEPCToughness to 1										`;short (1) � ��������� ������� �������� ������ �������� ����� ��������, ��� ����� ���. ��� ���� ��� ����������� ������������� ����������� � ���������� �� ����� ���� � ����� ������ ��������. ��� ������ ����� � ����� �����, ��� ���� �� ����������� �� �����, � ���� ������ �������� �����, �� ����������� ���������� ��� �������! ������ ��� ���, ��� ��������� �������� �������"
		Changes.Push(ChangeArr)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 1
		ChangeArr[3] := "set KeaSKILLWisdomMAX to 100"
		ChangeArr[4] := "set KeaSKILLWisdomMAX to 200				`;short (100) - �������� �������� ������ ""��������"""
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 1
		ChangeArr[3] := "set KeaSKILLMedicMAX to 100"
		ChangeArr[4] := "set KeaSKILLMedicMAX to 200					`;short (100) - ���� ����� - �� ��� ""��������"""
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 2
		ChangeArr[3] := "set KeaRandomWeaponPowerMod to 1.0"
		ChangeArr[4] := "set KeaRandomWeaponPowerMod to 1.0			`;float (1.0) ����������� �������� ������, ���������� �� �������� ������������� �������� ������, ��� ���� ����������� �������� ������ ����� ����� 0.5 �� ������������� (��������, �� 0 ������ ������ � ��� KeaRandomWeaponPowerMod = 1.5 ������������ �������� ������ ����� 25*1.5= +37.5%, � ����������� ����� 37.5*0.5= +18.75%)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 2
		ChangeArr[3] := "set KeaRandomArmorPowerMod to 1.0"
		ChangeArr[4] := "set KeaRandomArmorPowerMod to 1.0			`;float (1.0) ����������� �������� �����. ����������� �������� = 0.5 �� �������������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 2
		ChangeArr[3] := "set KeaRandomEnchantPowerMod to 1.0"
		ChangeArr[4] := "set KeaRandomEnchantPowerMod to 1.0			`;float (1.0) ����������� �������� ����������� (������/�����). ����������� �������� = 0.75 �� �������������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 2
		ChangeArr[3] := "set KeaRandomStaffPowerMod to 1.0"
		ChangeArr[4] := "set KeaRandomStaffPowerMod to 1.0			`;float (1.0) ����������� �������� �������. ����������� �������� = 0.75 �� �������������"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set KeaSettingRedBlink"
		ChangeArr[4] := "set OEKSEBladeGoverningSpeed to 0 			`;short (0) ��������� �������� �������� ������ ""������"" � ��������, ������� ����� ������������� ��� ��������� ������ (���� ����� �� ��������� ������ ������� �������� ������� ""������""). ��� 0 ����� ����� ����, ��� 1 - ��������"
		StringsArr := []
		StringsArr.Push("`;[0,1]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 1
		ChangeArr[3] := "setGS fDamagePowerAttackForwardBonus 4.0"
		ChangeArr[4] := "setGS fDamagePowerAttackForwardBonus 2.5	`;float (v:3,KSE:5) �� ������� ��� ������� ""������ �����"" ��� �������� ������ (���� � ����� ������)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 2
		ChangeArr[3] := "set OEKSEAddDamagePowCritChancePC"
		ChangeArr[4] := "set OEKSEAddDamagePowCritChancePC to 50		`;short (50) ���� ����, ��� ����, ��������� ����������� ���������� ���� �� ������, ����� ��������� ����������� (�2.0), � �� ������� �����������. ���� ���������� ������������ ����� ������������� � ������ �������� ������������ �����, �.�. ����� ���� �������� ��������� ����������� ���� ����� 0.2*0.5=0.1=10%"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set KeaDMGPenStaggerBaseAgi"
		ChangeArr[4] := "`nset OEKSEPCHealthPenaltyRestriction to 1						`;short (1) ������������ �������������� ���� ��� �� ������ (�� ������ � �����, �� ����� �����, �� ����� ������������ ���������� � �.�.). �� ������������ ����������� ������� ���� (��������, ������� ���� �� ������� � ��������� ������� � ����� ��� ��� ��������� ������������ ����) ��� ���� �� �����"
		StringsArr := []
		StringsArr.Push("`;[0,1]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set KeaDMGPenStaggerBaseAgi"
		ChangeArr[4] := "`nset OEKSEPCHealthPenaltyRestrictionBaseAttack to 0.15			`;float (0.15) ���� ����� �������� ������� ���� �������� ��� ��� ���� �� ������ � ��������� ���� ��������� ��� �������� (0.15=15% �� �������� �������� �����), �� ����� �������������� ���� ���� ����� �������� ��� ����� ����� ����������"
		StringsArr := []
		StringsArr.Push("`;[0.0..1.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set KeaDMGPenStaggerBaseAgi"
		ChangeArr[4] := "set OEKSEPCHealthPenaltyRestrictionPowerAttack to 0.25			`;float (0.25) �� �� �����, �� ��� ������� ���� �������� ���"
		StringsArr := []
		StringsArr.Push("`;[0.0..1.0]`n")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "`n`nset OEKSEPCMeleeCombatRegulation to 1							`;short (1) ���� ������ ��������� ����������� ����������� � ������� ���. ���������� - �������� ������� ������������� ���������� ��� � ��������, ��������� ������ � ������� ���. ���������� ��������� ������� �� ����, ������ � ���������� ������� � ��������� ������. ������ �������� ��� ������ �������� ���, ��� ����� ����� ����������. ���������� ��������� ������������� ���������� ������ ��������� ������ (�������, � ������� 2 ������ ������ ����� ��������� �� ����� 2 ������, ����� � ������� 4 ������ �� ����� 3 ������ � �.�.). �� ������ �� ����� 1 �� 1. �� ������ �� ��������� �������� �� ���� � ������������ ���������� �������. ������ �� ��� � �������� ������ �����, ����� �� ���� - �����, �� �� �� �� ��� ����� �����. ������ ������ �������� (�����, ����� � �.�.) �� �����������. �������� ������ ��� KeaSettingWSpeed = 1"
		StringsArr := []
		StringsArr.Push("`;[0,1]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "`nset OEKSEPCMeleeCombatRegulationConsiderCreatures to 1			`;short (1) ��������� ��������, ��������� ������. ��� 0 ����� ����������� ������ ��� (������� � �.�.), � ������� (�����, �������, �������� � �.�.) �� ����� ����� ����������"
		StringsArr := []
		StringsArr.Push("`;[0,1]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "`nset OEKSEPCMeleeCombatRegulationRaceImperial to 2.65			`;float (2.65) ������� ���������� ���������, ���� �������� ������ ����� ���� ""�������"". �� 1 �� 4. ��������, 2.65, ���� �� ��������� �������� ���������, �������� �� ����� 2.65 ��������� ������������ (������� ��������) � ��� �������� ����� �������� � ��������� �� 2.15 �� 3.15 ������ ��������� ������. � ����� ������ � ������� ��� ����� ��������� 35% ������� �� ����� 2 ������ � 65% �� ����� 3 ������"
		StringsArr := []
		StringsArr.Push("`;[1.0..4.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "set OEKSEPCMeleeCombatRegulationRaceKhajiit to 2.2				`;float (2.2) ������"
		StringsArr := []
		StringsArr.Push("`;[1.0..4.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "set OEKSEPCMeleeCombatRegulationRaceWoodElf to 2.35				`;float (2.35) ������ ����"
		StringsArr := []
		StringsArr.Push("`;[1.0..4.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "set OEKSEPCMeleeCombatRegulationRaceNord to 2.5					`;float (2.5) ����"
		StringsArr := []
		StringsArr.Push("`;[1.0..4.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "set OEKSEPCMeleeCombatRegulationRaceOrc to 2.5					`;float (2.5) ���"
		StringsArr := []
		StringsArr.Push("`;[1.0..4.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "set OEKSEPCMeleeCombatRegulationRaceRedguard to 2.5				`;float (2.5) �������"
		StringsArr := []
		StringsArr.Push("`;[1.0..4.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "set OEKSEPCMeleeCombatRegulationRaceDarkElf to 2.65				`;float (2.65) Ҹ���� ����"
		StringsArr := []
		StringsArr.Push("`;[1.0..4.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "set OEKSEPCMeleeCombatRegulationRaceArgonian to 2.2				`;float (2.2) ����������"
		StringsArr := []
		StringsArr.Push("`;[1.0..4.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "set OEKSEPCMeleeCombatRegulationRaceBreton to 2.8				`;float (2.8) ��������"
		StringsArr := []
		StringsArr.Push("`;[1.0..4.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "set OEKSEPCMeleeCombatRegulationRaceHighElf to 2.95				`;float (2.95) ������� ����"
		StringsArr := []
		StringsArr.Push("`;[1.0..4.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "`nset OEKSEPCMeleeCombatRegulationConsiderPhysics to 1			`;short (1) ��������� �������� ������ ������� (������, �������� ������ � ���������� ���) � ��������� (����, ��������, �������� � ������������) ��� ������� ������������ ���������� ���������. ���� ��������� ������ ������ � ��������, �� ���������� ��������� ������ ������ � ������� ��� �������� (����� ������ ���� �������� ����� �������� ���)"
		StringsArr := []
		StringsArr.Push("`;[0,1]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "`nset OEKSEPCMeleeCombatRegulationConsiderMagic to 1				`;short (1) ��������� ����� ���������� ����, ����������� ����� ��������, �������� ���������� ������� � ���������. ���� ������� ���������� ���� (������� ����, �������� - ����� ������� ����� ���������� �����), ����� ���������� ���� �������� (���, ������, �������), ��������� ������ ���������� ������ (���������� � ����������, ����� ������ - ���������) � ���������� �������� (��������� � ���� ����), �� ���������� ��������� ������ ������ � ������� ��� ���������� (����� ������ ���� �������� ����)"
		StringsArr := []
		StringsArr.Push("`;[0,1]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "`nset OEKSEPCMeleeCombatRegulationInfo to 1						`;short (1) ��������� ���������� �� ����������� � ����� �������������� ���������� KSE. ��� ����������� ��������� ������ ������� (�� ���������� ������) �������� �������/���������"
		StringsArr := []
		StringsArr.Push("`;[0,1]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "`n`nset OEKSEPCMeleeCombatEnhancedDamage to 1						`;short (1) ���� ������ ��������� �����������, ����������� ������������ ��������� ������������ ����� ������ ��� �����. ���������� � ��� �� ������������ ����� ���� � ������ � ��� ���� ����������� �������������� ������ ��������� ������ ��� ����� ������ �����, ��� ����� ���������� ���� ���������� ���� � ������� ���. ��� ���� ����� �������� (��� ��������, ���������, ���������� ��������), ������� ""�������� ��� ������"" � ��� � ����� ����������� �����, ������ ������ ������������������ �� ���������� - ���� ���� ����� ""��������"" ����������� ������� ������������� �����������, � 2 � ����� ��������� �������� ������ �����������! ��������� ����� ������� ���� (�������� - �����) ���������� ����������� ����� ���������� �� ��������� � ������, ������� ������������ ����� ������ ���������� (�������� - ������� �����). ��� ������ ������� ������ ������ � �������� �� ��������� � �����������, ��� ���� ������������� ����������� � ��������. ������ ������ �������� (�����, ����� � �.�.) �� �����������"
		StringsArr := []
		StringsArr.Push("`;[0,1]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "`nset OEKSEPCMeleeCombatEnhancedDamageRaceImperial to 1.1			`;float (1.1) ����������� ������������� ����������� ��� ���� ""�������"". ������ �� �������������� ���������� ���� � ������� ��� � ����������� ������������ - ���� >1, �� ����������� ���, ���� < 1, �� ���������"
		StringsArr := []
		StringsArr.Push("`;[0.5..2.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "set OEKSEPCMeleeCombatEnhancedDamageRaceKhajiit to 0.95			`;float (0.95) ������"
		StringsArr := []
		StringsArr.Push("`;[0.5..2.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "set OEKSEPCMeleeCombatEnhancedDamageRaceWoodElf to 1.0			`;float (1.0) ������ ����"
		StringsArr := []
		StringsArr.Push("`;[0.5..2.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "set OEKSEPCMeleeCombatEnhancedDamageRaceNord to 1.25			`;float (1.25) ����"
		StringsArr := []
		StringsArr.Push("`;[0.5..2.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "set OEKSEPCMeleeCombatEnhancedDamageRaceOrc to 1.3				`;float (1.3) ���"
		StringsArr := []
		StringsArr.Push("`;[0.5..2.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "set OEKSEPCMeleeCombatEnhancedDamageRaceRedguard to 1.2			`;float (1.2) �������"
		StringsArr := []
		StringsArr.Push("`;[0.5..2.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "set OEKSEPCMeleeCombatEnhancedDamageRaceDarkElf to 1.1			`;float (1.1) Ҹ���� ����"
		StringsArr := []
		StringsArr.Push("`;[0.5..2.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "set OEKSEPCMeleeCombatEnhancedDamageRaceArgonian to 0.95		`;float (0.95) ����������"
		StringsArr := []
		StringsArr.Push("`;[0.5..2.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "set OEKSEPCMeleeCombatEnhancedDamageRaceBreton to 0.85			`;float (0.85) ��������"
		StringsArr := []
		StringsArr.Push("`;[0.5..2.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "set OEKSEPCMeleeCombatEnhancedDamageRaceHighElf to 0.75			`;float (0.75) ������� ����"
		StringsArr := []
		StringsArr.Push("`;[0.5..2.0]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEPCToughness"
		ChangeArr[4] := "`nset OEKSEPCMeleeCombatEnhancedDamageInfo to 1					`;short (1) ��������� ���������� �� ����������� � ����� �������������� ���������� KSE. ��� ����������� ��������� ������ ������� (�� ���������� ������) �������� �������/���������/����������"
		StringsArr := []
		StringsArr.Push("`;[0,1]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEWeaponSelfRecharge"
		ChangeArr[4] := "`nset OEMitigatePCMeleeSneakAttackReflectDamage to 1	`;(1) ������������ ���������� ����, ������� �������� ����� ��� ���������� ������� ����� �������� ��� �� ��� � ���������. �� ���������, ��� ���� ��������� ������������ �����, ��� ������ ����� �������� ����������� ����� �, ��� ������������ ��������, ������� ��� ���� � ������ �����. ��� 1 � ������� ����������� ����� �� ������ �� ����� ����������� ��������� ������������ �����. ����������: ��� � �������� �� 100% ���������� �����"
		StringsArr := []
		StringsArr.Push("`;[0,1][short]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 1
		ChangeArr[3] := "set OEAdditionalHealthBoostLevel"
		ChangeArr[4] := "set OEAdditionalHealthBoostLevel to 5				`;(5) ������� � ������ ������ ����� ����������� ��� � �������� � �������������� ��������� �����"
		Changes.Push(ChangeArr)
		;
		;
		ChangeArr := []
		ChangeArr[0] := "SupremeMagicka.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 1
		ChangeArr[3] := "set SMNewSpells to 0"
		ChangeArr[4] := "set SMNewSpells to 0						`;(0) ��� 1 ��������� � ���� ����� ���������� �� SupremeMagicka, �������� ������, ��� 0 - ������� �� �� ����. ����������, ����������� ����������� SMNewSpells � SMNewSuitableSpells - ��� ��� ������ ������ ����������"
		Changes.Push(ChangeArr)
		

		if (Changes[0] == "")
			Changes.RemoveAt(0)

		ChangesCount := Changes.MaxIndex() + 1
		
		AcceptableChangesCount := 0
		index1 := 0
		Loop, %ChangesCount%
		{
			if (Changes[index1][1] >= OBLIVION_PATCHER_MINIMUM_PATCH_INDEX)
				AcceptableChangesCount++
			index1++
		}
	}
	;;;;;;;;;;

	; ������������ ������ ���-������
	{
		Inis := []
		
		if (APPLICATION_MODE == 0)
		{
			AdditionalPathAndName := []
			AdditionalPathAndName[0] := "\_release ini\files\Data\"
			AdditionalPathAndName[1] := "KeaSkillExtender.ini"
			Inis.Push(AdditionalPathAndName)
			
			AdditionalPathAndName := []
			AdditionalPathAndName[0] := "\_release ini\files\Data\"
			AdditionalPathAndName[1] := "SupremeMagicka.ini"
			Inis.Push(AdditionalPathAndName)
			
			AdditionalPathAndName := []
			AdditionalPathAndName[0] := "\_release ini\files\Data\ini\"
			AdditionalPathAndName[1] := "Oblivion Enhancer.ini"
			Inis.Push(AdditionalPathAndName)
			
			AdditionalPathAndName := []
			AdditionalPathAndName[0] := "\_release ini\files\Data\ini\"
			AdditionalPathAndName[1] := "Oblivion Enhancer (KSE module).ini"
			Inis.Push(AdditionalPathAndName)
			
			AdditionalPathAndName := []
			AdditionalPathAndName[0] := "\_release ini\files\Data\"
			AdditionalPathAndName[1] := "Maskar's Oblivion Overhaul.ini"
			Inis.Push(AdditionalPathAndName)
		}
		else if (APPLICATION_MODE == 1)
		{
			AdditionalPathAndName := []
			AdditionalPathAndName[0] := "\Data\"
			AdditionalPathAndName[1] := "KeaSkillExtender.ini"
			Inis.Push(AdditionalPathAndName)
			
			AdditionalPathAndName := []
			AdditionalPathAndName[0] := "\Data\"
			AdditionalPathAndName[1] := "SupremeMagicka.ini"
			Inis.Push(AdditionalPathAndName)
			
			AdditionalPathAndName := []
			AdditionalPathAndName[0] := "\Data\ini\"
			AdditionalPathAndName[1] := "Oblivion Enhancer.ini"
			Inis.Push(AdditionalPathAndName)
			
			AdditionalPathAndName := []
			AdditionalPathAndName[0] := "\Data\ini\"
			AdditionalPathAndName[1] := "Oblivion Enhancer (KSE module).ini"
			Inis.Push(AdditionalPathAndName)
			
			AdditionalPathAndName := []
			AdditionalPathAndName[0] := "\Data\"
			AdditionalPathAndName[1] := "Maskar's Oblivion Overhaul.ini"
			Inis.Push(AdditionalPathAndName)
		}
		
		if (Inis[0] == "")
			Inis.RemoveAt(0)

		IniFileCount := Inis.MaxIndex() + 1
	}

	; �������� ������������� ���-������, � �������� �������
	index := IniFileCount - 1
	Loop, %IniFileCount%
	{
		IniFileFullPath := ApplicationDir Inis[index][0] Inis[index][1]
		IfNotExist, %IniFileFullPath%
		{
			; ������� ����������� ������ ���-������ ��� ������ ����� � ��������� ������ �� ����� ������, ���� �� � ��� ���
			if (APPLICATION_MODE == 0)
			{
				Path := StrReplace(Inis[index][0], "\_release ini\files")
				FileNameWithPartedPath := Path Inis[index][1]
				FileName := Inis[index][1]
				msgbox ������: ����������� ���� "%FileName%"
				RealeseGamePath := "D:\Games\_������_Oblivion\_�����\__Bild\Oblivion"
				IfExist, %RealeseGamePath%\%FileNameWithPartedPath%
				{
					msgbox ������� "%FileName%" �� ����� ������ %RealeseGamePath%
					FileCreateDir, %ApplicationDir%\_release ini\files\Data\ini
					PatchLocalPath := Inis[index][0] Inis[index][1]
					FileCopy, %RealeseGamePath%\%FileNameWithPartedPath%, %ApplicationDir%\%PatchLocalPath%
				}
			}
			else if (APPLICATION_MODE == 1)
			{
				msgbox ������ ���������: �� ��������� ���� �� ������ %IniFileFullPath%
				Inis.RemoveAt(index)
				IniFileCount--
			}
		}
		index--
	}

	; �������� ������������� ������������ � ��������� ������ �����
	if (APPLICATION_MODE == 0)
	{
		; ����� ���-������ ����������� �������� -				version
		FileRemoveDir, %ApplicationDir%\version, 1
		FileCreateDir, %ApplicationDir%\version
		; ����� ���-������ ��� ������ ��������� ����� -			_generated
		FileRemoveDir, %ApplicationDir%\_generated, 1
		FileCreateDir, %ApplicationDir%\_generated\files\Data
		FileCreateDir, %ApplicationDir%\_generated\files\Data\ini
	}

	; ���������� ��������
	; ������������ ������ �������������� ���-������ ��� �������� ������������ �������� � ��� ���������
	if (APPLICATION_MODE == 0)
	{
		ini_index := 0
		TestInis := []
		Loop, %IniFileCount%
		{
			index2 := 0
			Loop, %PatchesCount%
			{
				AdditionalPathAndName := []
				AdditionalPathAndName[0] := "\version\"
				AdditionalPathAndName[1] := Inis[ini_index][1] index2
				TestInis.Push(AdditionalPathAndName)
				index2++
			}
			ini_index++
		}
		if (TestInis[0] == "")
			TestInis.RemoveAt(0)
		TestIniFileCount := TestInis.MaxIndex() + 1
	}

	; ����� ��������� � ����
	PrintChanges(ApplicationDir, Changes, ChangesCount, Inis, Patches)

	;������ ���-������
	index := 0
	Loop, %IniFileCount%
	{
		IniFileFullPath := ApplicationDir Inis[index][0] Inis[index][1]
		file_format := FileGetFormat(IniFileFullPath)
		if (file_format == "UTF-8") || (file_format == "UTF-8 no BOM")
		{
			FileRead, TempMultistring, *P65001, %IniFileFullPath%
			
			;�������������� �������� ���������� ����� - ���� ������ ����������� �������, �� �� �������� �� ������ (ANSI <> UTF)
			;��� ������ ��� �������� ����� ������� ���� �� ������
			if (InStr(TempMultistring, "�") == 0)
				FileRead, TempMultistring, *P1251, %IniFileFullPath%
		}
		else
		{
			FileRead, TempMultistring, *P1251, %IniFileFullPath%
			
			;�������������� �������� ---||---
			if (InStr(TempMultistring, "�") == 0)
				FileRead, TempMultistring, *P65001, %IniFileFullPath%
		}
		Inis[index][2] := TempMultistring
		index++
	}

	; ��� �������� ������ ��������������� ��������� ANSI (Windows 1251)
	FileEncoding CP1251

	; ������� ��������� ��������� � �����
	InjectedChangesCount := 0
	; ��������� ���-������
	; � �������� ������ ����������� 2 ���� - ������ ��� ��������� �������� ���-����� ������ ������ ������ (���������� ������ = PatchesCount), �� ������ ������ ��������� ������������ ���-����� �� ���� ������ �� ��������� ������ (���������� ������ = PatchesCount, ��������� ����, ����������, �� ��������)
	InisReapetedFilesVersionControlHandling := 0
	if (APPLICATION_MODE == 0)
		mode_loop_count := 2
	else if (APPLICATION_MODE == 1)
		mode_loop_count := 1
	Loop, %mode_loop_count%
	{
		ini_index := 0
		repeated_file_applied_patch_index := 0
		Loop, %IniFileCount%
		{
			; ��������� ���-�����
			
			; ���������� ��������
			; ������ ���������� �������� ���-������ ��� ������� � �������� (PatchesCount) � ��������� (1) �������
			{
				if (InisReapetedFilesVersionControlHandling == 0) && (APPLICATION_MODE == 0)
				{
					LoopsCount := PatchesCount
					repeated_file_maximum_patch_index := 0
				}
				else
				{
					LoopsCount := 1
					repeated_file_maximum_patch_index := Patches.MaxIndex()
				}
			}
			
			Loop, %LoopsCount%
			{
				; ������ ini-����� � ��� �����
				TempMultistring := Inis[ini_index][2]
				
				IniFileNameWithExtension := Inis[ini_index][1]
				
				; ���������� ��������
				; �� ����� ����� ��������� ��������� ����� (��� ������ ������)
				if (InisReapetedFilesVersionControlHandling == 1)
					IniFileNameWithExtension := DeleteLastStringDigits(IniFileNameWithExtension)

				; ���������� ��������� �������
				if (APPLICATION_MODE == 1)
					GuiControl, Text, State, �����������: %IniFileNameWithExtension%

				; ��������������� ����������� ���� `r
				TempMultistring := StrReplace(TempMultistring, "`r")
				
				; ��������� ����� �� ����� (���� �� ������) � ������ ��, ������� ����� ��������� � ����������� ���-�����
				; ���������� ������������ ������� �����, ������� (������������) � �������� ����� ����������� ���������
				; ����������� ������ ����� ����� ����������� ������� = ������ �������������� ����� + 1
				cycle_patch_index := OBLIVION_PATCHER_MINIMUM_PATCH_INDEX
				Loop, %PatchesCount%
				{
					; �� ������ �� ����� ��������� MultiString. ��� �������� ��������� �������� ��������, ����� ���� ��� ������� (continue/break), � �� ������ ����� ������� TempMultistring
					MultiString := TempMultistring
					
					; ���������� ��������
					; � ��������� ������ ��������� ������ �� �����, ������� ��� �� ���� ���������
					; !����������� ���������
					if (InisReapetedFilesVersionControlHandling == 1) && (cycle_patch_index <= repeated_file_applied_patch_index)
					{
						; ����������� ������, ����� �� ���� �������� �����, ��� ����������� ������������
						if (repeated_file_applied_patch_index == PatchesMaxIndex)
						{
							; ���� �����������
							break
						}
						cycle_patch_index++
						continue
					}

					; �������� ������ � ����������� ��� ����� ��� ����� �����������
					; !�������� ���������
					index1 := 0
					CurrentChanges := []
					CurrentChangesCount := 0
					Loop, %ChangesCount%
					{
						ChangeIniFileNameWithExpension := Changes[index1][0]
						ChangePatchIndex := Changes[index1][1]
						if (IniFileNameWithExtension == ChangeIniFileNameWithExpension) && (cycle_patch_index == ChangePatchIndex) && (cycle_patch_index <= repeated_file_maximum_patch_index)
						{
							CurrentChanges.Push(Changes[index1])
							CurrentChangesCount++
						}
						index1++
					}
					if (CurrentChanges[0] == "")
						CurrentChanges.RemoveAt(0)

					; ���� ������ �� ����� ��������, ���� ��� ���-����� ��� ������� ���������
					; !����������� ���������
					if (CurrentChangesCount == 0)
					{
						cycle_patch_index++
						continue
					}
					
					; ������ ��� ��� ���� - � ������ � �������� �������, ����� ������ ��������� �� (CurrentChanges[index1][2] == 3) � ����� (CurrentChanges[index1][2] == 4) ������
					ReverseParsing := 0
					; ��� ����� ���������� ������ ����� TempMultistring � MultiString, ����� - MultiString
					Loop, 2
					{
						; �������� ��������� ����� ������
						MultiString := ""
						RevertedMultiString := ""
						ChangeString := ""
						UnappliedChanges := []
						; ������ ��� �� ������� �������� �� ����� ������
						Loop, Parse, TempMultistring, `n
						{
							ReadedLine = %A_LoopField%
							
							; ��������� ������ ���������, ������� ������ ���� �������. ���� ����, ��� ������� - ������
							; ��������� ��������� �� � ����� ������
							if (UnappliedChanges.MaxIndex() >= 0)
							{
								UnappliedChangesCount := UnappliedChanges.MaxIndex() + 1
								
								CurrentLineType := DefineString(ReadedLine)
								if (CurrentLineType == 1) || (CurrentLineType == 2)
								{
									Loop, %UnappliedChangesCount%
									{
										; �������� ��������� � ����������� �� ����, � ������ ��� �������� ������� ����������� ���������� ���-�����
										if (ReverseParsing == 1)
										{
											; ������ � ����������
											ChangeString := UnappliedChanges[UnappliedChanges.MaxIndex()][0]
											; �������������� ������
											AddStrings := UnappliedChanges[UnappliedChanges.MaxIndex()][1]
											
											MultiString = %MultiString%`n%AddStrings%%ChangeString%
											; ��������� ������ ������ ����� �������� ������� (`n`n) ������ �� ������������
											
											; ������ ������ ���������, ������� ������ ���� �������
											UnappliedChanges.Pop()
											
											if (InisReapetedFilesVersionControlHandling == 0) && (repeated_file_maximum_patch_index == PatchesMaxIndex)
												InjectedChangesCount++
										}
										else
										{
											; ������ � ����������
											ChangeString := UnappliedChanges[0][0]
											; �������������� ������
											AddStrings := UnappliedChanges[0][1]
											
											MultiString = %MultiString%`n%ChangeString%%AddStrings%
											; ��������� ������ ������ ����� �������� ������� (`n`n) ������ �� ������������
											
											; ������ ������ ���������, ������� ������ ���� �������
											UnappliedChanges.RemoveAt(0)
											
											if (InisReapetedFilesVersionControlHandling == 0) && (repeated_file_maximum_patch_index == PatchesMaxIndex)
												InjectedChangesCount++
										}
									}
									
									; ���������� ����������� ���� ������ ������ �� ������������� � ��� ���� 2 ������ �� ������������ "MultiString = %MultiString%`n"
								}
							}
							
							; ��� ���������� ��������-�����, ����������� ��������� �� � ����� ������ � ������ ������ �� ��������� � ������ �������
							index1 := 0
							Loop, %CurrentChangesCount%
							{
								ChangeTaken := 0
								
								; �������� �� ������� ��������� ������-�����
								SearchString := CurrentChanges[index1][3]
								
								; ����������� ���������, �������� ����� ������ ��� ������ ������ � �� ������ ��� �������� �������
								if (InStr(ReadedLine, SearchString) > 0) && (((CurrentChanges[index1][2] == 4) && (ReverseParsing == 0)) || ((CurrentChanges[index1][2] == 3) && (ReverseParsing == 1)))
								{
									ChangeArray := []
									; ������ ���������
									ChangeArray[0] := CurrentChanges[index1][4]
									; �������������� ������ (���� ����)
									ChangeArray[1] := CurrentChanges[index1][5]
									
									; ����, ��������� � ���, ��� �� ������� ��������� � ��� ������ ���� �� CurrentChanges �������
									ChangeTaken := 1
									
									; �������� ��������� � ��������� � ��� ���� � ������������� ������ ���������, ������� ������ ���� �������
									UnappliedChanges.push(ChangeArray)
									
									if (UnappliedChanges[0] == "")
										UnappliedChanges.RemoveAt(0)
								}
								
								; ����������� ���������, �������� �������� �� ��������� ��� �������� ��� ������. ��� ������������� - ������ ��� ���������
								if (InStr(ReadedLine, SearchString) > 0) && ((CurrentChanges[index1][2] == 1) || (CurrentChanges[index1][2] == 2)) && (ReverseParsing == 0)
								{
									; ������ ���������
									ChangeString := CurrentChanges[index1][4]
									; �������������� ������ (���� ����)
									if CurrentChanges[index1][5]
										ChangeString := ChangeString CurrentChanges[index1][5]
									ReadedLine := ChangeString
									
									; ����, ��������� � ���, ��� �� ��������� ��������� � ��� ������ ���� �� CurrentChanges �������
									ChangeTaken := 1
									
									if (InisReapetedFilesVersionControlHandling == 0) && (repeated_file_maximum_patch_index == PatchesMaxIndex)
										InjectedChangesCount++
								}

								if (ChangeTaken == 0)
									index1++
								else
									CurrentChanges.RemoveAt(index1)
							}
							
							; ������� ��� ������ � ��������� `r`n ��������
							{
							if (A_Index == 1)
								MultiString = %MultiString%%ReadedLine%
							else
								MultiString = %MultiString%`n%ReadedLine%
							}
						}
						
						; ������������ ������ ���-����� � �������� �������, ����� ������ ��������� �� ������ �� 1 ������� � ������� � ���������� ��������� �� 2 �������
						TempMultistring := ""
						Loop, Parse, MultiString, `n
						{
							ReadedLine = %A_LoopField%
							; ������� ��� ������ � ��������� `r`n ��������
							if (A_Index == 1)
								TempMultistring = %ReadedLine%%TempMultistring%
							else
								TempMultistring = %ReadedLine%`n%TempMultistring%
						}
						
						; ���������� ���������� ������������������ ����� � ������������ (�������� ���-����)
						if (A_Index == 2)
							MultiString := TempMultistring
						
						ReverseParsing := 1
					}

					; ��������� ������������ - ���� ���� ���������, �� ��� �� ���� �������
					if (UnappliedChanges.MaxIndex() >= 0)
					{
						UnappliedChangesCount := UnappliedChanges.MaxIndex() + 1
						index1 := UnappliedChanges.MaxIndex()
						
						ChangeString := UnappliedChanges[index1][0]
						; ����� �����
						PatchmMark := UnappliedChanges[index1][1]
						; �������������� ������
						AddStrings := UnappliedChanges[index1][2]
						MultiString = %MultiString%`n`n%ChangeString% [&&%PatchmMark%&]%AddStrings%
						UnappliedChanges.Pop()
						
						if (InisReapetedFilesVersionControlHandling == 0) && (repeated_file_maximum_patch_index == PatchesMaxIndex)
							InjectedChangesCount++
					}

					; ������ ��������� � ������ �����
					index1 := 0
					Loop, %CurrentChangesCount%
					{
						if (CurrentChanges[index1][2] == 5)
						{
							; ������ ���������
							ChangeString := CurrentChanges[index1][4]
							; �������������� ������
							AddStrings := CurrentChanges[index1][5]

							; ��������� ��������� � ����
							MultiString = %ChangeString%%AddStrings%`n`n%MultiString%
							
							if (InisReapetedFilesVersionControlHandling == 0) && (repeated_file_maximum_patch_index == PatchesMaxIndex)
								InjectedChangesCount++
						}
						
						index1++
					}

					; ������ ��������� � ����� ����� � ��������� ������ ��������� ������
					{
						Loop, Parse, MultiString, `n
						{
							ReadedLine = %A_LoopField%
							
							if (ReadedLine == "")
								LastEmptyLineFound := 1
							else
								LastEmptyLineFound := 0
						}
						index1 := CurrentChangesCount - 1
						Loop, %CurrentChangesCount%
						{
							if (CurrentChanges[index1][2] == 6)
							{
								; ������ ���������
								ChangeString := CurrentChanges[index1][4]
								; �������������� ������
								AddStrings := CurrentChanges[index1][5]

								; ��������� ��������� � ���� � ������ ������� � ����� ����� ������ ������
								if (LastEmptyLineFound == 1)
								{
									MultiString = %MultiString%`n%ChangeString%%AddStrings%
									LastEmptyLineFound := 0
								}
								else
									MultiString = %MultiString%`n`n%ChangeString%%AddStrings%
								
								if (InisReapetedFilesVersionControlHandling == 0) && (repeated_file_maximum_patch_index == PatchesMaxIndex)
									InjectedChangesCount++
							}
							index1 := index1 - 1
						}
					}
					
					; ���������� ��������
					; �������� �� ���� ����� ���-����� �� ������������ ��� ��������� ���������
					TempMultistring := MultiString
					
					cycle_patch_index++
				}

				; �������� ��������� ������ ������, ���� ��������� ������ �� ������ ������
				MultiStringLength := StrLen(MultiString)
				LastCharacter := SubStr(MultiString, MultiStringLength , 1)
				if (LastCharacter != "`n")
					MultiString = %MultiString%`n

				; ����������� ���� `n � `r`n
				MultiString := StrReplace(MultiString, "`n", "`r`n")

				; ��������� ���-������
				{
					if (InisReapetedFilesVersionControlHandling == 0) && (repeated_file_maximum_patch_index == PatchesMaxIndex)
					{
						if (APPLICATION_MODE == 0)
						{
							Path := StrReplace(Inis[ini_index][0], "\_release ini")
							IniFileFullPath := ApplicationDir "\_generated" Path Inis[ini_index][1]
						}
						else if (APPLICATION_MODE == 1)
							IniFileFullPath := ApplicationDir Inis[ini_index][0] Inis[ini_index][1]
						
						; ���������� ���-������
						IfExist, %IniFileFullPath%
							FileDelete %IniFileFullPath%
						FileAppend, %MultiString%, %IniFileFullPath%
					}

					if (APPLICATION_MODE == 0)
					; ���������� ��������
					{
						if (InisReapetedFilesVersionControlHandling == 0)
						{
							; ���������� ���-������ � ����� version/
							IniFileFullPath := ApplicationDir "\version\" Inis[ini_index][1] repeated_file_maximum_patch_index
							repeated_file_maximum_patch_index++
						} else
						{
							; ���������� ���-������ � ����� version/ � ���������� � ����� ���������� ����� ������ ����� ����� ��� ���������� - ��� ���������� ���������
							Inis[ini_index][1] := Inis[ini_index][1] repeated_file_maximum_patch_index
							IniFileFullPath := ApplicationDir Inis[ini_index][0] Inis[ini_index][1]
						}
						; ���������� ������� ������ ��� ��������� ���-������
						repeated_file_applied_patch_index++
						; ����� ������� ������ ��� ��������� ���-������ �� 0, ���� ����� ����� ������ ��������� ���-������
						if (repeated_file_applied_patch_index >= PatchesCount)
							repeated_file_applied_patch_index := 0

						; ���������� ���-������
						IfExist, %IniFileFullPath%
							FileDelete %IniFileFullPath%
						FileAppend, %MultiString%, %IniFileFullPath%
					} ; ������ �����
					else if (APPLICATION_MODE == 1)
					{
						repeated_file_maximum_patch_index++
					}
				}
			}
			ini_index++
		}
		
		; ���������� ��������
		; ����� �������� ��������� ���-������ ��� ����������� ��� "��������" ���-����� ��� ����, ����� �� ����� ���� ���������� � ��������
		if (APPLICATION_MODE == 0)
		{
			if (InisReapetedFilesVersionControlHandling == 0)
			{
				Inis := TestInis
				IniFileCount := TestIniFileCount
				
				index := 0
				Loop, %IniFileCount%
				{
					IniFileFullPath := ApplicationDir Inis[index][0] Inis[index][1]
					;�� ���� ����� ��� ����� ����� ������ ANSI
					FileRead, TempMultistring, *P1251, %IniFileFullPath%
					Inis[index][2] := TempMultistring
					
					index++
				}

				InisReapetedFilesVersionControlHandling := 1
			}
		}
	}

	; ���������� ��������
	; ��������� ��������� ������
	if (APPLICATION_MODE == 0)
	{
		; ��� ��������� �����, ��������� �� ������ ��������� ���-�����, ������ ����� ���������� ������
		index1 := 0
		RepeatedInis := [[],[]]
		ArrayItemCount := 0
		Loop, %TestIniFileCount%
		{
			InitialFileName := DeleteLastStringDigits(Inis[index1][1])
			VersionFileName := Inis[index1][1]
			FileFullPath := ApplicationDir Inis[index1][0] Inis[index1][1]
			FileGetSize, FileSize, %FileFullPath%
			;�� ���� ����� ��� ����� ����� ������ ANSI
			FileRead, TempMultistring, *P1251, %FileFullPath%
			MD5Hash := MD5(TempMultistring)

			RepeatedInis[ArrayItemCount,0] := VersionFileName
			RepeatedInis[ArrayItemCount,1] := InitialFileName
			RepeatedInis[ArrayItemCount,2] := FileSize
			RepeatedInis[ArrayItemCount,3] := MD5Hash

			ArrayItemCount++
			index1++
		}

		; ��������� ������ ��������� ���-������
		index1 := 0
		IniInitialName := ""
		IniOldInitialName := ""
		IniSize := ""
		IniOldSize := ""
		MultiString := ""
		ErrorFound := 0
		Loop, %ArrayItemCount%
		{
			IniVersionName := RepeatedInis[index1,0]
			IniInitialName := RepeatedInis[index1,1]
			IniSize := RepeatedInis[index1,2]
			IniMD5 := RepeatedInis[index1,3]

			if (IniInitialName == IniOldInitialName)
			{
				if (IniSize == IniOldSize) && (IniMD5 == IniOldMD5)
				{
					if (MultiString == "")
						MultiString = %MultiString%ok	[%IniOldVersionName%][%IniOldSize%][%IniOldMD5%] vs [%IniVersionName%][%IniSize%][%IniMD5%]
					else
						MultiString = %MultiString%`nok	[%IniOldVersionName%][%IniOldSize%][%IniOldMD5%] vs [%IniVersionName%][%IniSize%][%IniMD5%]
						
				}
				else
				{
					if (ErrorFound == 0)
					{
						MultiString = `nFound ERROR in repeated inis!`n`n%MultiString%
						ErrorFound := 1
					}
					
					if (MultiString == "")
						MultiString = %MultiString%!!!!!!!!! ERROR	[%IniOldVersionName%][%IniOldSize%][%IniOldMD5%] vs [%IniVersionName%][%IniSize%][%IniMD5%] !!!!!!!!!
					else
						MultiString = %MultiString%`n!!!!!!!!! ERROR	[%IniOldVersionName%][%IniOldSize%][%IniOldMD5%] vs [%IniVersionName%][%IniSize%][%IniMD5%] !!!!!!!!!
				}
					
			}
			IniOldVersionName := RepeatedInis[index1,0]
			IniOldInitialName := RepeatedInis[index1,1]
			IniOldSize := RepeatedInis[index1,2]
			IniOldMD5 := RepeatedInis[index1,3]
			
			index1++
		}

		; ���� ���� ������, �� �� ��� ��������� ���������
		if (ErrorFound == 1)
			msgbox Found ERROR in repeated inis!
		; ������ ����������� �������� ����������� � checksum_ini.txt
		IfExist, %ApplicationDir%\checksum_ini.txt
			FileDelete %ApplicationDir%\checksum_ini.txt
		FileAppend, %MultiString%, %ApplicationDir%\checksum_ini.txt
	}
	
	; ��������� ����� ������
	if (APPLICATION_MODE == 0)
	{
		IfExist, %ApplicationDir%\_generated\files\Data\Oblivion Enhancer - version.ver
			FileDelete %ApplicationDir%\_generated\files\Data\Oblivion Enhancer - version.ver
		FileAppend, %PatchesMaxIndex%, %ApplicationDir%\_generated\files\Data\Oblivion Enhancer - version.ver
	}
	else if (APPLICATION_MODE == 1)
	{
		IfExist, %ApplicationDir%\Data\Oblivion Enhancer - version.ver
			FileDelete %ApplicationDir%\Data\Oblivion Enhancer - version.ver
		FileAppend, %PatchesMaxIndex%, %ApplicationDir%\Data\Oblivion Enhancer - version.ver
	}

	; ������������ ������ ��������� � ���-����� ���������
	if (APPLICATION_MODE == 0)
		ChangesFileFullPath = %ApplicationDir%\Oblivion Enhancer - ��������� ���-������.txt			; ��������� ����� ��� �������� ������� �� ����� ������
	else if (APPLICATION_MODE == 1)
		ChangesFileFullPath = %ApplicationDir%\Data\Oblivion Enhancer - ��������� ���-������.txt
	IfExist, %ChangesFileFullPath%
	{
		FileRead, Multistring, *P1251, %ChangesFileFullPath%
		FileDelete %ChangesFileFullPath%
		Multistring = `r`n������ ���������: ��������� �����/��������/�������: %ChangesCount%/%AcceptableChangesCount%/%InjectedChangesCount%%Multistring%
		FileAppend, %MultiString%, %ChangesFileFullPath%
		
		; � ��������� ������ ����� ����� ����� ������������ � _generated
		if (APPLICATION_MODE == 0)
		{
			IfExist, %ApplicationDir%\_generated\files\Data\Oblivion Enhancer - ��������� ���-������.txt
				FileDelete %ApplicationDir%\_generated\files\Data\Oblivion Enhancer - ��������� ���-������.txt
			FileAppend, %MultiString%, %ApplicationDir%\_generated\files\Data\Oblivion Enhancer - ��������� ���-������.txt
		}
	}

	; �������� � ��������� ������ ����� � ��������� ���������� �����
	if (APPLICATION_MODE == 0)
	{
		LastPatchVersionName := Patches[PatchesMaxIndex]
		IfExist, %ApplicationDir%\_patch_data\LastPatchVersionName.txt
			FileDelete %ApplicationDir%\_patch_data\LastPatchVersionName.txt
		FileAppend, %LastPatchVersionName%, %ApplicationDir%\_patch_data\LastPatchVersionName.txt
	}
	

	; ����� �� ������� �� ��������� ���������
	if (APPLICATION_MODE == 0)
	{
		SoundPlay, %A_WinDir%\Media\Windows Background.wav
		sleep 1500
	}
	else if (APPLICATION_MODE == 1)
	{
		GuiControl, Text, State, ����������: ���������
		msgbox ��������� ����� ���������!
	}
	exitapp
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; �������:

; �������� ������������� ������ Oblivion Enhancer � ����������� ����������� ��������������� ������ ������
GetInstalledPatchIndex()
{
	global ApplicationDir
	global APPLICATION_MODE
	global OBLIVION_PATCHER_MINIMUM_PATCH_INDEX
	
	if (APPLICATION_MODE == 0)
		VersionFileFullPath = %ApplicationDir%\Oblivion Enhancer - version.ver
	else if (APPLICATION_MODE == 1)
		VersionFileFullPath = %ApplicationDir%\Data\Oblivion Enhancer - version.ver
	IfExist, %VersionFileFullPath%
	{
		FileRead, OblivionVersionFile, *P65001, %VersionFileFullPath%
		
		oblivion_version_file_index := ""
		Loop, Parse, OblivionVersionFile
		{
			if A_LoopField in 0,1,2,3,4,5,6,7,8,9
				oblivion_version_file_index = %oblivion_version_file_index%%A_LoopField%
			else
				break
		}
		if (StrLen(oblivion_version_file_index) > 0)
			oblivion_version_file_index := Floor(oblivion_version_file_index)
		else
			oblivion_version_file_index := -1

		OBLIVION_PATCHER_MINIMUM_PATCH_INDEX := oblivion_version_file_index + 1
	}
	else
	{
		OBLIVION_PATCHER_MINIMUM_PATCH_INDEX := 0
	}
}

; ��������� ��������� �����
FileGetFormat(IniFileFullPath){
  static BOM:={254_255:"UTF-16 BE",255_254:"UTF-16 LE",239_187_191:"UTF-8",0_0_254_255:"UTF-32 BE"
              ,255_254_0_0:"UTF-32 LE",43_47_118_43:"UTF-7",43_47_118_47:"UTF-7",43_47_118_56:"UTF-7"
              ,43_47_118_57:"UTF-7",221_115_102_115:"UTF-EBCDIC",132_49_149_51:"GB 18030"}
  If ("D"!=aFormat:=A_FormatInteger)
    SetFormat,Integer,D
  f:=FileOpen(IniFileFullPath,"r"),f.Pos:=0
  BOM4:=(BOM3:=(BOM2:=f.ReadUChar() "_" f.ReadUChar()) "_" f.ReadUChar()) "_" f.ReadUChar(),f.Close()
  If (aFormat!="D")
    SetFormat,Integer,%aFormat%
  FileRead,f,*c %IniFileFullPath%
  If BOM.HasKey(BOM4)
    return BOM[BOM4]
  else if BOM.HasKey(BOM3)
    return BOM[BOM3]
  else if BOM.HasKey(BOM2)
    return BOM[BOM2]
  FileRead,f,*P65001 %IniFileFullPath%
  FileGetSize,size,%IniFileFullPath%
  return StrLen(f)=size?"ANSI":"UTF-8 no BOM"
}

; ������������ ������-��������� �� ���� ����
ShortString(SwapString)
{
	SearchString := ""
	CharacterFound := 0
	SpaceTabCount := 0
	Loop, Parse, SwapString
	{
		ReadedSymbol = %A_LoopField%
		if (ReadedSymbol != A_Space) && (ReadedSymbol != A_Tab)
			CharacterFound := 1
		if ((ReadedSymbol == A_Space) || (ReadedSymbol == A_Tab)) && (CharacterFound == 1)
		{
			SpaceTabCount++
			CharacterFound := 0
		}
		if SpaceTabCount < 2
			SearchString = %SearchString%%ReadedSymbol%
		else
			break
	}
	return SearchString
}

; ��������� ���� ������, ��� 1 - ������ ������, ��� 2 - ������ � ����� ��������, ����� ������ - ��� 0
DefineString(ReadedLine)
{
	CurrentLineType := 0
	if (ReadedLine == "`n") || (ReadedLine == "`r") || (ReadedLine == "`n`r") || (ReadedLine == "`r`n") || (ReadedLine == "")
	{
		; ��� 1 - ������ ������
		CurrentLineType := 1
	}
	else
	{
		; LineIndex := LineIndex
		Loop, Parse, ReadedLine
		{
			ReadedSymbol = %A_LoopField%
			
			if (ReadedSymbol == A_Space) || (ReadedSymbol == A_Tab)
				continue
			else if  (ReadedSymbol == "`n") || (ReadedSymbol == "`r")
				CurrentLineType := 1
			else
			{
				if (InStr(ReadedLine, "set") == A_Index)
					CurrentLineType := 2
				else
					break
			}
		}
	}
	return CurrentLineType
}

; ������������ ���������� ����� � ���� ��������� ������ ������ �� ������������ ��������
StringsSum(StringsArr, ChangeType)
{
	if (StringsArr[0] == "")
		StringsArr.RemoveAt(0)
	Count := StringsArr.MaxIndex() + 1
	string := ""
	Loop, %Count%
	{
		; ���������� ������ � �������� �������, ���� ��������� �������� �� ������ (���������� ����� � ���� ������ �������������� � �������� �������)
		if (ChangeType == 3)
			string := StringsArr[A_Index - 1] "`n" string
		else
			string := string "`n" StringsArr[A_Index - 1]
	}
	string := string
	return string
}

; ����� � ���� ��������� � ��������� �� ������ � ���-������
PrintChanges(ApplicationDir, Changes, ChangesCount, Inis, Patches)
{
	global APPLICATION_MODE

	InisCount := Inis.MaxIndex() + 1
	PatchesCount := Patches.MaxIndex() + 1
	if (APPLICATION_MODE == 0)
	{
		IfExist, %ApplicationDir%\Oblivion Enhancer - ��������� ���-������.txt
			FileDelete %ApplicationDir%\Oblivion Enhancer - ��������� ���-������.txt
	}
	else if (APPLICATION_MODE == 1)
	{
		IfExist, %ApplicationDir%\Data\Oblivion Enhancer - ��������� ���-������.txt
			FileDelete %ApplicationDir%\Data\Oblivion Enhancer - ��������� ���-������.txt
	}
	MultiString := ""
	HandledChangesCount := 0
	; �������, �.�. ������������� Changes.RemoveAt(index1) ������� ������ ������ �� �� ���������� Changes � ������ � ���� �� ��������
	index1 := 0
	Loop, %ChangesCount%
	{						
		Changes[index1][10] := 0
		index1++
	}

	patch_index := Patches.MaxIndex()
	Loop, %PatchesCount%
	{
		; ������������ ���������� ������� ��������� �������� ���������� ���-������
		TempChanges := []
		index1 := 0
		Loop, %InisCount%
		{
			TempChanges[index1] := []
			index1++
		}
			
		; ���������� ��������� ��� ������������ ������ �����
		index1 := 0
		Loop, %ChangesCount%
		{
			ChangePatchIndex := Changes[index1][1]

			; ���� ������ ����� � ��������� ����� ��������
			if (patch_index == ChangePatchIndex)
			{
				IniName := Changes[index1][0]
				index2 := 0
				Loop, %InisCount%
				{
					SavedIniName := Inis[index2][1]
					if (IniName == SavedIniName) && (Changes[index1][10] == 0)
					{
						TempChanges[index2].Push(Changes[index1])
						Changes[index1][10] := 1
						HandledChangesCount++
						break
					}
					index2++
				}
			}
			index1++
		}
		
		; ���������� � ������� ������� ����� Push
		index1 := 0
		Loop, %InisCount%
		{
			if (TempChanges[index1][0] == "")
				TempChanges[index1].RemoveAt(0)
			index1++
		}

		; �������� ���������, �������� ������
		TempChangesCount := TempChanges.MaxIndex() + 1
		index1 := 0
		TempMultiString := ""
		Loop, %TempChangesCount%
		{
			InnerChangesCount := TempChanges[index1].MaxIndex() + 1
			if (InnerChangesCount > 0)
			{
				index2 := 0
				IniName := TempChanges[index1][index2][0]
				TempMultiString = %TempMultiString%%IniName%:`n
				Loop, %InnerChangesCount%
				{
					ChangeAddType := TempChanges[index1][index2][2]
					ChangeAnchorString := TempChanges[index1][index2][3]
					ChangeString := TempChanges[index1][index2][4]
					ChangeString := StrReplace(ChangeString, "`n", "")
					AddStrings := TempChanges[index1][index2][5]
					if AddStrings
						AddStrings := StrReplace(AddStrings, "`n", "`n                    ")
					if (ChangeAddType >= 3)
					{
						TempMultiString = %TempMultiString%  ��������� ������:`n                    %ChangeString%%AddStrings%`n
					}
					else if (ChangeAddType == 2)
					{
						TempMultiString = %TempMultiString%  �������� ������:`n    ������:         %ChangeAnchorString%`n    ������:         %ChangeString%%AddStrings%`n
					}
					else if (ChangeAddType == 1)
					{
						TempMultiString = %TempMultiString%  � ������ �������� �������� �� ���������:`n    ������:         %ChangeAnchorString%`n    ������:         %ChangeString%%AddStrings%`n
					}
					
					index2++
				}
			}
			
			index1++
		}
		
		; �������� � ������������ �������� ����� - ������ ���� ���� ���-�� ������� ���-�����
		if TempMultiString
			TempMultiString :=  "`n;;;;;;;;;;;;;;;;;;;;;;`n��������� .ini ������ (patch " Patches[patch_index] "):`n" TempMultiString
		
		MultiString = %MultiString%%TempMultiString%
		patch_index--
	}
	
	MultiString = `n������ �����: ��������� �����/�������� � ���� �����: %ChangesCount%/%HandledChangesCount%`n%MultiString%
	
	; ����������� ���� `n � `r`n
	MultiString := StrReplace(MultiString, "`n", "`r`n")
	
	; ����� � ����
	if (APPLICATION_MODE == 0)
		FileAppend, %MultiString%, %ApplicationDir%\Oblivion Enhancer - ��������� ���-������.txt
	else if (APPLICATION_MODE == 1)
		FileAppend, %MultiString%, %ApplicationDir%\Data\Oblivion Enhancer - ��������� ���-������.txt
}

; �������� ��������� ���� � ������
DeleteLastStringDigits(String)
{
	SymbolsCount := StrLen(String)
	Loop, %SymbolsCount%
	{
		LastCharacter := SubStr(String, SymbolsCount, 1)
		if LastCharacter is integer
		{
			SymbolsCount := SymbolsCount - 1
			String := SubStr(String, 1, SymbolsCount)
		}
		else
			break
	}
	return String
}

; ����������� �����
MD5(string, case := False)    ; by SKAN | rewritten by jNizM
{
    static MD5_DIGEST_LENGTH := 16
    hModule := DllCall("LoadLibrary", "Str", "advapi32.dll", "Ptr")
    , VarSetCapacity(MD5_CTX, 104, 0), DllCall("advapi32\MD5Init", "Ptr", &MD5_CTX)
    , DllCall("advapi32\MD5Update", "Ptr", &MD5_CTX, "AStr", string, "UInt", StrLen(string))
    , DllCall("advapi32\MD5Final", "Ptr", &MD5_CTX)
    loop % MD5_DIGEST_LENGTH
        o .= Format("{:02" (case ? "X" : "x") "}", NumGet(MD5_CTX, 87 + A_Index, "UChar"))
    return o, DllCall("FreeLibrary", "Ptr", hModule)
} ;https://autohotkey.com/boards/viewtopic.php?f=6&t=21





























