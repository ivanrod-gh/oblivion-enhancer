;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! this script must have: encoding: ANSI (Windows 1251) *якорь кодировки* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

#SingleInstance Force
AutoTrim, Off
SetBatchLines, -1


; объявление версий патчей и их названий
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

; определение режима работы патчера: 0 - ЛОКАЛЬНЫЙ РЕЖИМ, 1 - УДАЛЕННЫЙ РЕЖИМ
{
	APPLICATION_MODE := ""
	IfExist, %A_ScriptDir%\LOCAL_MARK
	{
		FileRead, Multistring, *P1251, %A_ScriptDir%\LOCAL_MARK
		if (Multistring == "gwse57xkszw36llzw78cr68cr6t8cr68")
		{
			APPLICATION_MODE := 0
			; определение рабочей папки
			ApplicationDir = %A_ScriptDir%
		}
	}
	else
		APPLICATION_MODE := 1
}

; при работе патчера в локальном режиме
if (APPLICATION_MODE == 0)
{
	ApplicationDir = %A_ScriptDir%
	GetInstalledPatchIndex()
	gosub InstallPatch
	
	return
} ; установка патча через установщик
else if (APPLICATION_MODE == 1)
{
	{
		; путь до рабочей папки по умолчанию
		RegRead, ApplicationDir, HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Bethesda Softworks\Oblivion, Installed Path
		; FileRead, ApplicationDir, *P1251, %A_ScriptDir%\_patch_data\TEST_ApplicationDir.txt
		GetInstalledPatchIndex()
		
		; Проверка установленной версии сборки
		if (PatchesMaxIndex < OBLIVION_PATCHER_MINIMUM_PATCH_INDEX)
		{
			msgbox Версия патча меньше или равна версии сборки`nУстановка прекращена
			exitapp
		}

		Gui, Show, X200 Y200 W500 H200, OblivionPatcher
		Gui, Add, Text,, % Patches[PatchesMaxIndex]
		Gui, Add, Text,,
		Gui, Add, Button, gSelectGamePath, Указать месторасположение игры
		Gui, Add, Text,, Путь к игре:
		Gui, Add, Text, W500 vPath
		Gui, Add, Text,,
		Gui, Add, Button, gApplyPatсh vApplyPatсh, Применить патч
		Gui, Add, Text, W500 vState
		Gui, Show, Autosize

		CheckApplicationDir("")
		
		return
	}
	
	ApplyPatсh:
	{
		GuiControl, Disable, ApplyPatсh
		gosub InstallPatch
		
		return
	}

	SelectGamePath:
	{
		FileSelectFolder, SelectedPath
		if SelectedPath
		{
			; указывание рабочей папки
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
		GuiControl, Disable, ApplyPatсh
		BasicOblibionFilesFoundCount := 0
		IfExist, %ApplicationDir%\Oblivion.exe
			BasicOblibionFilesFoundCount++
		IfExist, %ApplicationDir%\obse_loader.exe
			BasicOblibionFilesFoundCount++
		if (BasicOblibionFilesFoundCount != 2)
		{
			if (Mode == "select")
			{
				msgbox В указанной папке не найдены основные исполняемые файлы (Oblivion.exe, obse_loader.exe)
			}
			else
			{
				msgbox Не обнаружена установленная копия игры, необходимо указать папку игры вручную
			}
		}
		else if (BasicOblibionFilesFoundCount == 2)
		{
			GetInstalledPatchIndex()
			GuiControl, Text, Path, %ApplicationDir%
			
			msgbox Игра обнаружена, можно приступать у установке патча
			GuiControl, Enable, ApplyPatсh
		}
	}
}

GuiClose:
ExitApp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


InstallPatch:
{
	; запоминание очередности запуска плагинов на момент ДО применения патча
	FilesAndDates := ""
	Loop, Files, %ApplicationDir%\Data\*.*, F
	{
		if ((A_LoopFileExt == "esp") || (A_LoopFileExt == "esm") && (A_LoopFileName != "oblivion.esm"))
		{
			; !!! пока не используется !!!
			; подкидывание файлов, которых ранее не было в сборке - пропуск файла при учете в FilesAndDates
			; if (A_LoopFileName == "Gloves.esp")
				; continue
			
			FileGetTime, FileDateModified , %A_LoopFileFullPath%, M
			if (FilesAndDates == "")
				FilesAndDates = %FilesAndDates%%FileDateModified%:%A_LoopFileName%
			else
				FilesAndDates = %FilesAndDates%`n%FileDateModified%:%A_LoopFileName%
			
			; !!! пока не используется !!!
			; подкидывание файлов, которых ранее не было в сборке - установка нового файла прямо сразу за определенным файлом (за "файлом-якорем")
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

	;копирование файлов патча (.esp, .esm и 1 .txt)
	if (APPLICATION_MODE == 1)
	{
		GuiControl, Text, State, Копирую файлы
		Loop, Files, %A_ScriptDir%\files\*.*, R
		{
			;копируем только файлы с определенными расширениями
			if (A_LoopFileExt == "esp") || (A_LoopFileExt == "esm") || (A_LoopFileName == "Oblivion Enhancer - обновления.txt") || (A_LoopFileName == "Oblivion Enhancer - описание.txt")
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

	; возвращение плагинам их очередности запуска через изменение их даты модификации
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
	
	;;;;;;;;;;	Патчи (конкретные изменения, якоря, режимы и т.д.)
	{
		;[0] - имя и расширение файла настроек мода
		;[1] - индекс патча (индекс Patches)
		;[2] - типы:
		;	0 - не вносить изменение
		;	1 - изменить значение по умолчанию (заменить строку, если значение соответствует значению по умолчанию)
		;	2 - заменить строку на другую
		;	3 - добавить перед строкой
		;	4 - добавить после строки
		;	5 - вставить в начало файла
		;	6 - вставить в конец файла
		;[3] - базовая строка-якорь, относительно которой и будет осуществляться изменение
		;[4] - добавляемая/заменяющая строка
		;[5] - дополнительные строки с описанием - любой размер
		;[10] - отметка о захвате/не захвате изменения для вывода в файл

		Changes := []
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 6
		ChangeArr[2] := 2
		ChangeArr[3] := "`;конец блока нстроек для системы стрельбы KSE"
		ChangeArr[4] := ""
		StringsArr := []
		StringsArr.Push("`;------------------------------------------------------------------------")
		StringsArr.Push("`;конец блока настроек для системы стрельбы KSE")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 6
		ChangeArr[2] := 2
		ChangeArr[3] := "set KeaAddPCDamage to 0.03"
		ChangeArr[4] := "set OEKSEAddDamageMultPC to 0.075			`;float (0.075) Если > 0, то устанавливается минимальный физический урон по игроку, в результате чего даже слабые противники начинают представлять какую-то опасность. 0.075 означает, что, если физический урон по игроку был менее 7.5% базового значения жизни игрока, то урон становится 7.5%, если же урон больше 7.5%, то усиление урона не задействуется. Совсем слабые противники (крысы, крабы и т.п.) наносят половину от этой величины. Если удар по игроку проходит (т.е. это не удар в щит и игрок не совершил уклонение), то такой дополнительный урон проходит сквозь все защиты."
		Changes.Push(ChangeArr)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 1
		ChangeArr[3] := "set KeaRSMABaseCost to 0	"
		ChangeArr[4] := "set KeaRSMABaseCost to 0.3					`;float (0.5) Если больше ""0"" - базовая стоимость эффекта сопротивления магии меняется"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 2
		ChangeArr[3] := "setgs fArrowSpeedMult to 2000"
		ChangeArr[4] := "setgs fArrowSpeedMult 2000					`;float (v:1500, kse:2000) скорость стрел."
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 2
		ChangeArr[3] := "set KeaRandomWeaponPowerMod	to 1.0"
		ChangeArr[4] := "set KeaRandomWeaponPowerMod to 1.0			`;float (1.0) Модификатор усиления оружия, умножается на итоговую максимальную и минимальную силу модифицированного оружия (итоговое максимальное усиление не может быть меньше +10%, минимальное - +0%)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 4
		ChangeArr[3] := "set KeaRapidFire"
		ChangeArr[4] := "`nset OEKSEAmplifyingSystemBowPCDuration to 6			`;short (6)	Время действия ""беглого огня"" для игрока. Эффект прекращается, если прекратить успешно попадать по врагу"
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
		ChangeArr[4] := "set OEKSEAmplifyingSystemBowActorDuration to 5		`;short (5)	То же, но для НПС"
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
		ChangeArr[4] := "`nset OEKSEArmorAbsorbSkillLimitPC to 1		`;short (1) При 1 ""порог урона"" надетых частей брони зависит от навыка владения этой броней - только для игрока"
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
		ChangeArr[4] := "`nset OEKSEDaggerIgnoreMult to 0.45			`;float (0.45) Удар, нанесенный кинжалом, будет игнорировать 45% любой защиты при спецатаках и удара с тыла/при перехватывающих атаках"
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
		ChangeArr[4] := "set OEKSEShortBladeIgnoreMult to 0.35		`;float (0.35) То же самое, но для короткого меча"
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
		ChangeArr[4] := "set OEKSELongBladeIgnoreMult to 0.25		`;float (0.25) То же самое, но для длинного меча"
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
		ChangeArr[4] := "set OEKSETwoHandBladeIgnoreMult to 0.1		`;float (0.1) То же самое, но для двуручного меча"
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
		ChangeArr[4] := "set OEKSEAddDamageCritChancePC to 20		`;short (20) Шанс того, что удар, наносящий минимальный физический урон по игроку, будет критическим (х1.5)"
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
		ChangeArr[4] := "set OEKSEAddDamagePowCritChancePC to 10		`;short (10) Шанс того, что удар, наносящий минимальный физический урон по игроку, будет усиленным критическим (х2.0), а не обычным критическим"
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
		ChangeArr[4] := "set OEKSERSMAConstEffEnchFactor to 9.0		`;float (9) Если больше 0, то меняется коэффициент зачарования (отвечает за силу зачарования) эффекта ""сопротивление магии"". Только при KeaRSMABaseCost > 0"
		StringsArr := []
		StringsArr.Push("`;Формула: KeaMAGICresMOD * 3 * <текущее значение> + OEKSERSMAConstEffEnchFactor")
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
		ChangeArr[4] := "set OESkillArmorerUse0 to 1.5						`;(1.5) модификатор для навыка оружейник (починка, один удар кузнечным молотом по поврежденной вещи)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 1
		ChangeArr[3] := "set OESkillHeavyArmorUse0 to 2.0"
		ChangeArr[4] := "set OESkillHeavyArmorUse0 to 5.0					`;(5.0) тяжелые доспехи (получить один удар по одному элементу надетой тяжелой брони)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 1
		ChangeArr[3] := "set OESkillLightArmorUse0 to 2.0"
		ChangeArr[4] := "set OESkillLightArmorUse0 to 5.0					`;(5.0) легкие доспехи (получить один удар по одному элементу надетой легкой брони)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 1
		ChangeArr[3] := "set OESkillMercantileUse0 to 3.0"
		ChangeArr[4] := "set OESkillMercantileUse0 to 5.0					`;(5.0) торговля (совершить торговую операцию)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 1
		ChangeArr[3] := "set OESkillSecurityUse0 to 3.0"
		ChangeArr[4] := "set OESkillSecurityUse0 to 10.0						`;(10.0) взлом (взломать замок)"
		Changes.Push(ChangeArr)
		;
		;
		ChangeArr := []
		ChangeArr[0] := "SupremeMagicka.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 4
		ChangeArr[3] := "set SMNewSpells"
		ChangeArr[4] := "set SMNewSuitableSpells to 1				`;(1) При 1 добавляет новые, не ломающие баланса, заклинания из Supreme Magicka продавцам, при 0 - удаляет их"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "SupremeMagicka.ini"
		ChangeArr[1] := 7
		ChangeArr[2] := 4
		ChangeArr[3] := "set SMNewSpells"
		ChangeArr[4] := "set SMAddRestorationSpellsForAnvilMG to 1	`;(1) При 1 анвильскому отделению магов в продажу будет добавлено много заклинаний восстановления, при 0 - добавленные заклинания будут удалены у продавцов"
		Changes.Push(ChangeArr)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 8
		ChangeArr[2] := 2
		ChangeArr[3] := "set KeaRapidFire to 1"
		ChangeArr[4] := "set OEKSERapidFire to 1									`;short (1) Включает/выключает систему ""беглого огня"" для лучников. Если успешно попадать по врагу (выстрел не в щит и не по союзнику), то увеличивается счетчик серии атак луком. Когда счетчик достигает определенного значения, лук начинает наносить дополнительный урон, пробивающий любую защиту. Чем выше счетчик, тем выше дополнительный урон (до определенного предела). Чтобы ""беглый огонь"" заработал, уровень владения луком должен быть не менее ""ученик"" (1 уровень), а при росте уровня владения (специалист, эксперт, мастер) увеличивается предел дополнительного урона. Работает и для игрока, и для его противников"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 8
		ChangeArr[2] := 2
		ChangeArr[3] := "set OEKSEAmplifyingSystemBowPCDuration to 6"
		ChangeArr[4] := "set OEKSERapidFirePCDuration to 8						`;short (8)	Время действия ""беглого огня"" для игрока. Если прекратить успешно попадать по врагу, то счетчик серии атак луком уменьшается и при достижении 0 эффект прекращает действовать. Вне боя счетчик уменьшается очень быстро"
		Changes.Push(ChangeArr)
		;
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 8
		ChangeArr[2] := 2
		ChangeArr[3] := "set OEKSEAmplifyingSystemBowActorDuration to 5"
		ChangeArr[4] := "set OEKSERapidFireNPCDuration to 6						`;short (6)	То же, но для НПС/существ"
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
		ChangeArr[4] := "set keaTimePenalties.KeaHMFRestHealthMin to 5		`;short (12) зелье излечение такой мощности восстанавливает 1 ед.Израненности/2сек. Чем мощнее тем быстрее"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 1
		ChangeArr[3] := "set keaTimePenalties.KeaHMFRestMagicMin to 8	"
		ChangeArr[4] := "set keaTimePenalties.KeaHMFRestMagicMin to 4		`;short (8) зелье магии такой мощности восстанавливает 1 ед.Маг.истощ/2сек. Чем мощнее тем быстрее"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 1
		ChangeArr[3] := "set keaTimePenalties.KeaHMFRestFatigueMin to 25	"
		ChangeArr[4] := "set keaTimePenalties.KeaHMFRestFatigueMin to 10		`;short (25) зелье энергии такой мощности восстанавливает 1 ед.Усталости/2сек. Чем мощнее тем быстрее"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 1
		ChangeArr[3] := "set KeaMagickaRestoreMult to 5.0	"
		ChangeArr[4] := "set KeaMagickaRestoreMult to 2.0			`;float (10.0) - модификатор восстановления во время отдыха/сна Маны (Магического истощения)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 1
		ChangeArr[3] := "set OEKSEAddDamageMultPC to 0.075	"
		ChangeArr[4] := "set OEKSEAddDamageMultPC to 0.06			`;float (0.06) Если > 0, то устанавливается минимальный физический урон по игроку, в результате чего даже слабые противники начинают представлять какую-то опасность. 0.06 означает, что, если физический урон по игроку был менее 6% базового значения жизни игрока, то урон становится 6%, если же урон больше 6%, то усиление урона не задействуется. Совсем слабые противники (крысы, крабы и т.п.) наносят половину от этой величины. Если удар по игроку проходит (т.е. это не удар в щит и игрок не совершил уклонение), то такой дополнительный урон проходит сквозь все защиты."
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 1
		ChangeArr[3] := "set KeaResistNormWeapSystem to 1	"
		ChangeArr[4] := "set KeaResistNormWeapSystem to 0			`;short (1) вкл/выкл систему сопротивления обычному оружию KSE. Если=1 - только серебро, "
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 2
		ChangeArr[3] := "set OEKSEArmorAbsorbSkillLimitPC"
		ChangeArr[4] := "set OEKSEArmorAbsorbSkillDependencePC to 1	`;short (1) При 1 ""порог урона"" надетых частей брони зависит от навыка владения этой броней - только для игрока"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFire"
		ChangeArr[4] := "`nset OEKSERapidFireDistance to 1200						`;short (1200) Максимальная дистанция между стрелком и целью, на которой будет работать ""беглый огонь"" (т.е. применяться дополнительный урон и учитываться счетчик серии атак луком)"
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
		ChangeArr[4] := "`nset OEKSERapidFireBowExtraDamageMinSequence to 4		`;short (4) Минимальное значение счетчика серии атак для дополнительного урона при выстреле из лука"
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
		ChangeArr[4] := "`nset OEKSERapidFireLev1PCShortDistanceCounter to 1		`;short (1) Такое значение прибавляется к счетчику серии атак луком для игрока на 1 уровне способности при попадании по врагу на близкой дистанции (до OEKSERapidFireDistance * 0.5). На дистанции от OEKSERapidFireDistance * 0.67 до OEKSERapidFireDistance к счетчику всегда прибавляется 1, а между OEKSERapidFireDistance * 0.5 и OEKSERapidFireDistance * 0.67 есть шанс прибавки к счетчику не 1, а значения OEKSERapidFireLev1PCShortDistanceCounter (чем меньше дистанция, тем выше шанс)"
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
		ChangeArr[4] := "set OEKSERapidFireLev2PCShortDistanceCounter to 2		`;short (2) --||-- на 2 уровне способности"
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
		ChangeArr[4] := "set OEKSERapidFireLev3PCShortDistanceCounter to 3		`;short (3) --||-- на 3 уровне способности"
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
		ChangeArr[4] := "set OEKSERapidFireLev4PCShortDistanceCounter to 3		`;short (3) --||-- на 4 уровне способности"
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
		ChangeArr[4] := "set OEKSERapidFireLev1NPCShortDistanceCounter to 1		`;short (1) То же, но для НПС/существ"
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
		ChangeArr[4] := "set OEKSERapidFireLev2NPCShortDistanceCounter to 1		`;short (1) --||-- на 2 уровне способности"
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
		ChangeArr[4] := "set OEKSERapidFireLev3NPCShortDistanceCounter to 2		`;short (2) --||-- на 3 уровне способности"
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
		ChangeArr[4] := "set OEKSERapidFireLev4NPCShortDistanceCounter to 2		`;short (2) --||-- на 4 уровне способности"
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
		ChangeArr[4] := "`nset OEKSERapidFireLev1BowExtraDamageMaxSequence to 8	`;short (8) Ограничитель счетчика серии атак луком для подсчета значения дополнительного урона на 1 уровне способности. Такой урон игнорирует броню"
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
		ChangeArr[4] := "set OEKSERapidFireLev2BowExtraDamageMaxSequence to 12	`;short (12) --||-- на 2 уровне способности"
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
		ChangeArr[4] := "set OEKSERapidFireLev3BowExtraDamageMaxSequence to 16	`;short (16) --||-- на 3 уровне способности. Значение 16 соответствует наносимому дополнительному урону, равному урону лука + урону стрелы, которые выводятся в инвентаре"
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
		ChangeArr[4] := "set OEKSERapidFireLev4BowExtraDamageMaxSequence to 20	`;short (20) --||-- на 4 уровне способности"
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
		ChangeArr[4] := "`nset OEKSERapidFirePCCritical to 1						`;short (1) Дает возможность игроку нанести критический урон при нанесении дополнительного урона"
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
		ChangeArr[4] := "set OEKSERapidFireNPCCritical to 0						`;short (0) То же самое, но для НПС/существ"
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
		ChangeArr[4] := "`nset OEKSERapidFireCriticalMinSequence to 10				`;short (10) Минимальное значение счетчика серии атак для дополнительного критического урона при выстреле из лука. Пока счетчик ниже этого значения, критический урон не наносится"
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
		ChangeArr[4] := "`nset OEKSERapidFireLev1CriticalMod to 2.0				`;float (2.0) Модификатор дополнительного критического урона на 1 уровне способности"
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
		ChangeArr[4] := "set OEKSERapidFireLev2CriticalMod to 2.5				`;float (2.5) --||-- на 2 уровне способности"
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
		ChangeArr[4] := "set OEKSERapidFireLev3CriticalMod to 3.0				`;float (3.0) --||-- на 3 уровне способности"
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
		ChangeArr[4] := "set OEKSERapidFireLev4CriticalMod to 3.5				`;float (3.5) --||-- на 4 уровне способности"
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
		ChangeArr[4] := "`nset OEKSERapidFireMinCriticalChance to 25				`;short (25) Минимальный шанс нанести критический урон"
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
		ChangeArr[4] := "set OEKSERapidFireMaxCriticalChance to 80				`;short (80) Максимальный шанс нанести критический урон"
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
		ChangeArr[4] := "`nset OEKSERapidFireLev1PCCounterDecrease to 4			`;short (4) На такое значение уменьшится счетчик серии атак игрока на 1 уровне способности в бою, если прекратить успешно попадать по врагам в течение времени, указанном в OEKSERapidFirePCDuration. Вне боя счетчик уменьшается гораздо быстрее"
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
		ChangeArr[4] := "set OEKSERapidFireLev2PCCounterDecrease to 3			`;short (3) --||-- на 2 уровне способности"
		StringsArr := []
		StringsArr.Push("`;[1..10]")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSERapidFireNPCDuration"
		ChangeArr[4] := "set OEKSERapidFireLev3PCCounterDecrease to 2			`;short (2) --||-- на 3 уровне способности"
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
		ChangeArr[4] := "set OEKSERapidFireLev4PCCounterDecrease to 2			`;short (2) --||-- на 4 уровне способности"
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
		ChangeArr[4] := "set OEKSERapidFireLev1NPCCounterDecrease to 4			`;short (4) То же самое, но для НПС/существ"
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
		ChangeArr[4] := "set OEKSERapidFireLev2NPCCounterDecrease to 4			`;short (4) --||-- на 2 уровне способности"
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
		ChangeArr[4] := "set OEKSERapidFireLev3NPCCounterDecrease to 3			`;short (3) --||-- на 3 уровне способности"
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
		ChangeArr[4] := "set OEKSERapidFireLev4NPCCounterDecrease to 3			`;short (3) --||-- на 4 уровне способности"
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
		ChangeArr[4] := "set OEKSEEmpAgilityMod to 5.0				`;float (5.0) Сколько дает ""Обучаемости"" каждая единица ловкости (начиная с 40 ловкости) при активной способности ""Волшебный стрелок"""
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
		ChangeArr[4] := "set OEKSEFortificationAbility to 1								`;(1) дает доступ к способности ""Укрепление"". Эта способность позволяет игрокам-воинам ближнего боя эффективнее расправляться с врагами, но ограничивает магические способности. При этом блокируется срабатывание ""всплесков адреналина"". Для включения/выключения способности необходимо использовать заклинание ""KSE: Укрепление"""
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
		ChangeArr[4] := "`nset OEKSEFortificationAbKnockdown to 1							`;(1) периодически дает игроку возможность опрокинуть соперника(ов) на землю при ударе по ним оружием ближнего боя"
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
		ChangeArr[4] := "`nset OEKSEFortificationAbBaseCooldownTime to 15					`;(15) базовое время отката способности укрепления сбивать с ног врагов. На итоговое время влияют различные условия (количество врагов вокруг, сколько ударов по врагу было сделано и т.д.), но считается все от этой величины"
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
		ChangeArr[4] := "`nset OEKSEFortificationAbLev1Enemy1KnockdownChance to 100		`;(100) шанс того, что при ударе по врагу (после того, как игрока охватит оранжевое свечение) будет сбита с ног основная цель удара на 1 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev2Enemy1KnockdownChance to 100		`;(100) ---||--- будет сбита с ног основная цель удара на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev3Enemy1KnockdownChance to 100		`;(100) ---||--- будет сбита с ног основная цель удара на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev4Enemy1KnockdownChance to 100		`;(100) ---||--- будет сбита с ног основная цель удара на 4 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev1Enemy2KnockdownChance to 0			`;(0) шанс того, что при ударе по врагу будет сбит с ног второй враг на 1 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev2Enemy2KnockdownChance to 50			`;(50) ---||--- будет сбит с ног второй враг на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev3Enemy2KnockdownChance to 80			`;(80) ---||--- будет сбит с ног второй враг на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev4Enemy2KnockdownChance to 90			`;(90) ---||--- будет сбит с ног второй враг на 4 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev1Enemy3KnockdownChance to 0			`;(0) шанс того, что при ударе по врагу будет сбит с ног третий враг на 1 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev2Enemy3KnockdownChance to 10			`;(10) ---||--- будет сбит с ног третий враг на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev3Enemy3KnockdownChance to 20			`;(20) ---||--- будет сбит с ног третий враг на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev4Enemy3KnockdownChance to 35			`;(35) ---||--- будет сбит с ног третий враг на 4 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev1Enemy4KnockdownChance to 0			`;(0) шанс того, что при ударе по врагу будет сбит с ног четвертый враг на 1 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev2Enemy4KnockdownChance to 0			`;(0) ---||--- будет сбит с ног четвертый враг на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev3Enemy4KnockdownChance to 10			`;(10) ---||--- будет сбит с ног четвертый враг на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev4Enemy4KnockdownChance to 20			`;(20) ---||--- будет сбит с ног четвертый враг на 4 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev1Enemy5KnockdownChance to 0			`;(0) шанс того, что при ударе по врагу будет сбит с ног пятый враг на 1 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev2Enemy5KnockdownChance to 0			`;(0) ---||--- будет сбит с ног пятый враг на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev3Enemy5KnockdownChance to 0			`;(0) ---||--- будет сбит с ног пятый враг на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev4Enemy5KnockdownChance to 10			`;(10) ---||--- будет сбит с ног пятый враг на 4 уровне способности"
		StringsArr := []
		StringsArr.Push("`;[0..100][short] все")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEFortificationAbBulletTime to 1							`;(1) использовать замедление в бою"
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
		ChangeArr[4] := "`nset OEKSEFortificationAbLev1Enemy1BulletTimeStrength to 0.8		`;(0.8) степень замедления при 1 враге поблизости и 1 уровне способности. На 1 уровне способности большее количество врагов никак на способность не влияет степень замедления такая же. как и при 1 враге поблизости"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev2Enemy1BulletTimeStrength to 0.8		`;(0.8) степень замедления при 1 враге поблизости и 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev3Enemy1BulletTimeStrength to 0.8		`;(0.8) степень замедления при 1 враге поблизости и 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev4Enemy1BulletTimeStrength to 0.8		`;(0.8) степень замедления при 1 враге поблизости и 4 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev2Enemy2BulletTimeStrength to 0.7		`;(0.7) степень замедления при 2 врагах поблизости и 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] :=    "set OEKSEFortificationAbility"
		ChangeArr[4] :=    "set OEKSEFortificationAbLev3Enemy2BulletTimeStrength to 0.7		`;(0.7) степень замедления при 2 врагах поблизости и 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev4Enemy2BulletTimeStrength to 0.7		`;(0.7) степень замедления при 2 врагах поблизости и 4 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev3Enemy3BulletTimeStrength to 0.65	`;(0.65) степень замедления при 3 врагах поблизости и 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev4Enemy3BulletTimeStrength to 0.65	`;(0.65) степень замедления при 3 врагах поблизости и 4 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEFortificationAbLev4Enemy4BulletTimeStrength to 0.6		`;(0.6) степень замедления при 4 врагах поблизости и 4 уровне способности"
		StringsArr := []
		StringsArr.Push("`;[0.5..0.95][float] все, с шагом 0.05")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEFortificationAbFortify to 1							`;(1) использовать положительный усиливающий эффект (восстановление здоровья, сопротивления и т.д.) на игроке"
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
		ChangeArr[4] := "`nset OEKSEFortificationPlayRechargeEffect to 1					`;(1) включить/выключить шейдер визуального эффекта готовности Укрепления сбить противников с ног"
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
		ChangeArr[4] := "`n`nset OEKSEArcaneArcherAbility to 1								`;(1) дает доступ к способности ""Волшебный стрелок"". Эта способность позволяет игрокам-лучникам останавливать и замедлять врагов. В оригинальном Обливионе лучник без ипользования магии (деморализация, паралич, бешенство и т.д.) или оружия ближнего боя мало что мог сделать с противником, который до него добрался - Волшебный стрелок позволяет держать врагов на расстоянии. Для включения/выключения способности необходимо использовать заклинание ""KSE: Волшебный стрелок"". Использование этой способности не запрещает использование обычной магии. Т.к. останавливающие и замедляющие умения стоят % от общей маны, то увеличение интеллекта негативно скажется на способности не давать врагам добраться до лучника. Сила воли вообще не окажет никакого влияния - для этой способности используется регенерация маны от ловкости. Модификаторы стоимости умений, описанные ниже, применяются только к умениям Волшебного стрелка. Если враг блокирует щитом и повернут в сторону игрока, то умения не сработают, также они не сработают на целях с иммунитетом к магии"
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
		ChangeArr[4] := "`nset OEKSEArcaneArcherDebuffDuration to 3.0						`;(3.0) базовая длительность умений на врагах, т.е. столько времени действует замедление или остановка врага. Если прекратить успешно попадать по врагу, то умение прекратит действовать и враг освободится"
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
		ChangeArr[4] := "`nset OEKSEArcaneArcherLev1ContinuousDebuffDuration to 3			`;(3) когда умение повторно попадает в цель, которая все еще находится под действием умения, то вместо базовой длительности будет применяться это значение. Это дополнительная длительность на 1 уровне способности - по умолчанию она равна базовой длительности. Эта длительность применяется только в том случае, если цель находится на средней или дальней дистанции от игрока"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev2ContinuousDebuffDuration to 5			`;(5) --||-- на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev3ContinuousDebuffDuration to 6			`;(6) --||-- на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev4ContinuousDebuffDuration to 7			`;(7) --||-- на 4 уровне способности"
		StringsArr := []
		StringsArr.Push("`;[0..20][short] все")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherLev1ExtraContinuousDebuffDuration to 3		`;(3) дополнительная длительность на 1 уровне способности для тех случаев, когда враг подошел слишком близко и повторно применяется останавливающее умение"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev2ExtraContinuousDebuffDuration to 7		`;(7) --||-- на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev3ExtraContinuousDebuffDuration to 9		`;(8) --||-- на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev4ExtraContinuousDebuffDuration to 11	`;(11) --||-- на 4 уровне способности"
		StringsArr := []
		StringsArr.Push("`;[0..20][short] все")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherShortDistanceValue to 500					`;(500) базовое значение короткой дистанции. Если расстояние до врага такое или меньше, то применяется останавливающее умение"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLongDistanceValue to 1000					`;(1000) базовое значение дальней дистанции. Если расстояние до врага такое или больше, то применяется замедляющее умение средней силы. Если враг оказался на расстоянии от OEKSEArcaneArcherShortDistanceValue до OEKSEArcaneArcherLongDistanceValue, то считается, что он на средней дистанции и применяется сильное замедляющее умение"
		StringsArr := []
		StringsArr.Push("`;[100..2000][short] все")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherShortDistanceSpellCostMod to 0.3			`;(0.3) модификатор стоимости умений, применяемых на короткой дистанции. Стоимость умения = общее количество маны * модификатор, т.е. для использования умения забирается ПРОЦЕНТ (30%) от общего количества маны! При этом регенерация Волшебного стрелка не зависит от общего количества маны. Соответственно, чем больше маны, тем реже применяются умения Волшебного стрелка - и наоборот"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherAverageDistanceSpellCostMod to 0.15		`;(0.15) модификатор стоимости умений, применяемых на средней дистанции"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLongDistanceSpellCostMod to 0.075			`;(0.075) модификатор стоимости умений, применяемых на дальней дистанции"
		StringsArr := []
		StringsArr.Push("`;[0.0..1.0][float] все")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherLev1CounterAttackCostMod to 1.0			`;(1.0) модификатор стоимости умений, применяемых во время атаки врага на 1 уровне способности. По умолчанию для 1 уровня стоимость * 1, т.е. не меняется"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev2CounterAttackCostMod to 0.5			`;(0.5) --||-- на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev3CounterAttackCostMod to 0.45			`;(0.45) --||-- на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev4CounterAttackCostMod to 0.4			`;(0.4) --||-- на 4 уровне способности"
		StringsArr := []
		StringsArr.Push("`;[0.0..5.0][float] все")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherLev1RepeatCostMod to 0.8					`;(0.8) модификатор стоимости умений при применении по врагу, который уже находится под воздействием умений Волшебного стрелка, на 1 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev2RepeatCostMod to 0.7					`;(0.7) --||-- на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev3RepeatCostMod to 0.65					`;(0.65) --||-- на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev4RepeatCostMod to 0.6					`;(0.6) --||-- на 4 уровне способности"
		StringsArr := []
		StringsArr.Push("`;[0.0..5.0][float] все")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherLev1LevelDiffCostMod to 2.0				`;(2.0) модификатор стоимости умений при применении по врагу, который значительно превышает игрока по уровню, на 1 уровне способности. Стоимость плавно растет начиная с разницы в 5 уровней, при разнице в 15 уровней и выше стоимость максимальна"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev2LevelDiffCostMod to 1.5				`;(1.5) --||-- на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev3LevelDiffCostMod to 1.25				`;(1.25) --||-- на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev4LevelDiffCostMod to 1.0				`;(1.0) --||-- на 4 уровне способности"
		StringsArr := []
		StringsArr.Push("`;[1.0..5.0][float] все")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherLev1AdditionalTargets to 0					`;(0) сколько дополнительных целей может поразить останавливающее или замедляющее умение на 1 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev2AdditionalTargets to 1					`;(1) --||-- на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev3AdditionalTargets to 2					`;(2) --||-- на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev4AdditionalTargets to 3					`;(3) --||-- на 4 уровне способности"
		StringsArr := []
		StringsArr.Push("`;[0..10][short] все")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherLev1DebuffArea to 0						`;(0) область поражения умений на 1 уровне способности. По умолчанию на 1 уровне способности умения бьют только по основной цели"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev2DebuffArea to 150						`;(150) --||-- на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev3DebuffArea to 175						`;(175) --||-- на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEArcaneArcherLev4DebuffArea to 200						`;(200) --||-- на 4 уровне способности"
		StringsArr := []
		StringsArr.Push("`;[0..1000][short] все")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEArcaneArcherIgnoreWeakActors to 1						`;(1) игнорировать слабых противников (крыс, крабов и т.д.) при применении умений"
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
		ChangeArr[4] := "`nset OEKSEArcaneArcherMagickaReturnMult to 0.05					`;(0.05) модификатор, отвечающий за регенерацию маны - чем он больше, тем больше регенерация маны и наоборот"
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
		ChangeArr[4] := "`n`nset OEKSEBattleMagicAbility to 1								`;(1) дает доступ к способности ""Боевая магия"". Как и в случае с лучником, враги, дошедшие до мага, делают магу нехорошо, если только он не отмахается мечом. Т.к. мана не бесконечна, то редко когда маг в состоянии не допустить до себя большую группу врагов, соответственно, что для лучника, что для мага, игра толкает на обязательный гибрид с воином и физическое оружие. Эта способность усиливает защиту мага постоянным магическим щитом, улучшает блокирование ударов оружием или щитом и вместо нанесения физического урона оружием ближнего боя игрок периодически (раз в несколько секунд) может поджечь магическим пламенем всех окружающих НПС и существ, кроме себя. Используемое оружие ближнего боя при этом перестает наносить физический урон, сбивать с ног и т.п. На урон магическим вопсламенением влияют навыки разрушения или мистицизма (который выше) и урон самого оружия. Значение силы и навык владения оружием на урон воспламенения не влияют. Посмотреть урон воспламенения можно в описании оружия, когда способность активна. Параметры OEKSEBattleMagic* никакиим образом на магию игрока не влияют"
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
		ChangeArr[4] := "`nset OEKSEBattleMagicBurnBaseDamage to 4.0						`;(4.0) модификатор базового урон магического воспламенения. Урон растянут по времени, в первую секунду наносится максимальное значение, в последнюю - 1 (одна единица в секунду). При высоких навыках разрушения/мистицизма и уроне самого оружия (в том числе - из-за модификатора + % Атк.) наносит значительный урон в большой области"
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
		ChangeArr[4] := "`nset OEKSEBattleMagicLev1Area to 200								`;(200) область действия магического воспламенения на 1 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev2Area to 250								`;(250) --||-- на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev3Area to 300								`;(300) --||-- на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev4Area to 400								`;(400) --||-- на 4 уровне способности"
		StringsArr := []
		StringsArr.Push("`;[100..1000][short] все")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEBattleMagicBurnBaseDuration to 10.0					`;(10.0) базовая длительность магического воспламенения. Чем больше длительность, тем больше наносится урона за весь промежуток времени и тем проще поджечь врагов повторно"
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
		ChangeArr[4] := "`nset OEKSEBattleMagicBurnLev1AdditionalDuration to 0.0			`;(0.0) дополнительная длительность магического воспламенения на 1 уровне способности. Вступает в силу в конце действия, урона почти не наносит, но дает возможность поджечь врагов еще раз"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicBurnLev2AdditionalDuration to 0.0			`;(0.0) --||-- на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicBurnLev3AdditionalDuration to 2.5			`;(2.5) --||-- на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicBurnLev4AdditionalDuration to 5.0			`;(5.0) --||-- на 4 уровне способности"
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
		ChangeArr[4] := "`nset OEKSEBattleMagicBurnMaxCooldownTime to 10					`;(10) максимальное время восстановления магического поджога. Время восстановления можно сократить за счет траты маны и блокирования вражеских атак"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicBurnMinCooldownTime to 6					`;(6) минимальное время восстановления магического поджога, ничем не сокращается"
		StringsArr := []
		StringsArr.Push("`;[1..20][short] все")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEBattleMagicLev1RepeatDamageMod to 0.5					`;(0.5) модификатор урона при повторном магическом воспаменении одной и той же цели на 1 уровне способности. По умолчанию на 1 уровне способности повторное воспламенение не дает дополнительного урона"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev2RepeatDamageMod to 0.85					`;(0.85)  --||-- на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev3RepeatDamageMod to 1.0					`;(1.0)  --||-- на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev4RepeatDamageMod to 1.15					`;(1.15)  --||-- на 4 уровне способности"
		StringsArr := []
		StringsArr.Push("`;[0.5..5.0][float] все")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEBattleMagicBurnBlockStagger to 1						`;(1) дает возможность при блокировании атаки подожженного магическим воспламенением противника вывести его из строя на короткий промежуток времени и немного продлить на нем длительного магического поджога"
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
		ChangeArr[4] := "`nset OEKSEBattleMagicBurnStagger to 1							`;(1) дает возможность периодически выводить подожженных магическим воспламенением противников из строя"
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
		ChangeArr[4] := "`nset OEKSEBattleMagicLev1PrimaryTargetStaggerChance to 35		`;(35) при нанесении удара оружием ближнего боя дает шанс кратковременно вывести из строя главную цель магического воспламенения (т.е. того, по кому пришелся удар) на 1 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev2PrimaryTargetStaggerChance to 40		`;(40) --||-- на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev3PrimaryTargetStaggerChance to 50		`;(50) --||-- на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev4PrimaryTargetStaggerChance to 55		`;(55) --||-- на 4 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev1SecondaryTargetStaggerChance to 15		`;(15) при нанесении удара оружием ближнего боя дает шанс кратковременно вывести из строя второстепенные цели магического воспламенения на 1 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev2SecondaryTargetStaggerChance to 20		`;(20) --||-- на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev3SecondaryTargetStaggerChance to 25		`;(25) --||-- на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev4SecondaryTargetStaggerChance to 25		`;(25) --||-- на 4 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev1BurnMinStaggerChance to 20				`;(20) минимальный шанс кратковременно вывести из строя противников, на которых действует магическое воспламенение на 1 уровне способности. Шанс растет с каждой секундой и, после кратковременного выхода противника из строя, он на несколько секунд не подвержен этому эффекту"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev2BurnMinStaggerChance to 25				`;(25) --||-- на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev3BurnMinStaggerChance to 30				`;(30) --||-- на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev4BurnMinStaggerChance to 35				`;(35) --||-- на 4 уровне способности"
		StringsArr := []
		StringsArr.Push("`;[0..100][short] все")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEBattleMagicDamageToImmune to 1							`;(1) дает возможность магическому воспламенению наносить повреждения противникам с иммунитетом к магии (100% сопротивление, поглощение, отражение магии)"
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
		ChangeArr[4] := "`nset OEKSEBattleMagicLev1DamageToImmuneMod to 0.0				`;(0.0) модификатор урона магического воспламенения по иммунным к магии целям на 1 уровне способности. По умолчанию на 1 уровне способности магическое воспламенение не наносит урона таким целям и, в принципе, не действует на них"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev2DamageToImmuneMod to 0.25				`;(0.25) --||-- на 2 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev3DamageToImmuneMod to 0.35				`;(0.35) --||-- на 3 уровне способности"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "set OEKSEBattleMagicLev4DamageToImmuneMod to 0.5				`;(0.5) --||-- на 4 уровне способности"
		StringsArr := []
		StringsArr.Push("`;[0.0..1.0][float] все")
		ChangeArr[5] := StringsSum(StringsArr, ChangeArr[2])
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer (KSE module).ini"
		ChangeArr[1] := 9
		ChangeArr[2] := 4
		ChangeArr[3] := "set OEKSEFortificationAbility"
		ChangeArr[4] := "`nset OEKSEBattleMagicSpentMagickaRechargeValue to 100			`;(100) такое количество потраченной маны полностью перезарядит магическое воспламенение. Тратить ману можно и ""про запас"", в самом начале боя выплеснув на врага весь магический резерв и получая тем самым возможность максимально снизить время восстановления магического воспламенения на несколько ударов вперед"
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
		ChangeArr[4] := "`nset OEKSEBattleMagicPlayRechargeEffect to 1						`;(1) включить/выключить шейдер синего цвета, который сигнализирует об окончании перезарядки магического воспламенения"
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
		ChangeArr[4] := "`nset OEKSEAddTargetHealthAbsorbSpells to 1						`;(1) добавляет в продажу заклинания поглощения жизни на удаленную цель"
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
		ChangeArr[4] := "`nset OEKSERapidFireCriticalChanceMod to 1				`;float (1) Модификатор шанса нанести критический урон, умножается на (текущее значение счетчика серии атак - минимальное значение счетчика серии атак) и складывается с минимальным шансом нанести критический урон"
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
		ChangeArr[4] := "set OEKSERapidFireLev2PCCounterDecrease to 3			`;short (3) --||-- на 2 уровне способности"
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
		ChangeArr[4] := "set OESkillAthleticsUse0 to 4.0						`;(4.0) атлетика (секунда бега)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer.ini"
		ChangeArr[1] := 10
		ChangeArr[2] := 1
		ChangeArr[3] := "set OESkillAthleticsUse1 to 2.0"
		ChangeArr[4] := "set OESkillAthleticsUse1 to 4.0						`;(4.0) атлетика (секунда плавания)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "Oblivion Enhancer.ini"
		ChangeArr[1] := 10
		ChangeArr[2] := 1
		ChangeArr[3] := "set OESkillMysticismUse1 to 2.0"
		ChangeArr[4] := "set OESkillMysticismUse1 to 1.25					`;(1.25) мистицизм (ударить цель заклинанием мистицизма)"
		Changes.Push(ChangeArr)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 11
		ChangeArr[2] := 2
		ChangeArr[3] := "set KeaPCToughtness to 1"
		ChangeArr[4] := "set OEKSEPCToughness to 1										`;short (1) С развитием навыков персонаж игрока начинает лучше понимать, как вести бой. Это дает ему возможность противостоять противникам и оставаться на ногах даже в самых жарких схватках. Чем больше знает и умеет игрок, тем реже он оказывается на земле, а если игрока окружили враги, то способность возрастает еще сильнее! Только для тех, кто развивает воинское ремесло"
		Changes.Push(ChangeArr)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 1
		ChangeArr[3] := "set KeaSKILLWisdomMAX to 100"
		ChangeArr[4] := "set KeaSKILLWisdomMAX to 200				`;short (100) - максимум развития навыка ""Мудрость"""
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 1
		ChangeArr[3] := "set KeaSKILLMedicMAX to 100"
		ChangeArr[4] := "set KeaSKILLMedicMAX to 200					`;short (100) - тоже самое - но для ""Медицина"""
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 2
		ChangeArr[3] := "set KeaRandomWeaponPowerMod to 1.0"
		ChangeArr[4] := "set KeaRandomWeaponPowerMod to 1.0			`;float (1.0) Модификатор усиления оружия, умножается на значение максимального усиления оружия, при этом минимальное усиление оружия будет равно 0.5 от максимального (например, на 0 уровне игрока и при KeaRandomWeaponPowerMod = 1.5 максимальное усиление оружия будет 25*1.5= +37.5%, а минимальное будет 37.5*0.5= +18.75%)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 2
		ChangeArr[3] := "set KeaRandomArmorPowerMod to 1.0"
		ChangeArr[4] := "set KeaRandomArmorPowerMod to 1.0			`;float (1.0) Модификатор усиления брони. Минимальное усиление = 0.5 от максимального"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 2
		ChangeArr[3] := "set KeaRandomEnchantPowerMod to 1.0"
		ChangeArr[4] := "set KeaRandomEnchantPowerMod to 1.0			`;float (1.0) Модификатор усиления зачарований (оружия/броня). Минимальное усиление = 0.75 от максимального"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 2
		ChangeArr[3] := "set KeaRandomStaffPowerMod to 1.0"
		ChangeArr[4] := "set KeaRandomStaffPowerMod to 1.0			`;float (1.0) Модификатор усиления посохов. Минимальное усиление = 0.75 от максимального"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set KeaSettingRedBlink"
		ChangeArr[4] := "set OEKSEBladeGoverningSpeed to 0 			`;short (0) Позволяет изменить привязку навыка ""клинки"" к атрибуту, который будет увеличиваться при повышении уровня (если игрок до повышения уровня повысил владение навыком ""клинки""). При 0 будет расти сила, при 1 - скорость"
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
		ChangeArr[4] := "setGS fDamagePowerAttackForwardBonus 2.5	`;float (v:3,KSE:5) во сколько раз сильнее ""мощная атака"" при движении вперед (удар с шагом вперед)"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 2
		ChangeArr[3] := "set OEKSEAddDamagePowCritChancePC"
		ChangeArr[4] := "set OEKSEAddDamagePowCritChancePC to 50		`;short (50) Шанс того, что удар, наносящий минимальный физический урон по игроку, будет усиленным критическим (х2.0), а не обычным критическим. Шанс усиленного критического удара перемножается с шансом обычного критического удара, т.е. общий шанс получить усиленный критический удар равен 0.2*0.5=0.1=10%"
		Changes.Push(ChangeArr)
		;
		ChangeArr := []
		ChangeArr[0] := "KeaSkillExtender.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 4
		ChangeArr[3] := "set KeaDMGPenStaggerBaseAgi"
		ChangeArr[4] := "`nset OEKSEPCHealthPenaltyRestriction to 1						`;short (1) Ограничивает дополнительный урон КСЕ по игроку (от ударов в спину, во время атаки, во время произнесения заклинания и т.п.). Не ограничивает стандартный игровой урон (например, силовой удар от бандита с двуручным оружием в руках все еще причиняет существенный урон) или урон от магии"
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
		ChangeArr[4] := "`nset OEKSEPCHealthPenaltyRestrictionBaseAttack to 0.15			`;float (0.15) Если игрок получает обычный удар ближнего боя или урон от стрелы и суммарный урон превышает это значение (0.15=15% от базового значения жизни), то любой дополнительный урон выше этого значения для этого удара отменяется"
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
		ChangeArr[4] := "set OEKSEPCHealthPenaltyRestrictionPowerAttack to 0.25			`;float (0.25) То же самое, но для силовых атак ближнего боя"
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
		ChangeArr[4] := "`n`nset OEKSEPCMeleeCombatRegulation to 1							`;short (1) Дает игроку пассивную способность обороняться в ближнем бою. Фактически - включает систему регулирования количества НПС и монстров, атакующих игрока в ближнем бою. Количество атакующих зависит от расы, боевых и магических навыков и атрибутов игрока. Хорошо подходит для бойцов ближнего боя, для магов почти бесполезна. Количество атакующих незначительно изменяется каждые несколько секунд (условно, в течение 2 секунд игрока могут атаковать не более 2 врагов, затем в течение 4 секунд не более 3 врагов и т.д.). Не влияет на битвы 1 на 1. Не влияет на вражеские выстрелы из лука и произнесение заклинаний врагами. Влияет на НПС и монстров только тогда, когда их цель - игрок, но не на их бои между собой. Совсем слабые существа (крысы, крабы и т.п.) не учитываются. Работает только при KeaSettingWSpeed = 1"
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
		ChangeArr[4] := "`nset OEKSEPCMeleeCombatRegulationConsiderCreatures to 1			`;short (1) Учитывать монстров, атакующих игрока. При 0 будут учитываться только НПС (бандиты и т.п.), а монстры (зомби, гоблины, кланфиры и т.п.) не будут никак ограничены"
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
		ChangeArr[4] := "`nset OEKSEPCMeleeCombatRegulationRaceImperial to 2.65			`;float (2.65) Базовое количество атакующих, если персонаж игрока имеет расу ""имперец"". От 1 до 4. Например, 2.65, если не учитывать развитие персонажа, означает не более 2.65 атакующих одновременно (среднее значение) и это значение будет меняться в диапазоне от 2.15 до 3.15 каждые несколько секунд. В итоге игрока в ближнем бою будут атаковать 35% времени не более 2 врагов и 65% не более 3 врагов"
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
		ChangeArr[4] := "set OEKSEPCMeleeCombatRegulationRaceKhajiit to 2.2				`;float (2.2) Каджит"
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
		ChangeArr[4] := "set OEKSEPCMeleeCombatRegulationRaceWoodElf to 2.35				`;float (2.35) Лесной эльф"
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
		ChangeArr[4] := "set OEKSEPCMeleeCombatRegulationRaceNord to 2.5					`;float (2.5) Норд"
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
		ChangeArr[4] := "set OEKSEPCMeleeCombatRegulationRaceOrc to 2.5					`;float (2.5) Орк"
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
		ChangeArr[4] := "set OEKSEPCMeleeCombatRegulationRaceRedguard to 2.5				`;float (2.5) Редгард"
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
		ChangeArr[4] := "set OEKSEPCMeleeCombatRegulationRaceDarkElf to 2.65				`;float (2.65) Тёмный эльф"
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
		ChangeArr[4] := "set OEKSEPCMeleeCombatRegulationRaceArgonian to 2.2				`;float (2.2) Аргонианин"
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
		ChangeArr[4] := "set OEKSEPCMeleeCombatRegulationRaceBreton to 2.8				`;float (2.8) Бретонец"
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
		ChangeArr[4] := "set OEKSEPCMeleeCombatRegulationRaceHighElf to 2.95				`;float (2.95) Высокий эльф"
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
		ChangeArr[4] := "`nset OEKSEPCMeleeCombatRegulationConsiderPhysics to 1			`;short (1) Учитывать развитие боевых навыков (клинки, дробящее оружие и рукопашный бой) и атрибутов (сила, ловкость, скорость и выносливость) при расчете модификатора количества атакующих. Если развивать боевые навыки и атрибуты, то количество атакующих игрока врагов в ближнем бою снизится (игрок выбрал путь развития бойца ближнего боя)"
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
		ChangeArr[4] := "`nset OEKSEPCMeleeCombatRegulationConsiderMagic to 1				`;short (1) Учитывать выбор магической расы, магического знака рождения, развитие магических навыков и атрибутов. Если выбрать магическую расу (высокий эльф, бретонец - имеют расовый бонус увеличения магии), взять магический знак рождения (маг, ученик, атронах), развивать боевые магические навыки (разрушение и колдовство, менее строго - мистицизм) и магические атрибуты (интеллект и силу волу), то количество атакующих игрока врагов в ближнем бою увеличится (игрок выбрал путь развития мага)"
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
		ChangeArr[4] := "`nset OEKSEPCMeleeCombatRegulationInfo to 1						`;short (1) Добавляет информацию по способности в книгу дополнительной статистики KSE. Эта способность учитывает только базовые (не измененные магией) значения навыков/атрибутов"
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
		ChangeArr[4] := "`n`nset OEKSEPCMeleeCombatEnhancedDamage to 1						`;short (1) Дает игроку пассивную способность, позволяющую использовать численное приемущество врага против них самих. Противники в бою не координируют атаки друг с другом и это дает возможность подготовленным бойцам проводить против них более умелые атаки, тем самым увеличивая свой физический урон в ближнем бою. При этом любые нейтралы (или союзники, напарники, призванные существа), которые ""путаются под ногами"" в бою и ведут собственную войну, мешают игроку сконцентрироваться на противнике - даже один такой ""помощник"" значительно снижает эффективность способности, а 2 и более полностью обнуляют эффект способности! Физически более крепкие расы (например - норды) используют способность более эффективно по сравнению с расами, которые предпочитают магию боевой подготовке (например - высокие эльфы). Чем больше развиты боевые навыки и атрибуты по сравнению с магическими, тем выше эффективность способности и наоборот. Совсем слабые существа (крысы, крабы и т.п.) не учитываются"
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
		ChangeArr[4] := "`nset OEKSEPCMeleeCombatEnhancedDamageRaceImperial to 1.1			`;float (1.1) Модификатор эффективности способности для расы ""имперец"". Влияет на дополнительный физический урон в ближнем бою с несколькими противниками - если >1, то увеличивает его, если < 1, то уменьшает"
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
		ChangeArr[4] := "set OEKSEPCMeleeCombatEnhancedDamageRaceKhajiit to 0.95			`;float (0.95) Каджит"
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
		ChangeArr[4] := "set OEKSEPCMeleeCombatEnhancedDamageRaceWoodElf to 1.0			`;float (1.0) Лесной эльф"
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
		ChangeArr[4] := "set OEKSEPCMeleeCombatEnhancedDamageRaceNord to 1.25			`;float (1.25) Норд"
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
		ChangeArr[4] := "set OEKSEPCMeleeCombatEnhancedDamageRaceOrc to 1.3				`;float (1.3) Орк"
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
		ChangeArr[4] := "set OEKSEPCMeleeCombatEnhancedDamageRaceRedguard to 1.2			`;float (1.2) Редгард"
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
		ChangeArr[4] := "set OEKSEPCMeleeCombatEnhancedDamageRaceDarkElf to 1.1			`;float (1.1) Тёмный эльф"
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
		ChangeArr[4] := "set OEKSEPCMeleeCombatEnhancedDamageRaceArgonian to 0.95		`;float (0.95) Аргонианин"
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
		ChangeArr[4] := "set OEKSEPCMeleeCombatEnhancedDamageRaceBreton to 0.85			`;float (0.85) Бретонец"
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
		ChangeArr[4] := "set OEKSEPCMeleeCombatEnhancedDamageRaceHighElf to 0.75			`;float (0.75) Высокий эльф"
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
		ChangeArr[4] := "`nset OEKSEPCMeleeCombatEnhancedDamageInfo to 1					`;short (1) Добавляет информацию по способности в книгу дополнительной статистики KSE. Эта способность учитывает только базовые (не измененные магией) значения навыков/атрибутов/параметров"
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
		ChangeArr[4] := "`nset OEMitigatePCMeleeSneakAttackReflectDamage to 1	`;(1) ограничивает отраженный урон, который получает игрок при проведении скрытой атаки ближнего боя по НПС и существам. По умолчанию, чем выше множитель критического удара, тем больше игрок получает отраженного урона и, при определенных условиях, убивает сам себя с одного удара. При 1 в расчете отраженного урона по игроку не будет применяться множитель критического удара. Исключения: НПС и существа со 100% отражением урона"
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
		ChangeArr[4] := "set OEAdditionalHealthBoostLevel to 5				`;(5) начиная с какого уровня будут встречаться НПС и существа с дополнительным значением жизни"
		Changes.Push(ChangeArr)
		;
		;
		ChangeArr := []
		ChangeArr[0] := "SupremeMagicka.ini"
		ChangeArr[1] := 12
		ChangeArr[2] := 1
		ChangeArr[3] := "set SMNewSpells to 0"
		ChangeArr[4] := "set SMNewSpells to 0						`;(0) при 1 добавляет в игру новые заклинания от SupremeMagicka, ломающие баланс, при 0 - убирает их из игры. Заклинания, добавляемые настройками SMNewSpells и SMNewSuitableSpells - это два разных набора заклинаний"
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

	; формирование списка ини-файлов
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

	; проверка существования ини-файлов, в обратном порядке
	index := IniFileCount - 1
	Loop, %IniFileCount%
	{
		IniFileFullPath := ApplicationDir Inis[index][0] Inis[index][1]
		IfNotExist, %IniFileFullPath%
		{
			; простое копирование штаных ини-файлов для работы патча в локальном режиме из папки релиза, если их в ней нет
			if (APPLICATION_MODE == 0)
			{
				Path := StrReplace(Inis[index][0], "\_release ini\files")
				FileNameWithPartedPath := Path Inis[index][1]
				FileName := Inis[index][1]
				msgbox Ошибка: отсутствует файл "%FileName%"
				RealeseGamePath := "D:\Games\_Сборки_Oblivion\_Релиз\__Bild\Oblivion"
				IfExist, %RealeseGamePath%\%FileNameWithPartedPath%
				{
					msgbox Копирую "%FileName%" из папки релиза %RealeseGamePath%
					FileCreateDir, %ApplicationDir%\_release ini\files\Data\ini
					PatchLocalPath := Inis[index][0] Inis[index][1]
					FileCopy, %RealeseGamePath%\%FileNameWithPartedPath%, %ApplicationDir%\%PatchLocalPath%
				}
			}
			else if (APPLICATION_MODE == 1)
			{
				msgbox Ошибка установки: не обнаружен файл по адресу %IniFileFullPath%
				Inis.RemoveAt(index)
				IniFileCount--
			}
		}
		index--
	}

	; проверка существования используемых в локальном режиме папок
	if (APPLICATION_MODE == 0)
	{
		; папка ини-файлов версионного контроля -				version
		FileRemoveDir, %ApplicationDir%\version, 1
		FileCreateDir, %ApplicationDir%\version
		; папка ини-файлов для ручной установки патча -			_generated
		FileRemoveDir, %ApplicationDir%\_generated, 1
		FileCreateDir, %ApplicationDir%\_generated\files\Data
		FileCreateDir, %ApplicationDir%\_generated\files\Data\ini
	}

	; версионный контроль
	; формирование списка дополнительных ини-файлов для проверки правильности внесения в них изменений
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

	; вывод изменений в файл
	PrintChanges(ApplicationDir, Changes, ChangesCount, Inis, Patches)

	;чтение ини-файлов
	index := 0
	Loop, %IniFileCount%
	{
		IniFileFullPath := ApplicationDir Inis[index][0] Inis[index][1]
		file_format := FileGetFormat(IniFileFullPath)
		if (file_format == "UTF-8") || (file_format == "UTF-8 no BOM")
		{
			FileRead, TempMultistring, *P65001, %IniFileFullPath%
			
			;дополнительная проверка считанного файла - если формат определился неверно, то он меняется на другой (ANSI <> UTF)
			;для файлов без русского языка разницы быть не должно
			if (InStr(TempMultistring, "а") == 0)
				FileRead, TempMultistring, *P1251, %IniFileFullPath%
		}
		else
		{
			FileRead, TempMultistring, *P1251, %IniFileFullPath%
			
			;дополнительная проверка ---||---
			if (InStr(TempMultistring, "а") == 0)
				FileRead, TempMultistring, *P65001, %IniFileFullPath%
		}
		Inis[index][2] := TempMultistring
		index++
	}

	; для выходных файлов устанавливается кодировка ANSI (Windows 1251)
	FileEncoding CP1251

	; подсчет введенных изменений в файлы
	InjectedChangesCount := 0
	; обработка ини-файлов
	; в локально режиме прогоняется 2 раза - первый раз создаются тестовые ини-файлы патчей разных версий (количество файлов = PatchesCount), во второй прогон создаются пропатченные ини-файлы со всех версий до последней версии (количество файлов = PatchesCount, последний файл, фактически, не патчится)
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
			; ОБРАБОТКА ини-файла
			
			; версионный контроль
			; разное количество проходов ини-файлов для патчера в тестовом (PatchesCount) и удаленном (1) режимах
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
				; чтение ini-файла и его имени
				TempMultistring := Inis[ini_index][2]
				
				IniFileNameWithExtension := Inis[ini_index][1]
				
				; версионный контроль
				; из имени файла убираются последние цифры (это версии патчей)
				if (InisReapetedFilesVersionControlHandling == 1)
					IniFileNameWithExtension := DeleteLastStringDigits(IniFileNameWithExtension)

				; обновление состояния патчера
				if (APPLICATION_MODE == 1)
					GuiControl, Text, State, Обрабатываю: %IniFileNameWithExtension%

				; предварительное уничтожение всех `r
				TempMultistring := StrReplace(TempMultistring, "`r")
				
				; применяем патчи по шагам (друг за другом) и только те, которые имеют отношение к конкретному ини-файлу
				; объявление циклического индекса патча, начиная (включительно) с которого будут применяться изменения
				; циклический индекс патча имеет минимальное значени = индекс установленного патча + 1
				cycle_patch_index := OBLIVION_PATCHER_MINIMUM_PATCH_INDEX
				Loop, %PatchesCount%
				{
					; на выходе из цикла ожидается MultiString. Это действие позволяет избежать ситуаций, когда цикл был прерван (continue/break), а на выходе цикла остался TempMultistring
					MultiString := TempMultistring
					
					; версионный контроль
					; к повторным файлам применяем только те патчи, которые еще не были применены
					; !отбрасываем изменения
					if (InisReapetedFilesVersionControlHandling == 1) && (cycle_patch_index <= repeated_file_applied_patch_index)
					{
						; специальный случай, когда на вход подаются файлы, уже максимально пропатченные
						if (repeated_file_applied_patch_index == PatchesMaxIndex)
						{
							; цикл прерывается
							break
						}
						cycle_patch_index++
						continue
					}

					; работаем только с подходящими для этого ини файла изменениями
					; !набираем изменения
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

					; цикл уходит на новую итерацию, если для ини-файла нет никаких изменений
					; !отбрасываем изменения
					if (CurrentChangesCount == 0)
					{
						cycle_patch_index++
						continue
					}
					
					; крутим ини два раза - в прямую и обратную сторону, чтобы внести изменения до (CurrentChanges[index1][2] == 3) и после (CurrentChanges[index1][2] == 4) строки
					ReverseParsing := 0
					; для этого перегоняем данные между TempMultistring и MultiString, итого - MultiString
					Loop, 2
					{
						; внесение изменений после строки
						MultiString := ""
						RevertedMultiString := ""
						ChangeString := ""
						UnappliedChanges := []
						; парсим ини по символу перехода на новую строку
						Loop, Parse, TempMultistring, `n
						{
							ReadedLine = %A_LoopField%
							
							; проверяем массив изменений, которые должны быть внесены. если есть, что вносить - вносим
							; применяем изменения до и после строки
							if (UnappliedChanges.MaxIndex() >= 0)
							{
								UnappliedChangesCount := UnappliedChanges.MaxIndex() + 1
								
								CurrentLineType := DefineString(ReadedLine)
								if (CurrentLineType == 1) || (CurrentLineType == 2)
								{
									Loop, %UnappliedChangesCount%
									{
										; внесение изменений в зависимости от того, в прямом или обратном порядке разбирается содержимое ини-файла
										if (ReverseParsing == 1)
										{
											; строка с изменением
											ChangeString := UnappliedChanges[UnappliedChanges.MaxIndex()][0]
											; дополнительные строки
											AddStrings := UnappliedChanges[UnappliedChanges.MaxIndex()][1]
											
											MultiString = %MultiString%`n%AddStrings%%ChangeString%
											; установка чистой строки перед вносимой строкой (`n`n) больше не используется
											
											; чистим массив изменений, которые должны быть внесены
											UnappliedChanges.Pop()
											
											if (InisReapetedFilesVersionControlHandling == 0) && (repeated_file_maximum_patch_index == PatchesMaxIndex)
												InjectedChangesCount++
										}
										else
										{
											; строка с изменением
											ChangeString := UnappliedChanges[0][0]
											; дополнительные строки
											AddStrings := UnappliedChanges[0][1]
											
											MultiString = %MultiString%`n%ChangeString%%AddStrings%
											; установка чистой строки перед вносимой строкой (`n`n) больше не используется
											
											; чистим массив изменений, которые должны быть внесены
											UnappliedChanges.RemoveAt(0)
											
											if (InisReapetedFilesVersionControlHandling == 0) && (repeated_file_maximum_patch_index == PatchesMaxIndex)
												InjectedChangesCount++
										}
									}
									
									; функционал определения типа строки больше не задействуется и для типа 2 больше не используется "MultiString = %MultiString%`n"
								}
							}
							
							; при нахождении значения-якоря, отслеживаем изменения до и после строки и меняем строки по умолчанию и строки целиком
							index1 := 0
							Loop, %CurrentChangesCount%
							{
								ChangeTaken := 0
								
								; забираем из массива изменения строку-якорь
								SearchString := CurrentChanges[index1][3]
								
								; отслеживаем изменения, вносимые после строки при прямом обходе и до строки при обратном проходе
								if (InStr(ReadedLine, SearchString) > 0) && (((CurrentChanges[index1][2] == 4) && (ReverseParsing == 0)) || ((CurrentChanges[index1][2] == 3) && (ReverseParsing == 1)))
								{
									ChangeArray := []
									; строка изменения
									ChangeArray[0] := CurrentChanges[index1][4]
									; дополнительные строки (если есть)
									ChangeArray[1] := CurrentChanges[index1][5]
									
									; флаг, говорящий о том, что мы забрали изменение и оно должно быть из CurrentChanges удалено
									ChangeTaken := 1
									
									; передаем изменение и связанные с ним вещи в промежуточный массив изменений, которые должны быть внесены
									UnappliedChanges.push(ChangeArray)
									
									if (UnappliedChanges[0] == "")
										UnappliedChanges.RemoveAt(0)
								}
								
								; отслеживаем изменения, меняющие значения по умолчанию или меняющие всю строку. при необходимости - вносим эти изменения
								if (InStr(ReadedLine, SearchString) > 0) && ((CurrentChanges[index1][2] == 1) || (CurrentChanges[index1][2] == 2)) && (ReverseParsing == 0)
								{
									; строка изменения
									ChangeString := CurrentChanges[index1][4]
									; дополнительные строки (если есть)
									if CurrentChanges[index1][5]
										ChangeString := ChangeString CurrentChanges[index1][5]
									ReadedLine := ChangeString
									
									; флаг, говорящий о том, что мы применили изменение и оно должно быть из CurrentChanges удалено
									ChangeTaken := 1
									
									if (InisReapetedFilesVersionControlHandling == 0) && (repeated_file_maximum_patch_index == PatchesMaxIndex)
										InjectedChangesCount++
								}

								if (ChangeTaken == 0)
									index1++
								else
									CurrentChanges.RemoveAt(index1)
							}
							
							; костыль для борьбы с последним `r`n символом
							{
							if (A_Index == 1)
								MultiString = %MultiString%%ReadedLine%
							else
								MultiString = %MultiString%`n%ReadedLine%
							}
						}
						
						; пересобираем строки ини-файла в обратном порядке, чтобы внести изменения до строки на 1 проходе и вернуть в нормальное состояние на 2 проходе
						TempMultistring := ""
						Loop, Parse, MultiString, `n
						{
							ReadedLine = %A_LoopField%
							; костыль для борьбы с последним `r`n символом
							if (A_Index == 1)
								TempMultistring = %ReadedLine%%TempMultistring%
							else
								TempMultistring = %ReadedLine%`n%TempMultistring%
						}
						
						; возвращаем нормальную последовательность строк в мультистроке (содержит ини-файл)
						if (A_Index == 2)
							MultiString := TempMultistring
						
						ReverseParsing := 1
					}

					; нештатное срабатывание - если есть изменения, но они не были внесены
					if (UnappliedChanges.MaxIndex() >= 0)
					{
						UnappliedChangesCount := UnappliedChanges.MaxIndex() + 1
						index1 := UnappliedChanges.MaxIndex()
						
						ChangeString := UnappliedChanges[index1][0]
						; метка патча
						PatchmMark := UnappliedChanges[index1][1]
						; дополнительные строки
						AddStrings := UnappliedChanges[index1][2]
						MultiString = %MultiString%`n`n%ChangeString% [&&%PatchmMark%&]%AddStrings%
						UnappliedChanges.Pop()
						
						if (InisReapetedFilesVersionControlHandling == 0) && (repeated_file_maximum_patch_index == PatchesMaxIndex)
							InjectedChangesCount++
					}

					; вносим изменения в начало файла
					index1 := 0
					Loop, %CurrentChangesCount%
					{
						if (CurrentChanges[index1][2] == 5)
						{
							; строка изменения
							ChangeString := CurrentChanges[index1][4]
							; дополнительные строки
							AddStrings := CurrentChanges[index1][5]

							; добавляем изменение в файл
							MultiString = %ChangeString%%AddStrings%`n`n%MultiString%
							
							if (InisReapetedFilesVersionControlHandling == 0) && (repeated_file_maximum_patch_index == PatchesMaxIndex)
								InjectedChangesCount++
						}
						
						index1++
					}

					; вносим изменения в конец файла с проверкой пустой последней строки
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
								; строка изменения
								ChangeString := CurrentChanges[index1][4]
								; дополнительные строки
								AddStrings := CurrentChanges[index1][5]

								; добавляем изменение в файл с учетом наличия в конце файла пустой строки
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
					
					; версионный контроль
					; передача на вход цикла ини-файла из мультистроки для повторной обработки
					TempMultistring := MultiString
					
					cycle_patch_index++
				}

				; создание последней пустой строки, если последняя строка не пустая строка
				MultiStringLength := StrLen(MultiString)
				LastCharacter := SubStr(MultiString, MultiStringLength , 1)
				if (LastCharacter != "`n")
					MultiString = %MultiString%`n

				; превращение всех `n в `r`n
				MultiString := StrReplace(MultiString, "`n", "`r`n")

				; ИЗМЕНЕНИЕ ИНИ-ФАЙЛОВ
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
						
						; сохранение ини-файлов
						IfExist, %IniFileFullPath%
							FileDelete %IniFileFullPath%
						FileAppend, %MultiString%, %IniFileFullPath%
					}

					if (APPLICATION_MODE == 0)
					; версионный контроль
					{
						if (InisReapetedFilesVersionControlHandling == 0)
						{
							; сохранение ини-файлов в папке version/
							IniFileFullPath := ApplicationDir "\version\" Inis[ini_index][1] repeated_file_maximum_patch_index
							repeated_file_maximum_patch_index++
						} else
						{
							; сохранение ини-файлов в папке version/ и сохранение в имени повторного файла версии патча после его сохранения - для дальнейшей обработки
							Inis[ini_index][1] := Inis[ini_index][1] repeated_file_maximum_patch_index
							IniFileFullPath := ApplicationDir Inis[ini_index][0] Inis[ini_index][1]
						}
						; увеличение индекса патчей для повторных ини-файлов
						repeated_file_applied_patch_index++
						; сброс индекса патчей для повторных ини-файлов на 0, если пошла новая группа повторных ини-файлов
						if (repeated_file_applied_patch_index >= PatchesCount)
							repeated_file_applied_patch_index := 0

						; сохранение ини-файлов
						IfExist, %IniFileFullPath%
							FileDelete %IniFileFullPath%
						FileAppend, %MultiString%, %IniFileFullPath%
					} ; боевой режим
					else if (APPLICATION_MODE == 1)
					{
						repeated_file_maximum_patch_index++
					}
				}
			}
			ini_index++
		}
		
		; версионный контроль
		; после создания повторных ини-файлов они загружаются как "основные" ини-файлы для того, чтобы их можно было пропатчить и сравнить
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
					;на этом этапе все файлы имеют формат ANSI
					FileRead, TempMultistring, *P1251, %IniFileFullPath%
					Inis[index][2] := TempMultistring
					
					index++
				}

				InisReapetedFilesVersionControlHandling := 1
			}
		}
	}

	; версионный контроль
	; обработка повторных файлов
	if (APPLICATION_MODE == 0)
	{
		; все повторные файлы, созданные из одного исходного ини-файла, должны иметь одинаковый размер
		index1 := 0
		RepeatedInis := [[],[]]
		ArrayItemCount := 0
		Loop, %TestIniFileCount%
		{
			InitialFileName := DeleteLastStringDigits(Inis[index1][1])
			VersionFileName := Inis[index1][1]
			FileFullPath := ApplicationDir Inis[index1][0] Inis[index1][1]
			FileGetSize, FileSize, %FileFullPath%
			;на этом этапе все файлы имеют формат ANSI
			FileRead, TempMultistring, *P1251, %FileFullPath%
			MD5Hash := MD5(TempMultistring)

			RepeatedInis[ArrayItemCount,0] := VersionFileName
			RepeatedInis[ArrayItemCount,1] := InitialFileName
			RepeatedInis[ArrayItemCount,2] := FileSize
			RepeatedInis[ArrayItemCount,3] := MD5Hash

			ArrayItemCount++
			index1++
		}

		; обработка данных повторных ини-файлов
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

		; если есть ошибка, то об это выводится сообщение
		if (ErrorFound == 1)
			msgbox Found ERROR in repeated inis!
		; данные версионного контроля сохраняются в checksum_ini.txt
		IfExist, %ApplicationDir%\checksum_ini.txt
			FileDelete %ApplicationDir%\checksum_ini.txt
		FileAppend, %MultiString%, %ApplicationDir%\checksum_ini.txt
	}
	
	; генерация файла версии
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

	; формирование списка внесенных в ини-файлы изменений
	if (APPLICATION_MODE == 0)
		ChangesFileFullPath = %ApplicationDir%\Oblivion Enhancer - изменения ини-файлов.txt			; находится здесь для быстрого доступа во время тестов
	else if (APPLICATION_MODE == 1)
		ChangesFileFullPath = %ApplicationDir%\Data\Oblivion Enhancer - изменения ини-файлов.txt
	IfExist, %ChangesFileFullPath%
	{
		FileRead, Multistring, *P1251, %ChangesFileFullPath%
		FileDelete %ChangesFileFullPath%
		Multistring = `r`nДанные установки: изменений всего/доступно/внесено: %ChangesCount%/%AcceptableChangesCount%/%InjectedChangesCount%%Multistring%
		FileAppend, %MultiString%, %ChangesFileFullPath%
		
		; в локальном режиме копия этого файла отправляется в _generated
		if (APPLICATION_MODE == 0)
		{
			IfExist, %ApplicationDir%\_generated\files\Data\Oblivion Enhancer - изменения ини-файлов.txt
				FileDelete %ApplicationDir%\_generated\files\Data\Oblivion Enhancer - изменения ини-файлов.txt
			FileAppend, %MultiString%, %ApplicationDir%\_generated\files\Data\Oblivion Enhancer - изменения ини-файлов.txt
		}
	}

	; создание в локальном режиме файла с названием последнего патча
	if (APPLICATION_MODE == 0)
	{
		LastPatchVersionName := Patches[PatchesMaxIndex]
		IfExist, %ApplicationDir%\_patch_data\LastPatchVersionName.txt
			FileDelete %ApplicationDir%\_patch_data\LastPatchVersionName.txt
		FileAppend, %LastPatchVersionName%, %ApplicationDir%\_patch_data\LastPatchVersionName.txt
	}
	

	; выход из патчера по окончанию установки
	if (APPLICATION_MODE == 0)
	{
		SoundPlay, %A_WinDir%\Media\Windows Background.wav
		sleep 1500
	}
	else if (APPLICATION_MODE == 1)
	{
		GuiControl, Text, State, Обновление: завершено
		msgbox Установка патча завершена!
	}
	exitapp
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Функции:

; загрузка установленной версии Oblivion Enhancer и определение минимальной устанавливаемой версии патчей
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

; выяснение кодировки файла
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

; укорачивание строки-изменения до двух слов
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

; выяснения типа строки, тип 1 - пустая строка, тип 2 - строка с новой командой, любая другая - тип 0
DefineString(ReadedLine)
{
	CurrentLineType := 0
	if (ReadedLine == "`n") || (ReadedLine == "`r") || (ReadedLine == "`n`r") || (ReadedLine == "`r`n") || (ReadedLine == "")
	{
		; тип 1 - пустая строка
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

; суммирование нескольких строк в один временный мульти стринг по определенным правилам
StringsSum(StringsArr, ChangeType)
{
	if (StringsArr[0] == "")
		StringsArr.RemoveAt(0)
	Count := StringsArr.MaxIndex() + 1
	string := ""
	Loop, %Count%
	{
		; складывает строки в обратном порядке, если изменение вносится до строки (содержимое файла в этом момент прокручивается в обратном порядке)
		if (ChangeType == 3)
			string := StringsArr[A_Index - 1] "`n" string
		else
			string := string "`n" StringsArr[A_Index - 1]
	}
	string := string
	return string
}

; вывод в файл изменений с разбивкой по патчам и ини-файлам
PrintChanges(ApplicationDir, Changes, ChangesCount, Inis, Patches)
{
	global APPLICATION_MODE

	InisCount := Inis.MaxIndex() + 1
	PatchesCount := Patches.MaxIndex() + 1
	if (APPLICATION_MODE == 0)
	{
		IfExist, %ApplicationDir%\Oblivion Enhancer - изменения ини-файлов.txt
			FileDelete %ApplicationDir%\Oblivion Enhancer - изменения ини-файлов.txt
	}
	else if (APPLICATION_MODE == 1)
	{
		IfExist, %ApplicationDir%\Data\Oblivion Enhancer - изменения ини-файлов.txt
			FileDelete %ApplicationDir%\Data\Oblivion Enhancer - изменения ини-файлов.txt
	}
	MultiString := ""
	HandledChangesCount := 0
	; костыль, т.к. использование Changes.RemoveAt(index1) удаляет нахрен данные из НЕ локального Changes и НИЧЕГО с этим не поделать
	index1 := 0
	Loop, %ChangesCount%
	{						
		Changes[index1][10] := 0
		index1++
	}

	patch_index := Patches.MaxIndex()
	Loop, %PatchesCount%
	{
		; пересоздание временного массива изменений согласно количеству ини-файлов
		TempChanges := []
		index1 := 0
		Loop, %InisCount%
		{
			TempChanges[index1] := []
			index1++
		}
			
		; извлечение изменений для определенной версии патча
		index1 := 0
		Loop, %ChangesCount%
		{
			ChangePatchIndex := Changes[index1][1]

			; если индекс патча у изменения равен искомому
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
		
		; приведение в порядок массива после Push
		index1 := 0
		Loop, %InisCount%
		{
			if (TempChanges[index1][0] == "")
				TempChanges[index1].RemoveAt(0)
			index1++
		}

		; описание изменений, вносимых патчем
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
						TempMultiString = %TempMultiString%  добавлена строка:`n                    %ChangeString%%AddStrings%`n
					}
					else if (ChangeAddType == 2)
					{
						TempMultiString = %TempMultiString%  заменена строка:`n    раньше:         %ChangeAnchorString%`n    теперь:         %ChangeString%%AddStrings%`n
					}
					else if (ChangeAddType == 1)
					{
						TempMultiString = %TempMultiString%  у строки заменено значение по умолчанию:`n    раньше:         %ChangeAnchorString%`n    теперь:         %ChangeString%%AddStrings%`n
					}
					
					index2++
				}
			}
			
			index1++
		}
		
		; внесение в мультистринг названия патча - только если патч как-то изменял ини-файлы
		if TempMultiString
			TempMultiString :=  "`n;;;;;;;;;;;;;;;;;;;;;;`nИзменения .ini файлов (patch " Patches[patch_index] "):`n" TempMultiString
		
		MultiString = %MultiString%%TempMultiString%
		patch_index--
	}
	
	MultiString = `nДанные патча: изменений всего/отражено в этом файле: %ChangesCount%/%HandledChangesCount%`n%MultiString%
	
	; превращение всех `n в `r`n
	MultiString := StrReplace(MultiString, "`n", "`r`n")
	
	; сброс в файл
	if (APPLICATION_MODE == 0)
		FileAppend, %MultiString%, %ApplicationDir%\Oblivion Enhancer - изменения ини-файлов.txt
	else if (APPLICATION_MODE == 1)
		FileAppend, %MultiString%, %ApplicationDir%\Data\Oblivion Enhancer - изменения ини-файлов.txt
}

; удаление последних цифр в строке
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

; контрольная сумма
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





























