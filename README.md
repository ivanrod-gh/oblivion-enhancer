# О проекте

Это скриптовая часть сборки/модификации для компьютерной игры The Elder Scrolls IV: Oblivion

Сам проект можно найти на rutracker.org по ключевым словам "Oblivion Enhancer"

# Описание

Проект Oblivion Enhancer - это сборка, которая включает в себя оригинальную игру, плагины, определенный набор модификаций и инсталлятор

Некоторые модификации были изменены/переписаны

Сборка содержит одноименную модификацию, которая изменяет и расширяет оригинальный геймплей

Для обновления сборки был написан патчер (.ahk, компилируется в .exe), который разворачивает обновления в установленной сборке без уничтожения внесенных пользователем изменений в ini-файлы модификаций

В этом репозитории представлены скрипты из сборки (v1.1.3):
- модификации Oblivion Enhancer Main.esp (все)
- модификации KSE_v3.esp (только написанные мной)
- патчера OblivionPatcher.ahk

85% кода было написано в 2015-2017 и 2022 годах, еще до чтения "правильных" книг и прохождения курсов

Т.к. специалистов по этому скриптовому языку немного, то, дополнительно, здесь опубликованы ini-файлы (файлы с настройками) к этим модификациям, которые позволяют приблизительно оценить объем выполненных работ (верстку штормит, т.к. предполагается открывать в Notepad++)

# Структура

Скрипты модификаций для The Elder Scrolls IV: Oblivion пишутся на проприетарном языке, не имеют структуры файлов/папок, как тот же Ruby on Rails, на них не написано своего rubocop, а техническая документация на OBSE (добавляет в скрипты новые типы данных и функции) представляет из себя просто список функций с кратким пояснением, которые доступны для использования

В гите для таких скриптов нет линтера, что усложняет чтение

Для облегчения навигации здесь я дам краткое описание скриптов/функций (зачем нужны и что делают) и их взаимосвязей

## Oblivion Enhancer Main.esp

1. **OEInitQScr**:
	- содержит глобальные переменные, используемые в других функциях
	- отвечает за вывод debug-сообщений
	- загружает и проверяет (**OEInitCheckAllowedSettingsFScr**) пользовательские настройки из Oblivion Enhancer.ini
	- инициализирует массивы и ассоциативные массивы
	- **OEActorsDrainedHealthRestoreWithSpellsFScr**: позволяет актерам (НПС и существам) восстанавливать значение здоровья, которое было увеличено при помощи скриптовых команд; в противном случае актер пытается безрезультатно исцелить себя, пока есть мана
	- проводит работы с уровневыми списками оружия и брони: подготовку данных, перерасчет, откат изменений в случае необходимости
		- **OEFillLeveledListsMainArray1FScr**, **OEFillLeveledListsMainArray2FScr**, **OEFillLeveledListsMainArray3FScr**, **OEFillLeveledListsMainArray4FScr**, **OEFillLeveledListsMainArray5FScr**: наполняют массив данным уровневых списков оружия и брони
		- **OELevelListsNormalizeFScr**:
			- производит перерасчет уровневых списков, хранит их в клонформах (CloneForm), заменяют оригинальные уровневые списки на клонформы
			- **OECheckLeveledListSettingsFScr**: отслеживает изменение настроек функции с прошлого запуска игры
			- **OEExtractLevelListsFScr**: извлекает содержимое уровневого списка в массив
			- **OELeveledListRefactorFScr**:
				- производит перерасчет уровневых списков оружия и брони (игра содержит более 2000 таких списков), нормирует полученные данные так, чтобы шанс выпадения вещей с каждого уровня был примерно одинаков
				- **OEGetApparelEnchantmentValueFScr**: рассчитывает ценность постоянного зачарования
			- **OELeveledListExchangeFScr**: меняет оригинальные уровневые списки на перерасчитанные
		- **OERestoreLeveledListsFScr**: восстанавливает уровневые списки при помощи ранее сохраненных значений
		- **OEEmergencyWipeQScr**: проводит работы перерасчету и замене уровневых списков, при необходимости - откатывает изменения
		- **OERebalanceFScr**:
			- проводит работы по перебалансировке параметров вещей (оружия и брони)
			- **OECalcArmorPriceFScr**: вычитывает стоимость брони согласно характеристике (тангенс)
			- **OECalcWeaponPriceFScr**: вычитывает стоимость оружия согласно характеристике (тангенс, возведенный в степень)
		- **OECalcItemsValueFScr**: наполняют массив данным об оружии и броне
	- проводит работы с дополнительными призываемыми существами: изменение уровневых списков, цены и длительности заклинаний, добавление новых заклинаний вызова в игру, отслеживание применения заклинаний вызова
		- **OESummonLvlSpellRecombFScr**:
			- меняет минимальный уровень владения колдовством, чтобы актер мог использовать заклинания призыва
			- **OEChangeLvlInLeveledSpellFScr**: обеспечивает такое изменение
	- **OEGetStartMapMarkersEnabledFScr**: возвращает стандартные маркеры карты, которые удаляются некоторыми модификациями из состава FCOM
	- разрешает квестовых скриптам (**OEGlobalWatchQScr**, **OEGlobalVariablesUpdateQScr**, **OEEmergencyWipeQScr**) работать, в противном случае эти скрипты "самоблокируются"
	- отслеживает запуск других модификаций
	- **OERestrictLeveledCreatureMaxItemsFScr**: ограничивает количество актеров в ванильных (оригинальных) уровневых списках
		- **OERestrictLeveledCreatureSettingsFScr**: отслеживает изменение настроек функции с прошлого запуска игры
		- **OEFillLeveledListsToRestrictArray1FScr**, **OEFillLeveledListsToRestrictArray2FScr**, **OEFillLeveledListsToRestrictArray3FScr**, **OEFillLeveledListsToRestrictArray4FScr**, **OEFillLeveledListsToRestrictArray5FScr**: наполняют массив данными уровневых списков актеров
	- **OEGetLoadedModsListFScr**: наполняет массив названиями загруженных модификаций
	- **OEManageSkillsUseFScr**: переназначает скорость роста навыков с учетом общей скорости роста навыков
	- прочие минорные вещи
2. **OEGlobalWatchQScr**:
	- инициализирует свои массивы с зачисткой или без зачистки информации, вводит предварительные настройки
	- 1 раз в 250мс проводит захват актеров в радиусе 2 клеток (cell) от игрока, без захвата призываемых существ
	- за один цикл обрабатывает определенное количество захваченных актеров - в зависимости от дальности до игрока
	- проверяет захваченных актеров на владение оружием и броней, которые избежали перебалансировку
	- **OEAmplificationSystemFScr**:
		- **OEAddFireResistValueFScr**, **OEAddFrostResistValueFScr**, **OEAddShockResistValueFScr**, **OEAddMagicResistValueFScr**, **OEAddParalysisResistValueFScr**, **OEAddPhysicalShieldValueFScr**, **OEAddResistNormalWeaponsValueFScr**, **OEAddReflectDamageValueFScr**, **OEAddChameleonValueFScr**, **OEAddSpellAbsorbChanceValueFScr**, **OEAddSpellReflectChanceValueFScr**, **OEAddHealthBoostFScr**, **OEAddMagickaBoostFScr**, **OEAddFatigueBoostFScr**, **OEAddSpeedBoostFScr**: назначает актерам без соответствующих меток случайные усиления параметров
		- **OEAddElementalResistTokenFScr**, **OEAddMagicResistTokenFScr**, **OEAddParalysisResistTokenFScr**, **OEAddPhysicalShieldTokenFScr**, **OEAddResistNormalWeaponsTokenFScr**, **OEAddReflectDamageTokenFScr**, **OEAddChameleonTokenFScr**, **OEAddSpellAbsorbChanceTokenFScr**, **OEAddSpellReflectChanceTokenFScr**, **OEAddRegenTokenFScr**: назначает актерам метки, по которым система поймет, проходил ли актер процедуру у усиления, или нет; исключение - метка регенерации жизни, которая имеет не запрещающий, а разрешающий характер
		- откатывает внесенные изменения, если необходимо
	- **OEAddRegenValueFScr**: функция регенерации жизни актеров, у которых есть соответствующая метка
	- предотвращает "stunlock" актеров/игрока, у которых значение выносливости стало отрицательным (под действием заклинаний и т.п.)
	- **OEAutoRechargeFScr**:
		- система автоподзарядки вещей игрока при помощи Звезды Азуры
		- **OEAutoWeaponRechargeFunction**: проводит саму подзарядку вещей
	- **OEEnemyActorsCheckPCInvisibilitySpellFScr**: снимает с игрока невидимость, если он находится слишком близком к врагам
	- **OEWeaponSelfRechargeFScr**: обеспечивает подзарядку вещей игрока со временем, как в Morrowind
	- обеспечивает работу новых призываемых существ, т.к. они не являются "штатными" и у них отсутствует подобная логика - например следит за тем, чтобы общее количество призванных существ было не более допустимого
		- **OEUpdateSummonsInSummonerGroupFScr**: обновляет данные в группах "призывающий - призванные существа"
		- **OECheckValidActorsInSummonersArrayFScr**: зачищает группы от актеров с недействительными идентификаторами
	- проводит очистку локации, куда скидываются мертвые нештатные призванные существа
3. Нештатные призванные существа
	- **OESpawnAdditionalSummonMEScr**: эффект заклинания, при помощи которого нештатные призванные существа могут призывать себе "помощника" (также является нештатным призванным существом)
	- **OEScriptSummonEffectOScr**:
		- обеспечивает логику работы нештатных призванных существ и их регистрацию в OEGlobalWatchQScr
	- **OESummonAtronachFlameJourneymanMEScr**, **OESummonAtronachFrostJourneymanMEScr**, **OESummonAtronachShockJourneymanMEScr**, **OESummonDremoraWarriorExpertMEScr**, **OESummonMonarchFlameMasterMEScr**, **OESummonMonarchFrostMasterMEScr**, **OESummonMonarchStormMasterMEScr**, **OESummonSkeletonOverlordMasterMEScr**, **OESummonZombieDreadExpertMEScr**, **OESummonZombieOverlordMasterMEScr**, **OESummonZombieSoldierJourneymanMEScr**: эффект заклинания призыва нештатных призванных существ; из-за определенной реализации в KSE_v3 должны быть отдельными скриптами, при этом части этих скриптов слабо подлежат выносу в отдельные функции
	- **OEAddSummonerToSummonersArrayFScr**: решает проблему вылета при использовании как призываемого существа не существа, а уровневый список с существами
4. **OEShowLeveledListByLevelFScr**: выводит данные уровневого списка (debug)
5. **OEShowPackedLeveledListByLevelFScr**: выводит данные сложного уровневого списка (debug)
6. **OEShowNormalizedArrayByItemFScr**: выводит данные нормированного массива (debug)
7. **OEShowPackedNormalizedArrayByLevelFScr**: выводит данные сложного нормированного массива (debug)
8. **OEShowPackedNormalizedArrayByItemFScr**: выводит данные сложного нормированного массива (debug)
9. **OEGetLeveledListCommonCastFScr**: создает простой "слепок" (перечень содержимого) уровневого списка в виде массива
10. **OECheckCastsDifferenceFScr**: проверяет два слепка на идентичность
11. **OECheck1DArrayDifferenceFScr**: проверяется два одномерны массива на идентичность
12. **OECirculeCheckArraysFullnessFScr**: проверяет, что массив имеет записей не менее определенного количества
13. **OEGlobalVariablesUpdateQScr**: раз в 30 секунд проверяет определенные глобальные настройки, привязанные к уровню игрока
14. **OELLRQScr**: обеспечивает принудительный перерасчет уровневых списков оружия и брони
15. **OEWeaponBlockOScr**: блокирует оружие призванных существ так, чтобы его не мог использовать игрок
16. **OETESTBattleChamberQScr**: боевая камера, используется для тестов призванных существ и балансировки их параметров
17. **OETESTGetAllActiveEffectsMEScr**: выводит все активные эффекты актера (debug)
18. **OETESTGetAllAnimGroupsPlayingMEScr**: выводит все проигрываемые анимации актера (debug)
19. **OETESTGetAllItemsFScr**: выводи все вещи актера (debug)
20. **OETESTGetAllSpellsMEScr**: выводи все доступные на данный конкретный момент заклинания актера (debug)
21. **OETESTGetFactionsAndRelationsMEFcr**: выводит все фракции актера и его отношения со всеми другими актерами в клетке (debug)
22. **OETESTRageOScr**: режим берсерка для актера
23. **OETESTTransferQScr**: телепортация по миру с дополнительным спавном существ и выводом сервисной информации о состоянии окружения: используется для тестов стабильности сборки
24. **OEPCSneakAttackObserverQScr**: отслеживает актеров, по которым игрок ударил скрытой атакой и у которых есть отражение урона. Запускает возвращение им нормального значения отражения урона
25. **OEActorReduceReflectDamageFScr**: обработчик события удара - запускает **OECalcPCMeleeCriticalMultFScr** и **OEManageReflectDamageReductionFScr**
26. **OECalcPCMeleeCriticalMultFScr**: рассчитывает множитель критического удара игрока
27. **OEManageReflectDamageReductionFScr**: снижает значение отраженного урона актера в "множитель критического удара игрока" раз или возвращает стандартное значение

## KSE_v3.esp

1. **OEKSEInitQScr**:
	- содержит глобальные переменные, используемые в других функциях
	- отвечает за вывод debug-сообщений
	- загружает и проверяет (**OEKSEInitCkeckAllowedSettingsFScr**) пользовательские настройки из Oblivion Enhancer (KSE module).ini
	- инициализирует массивы и ассоциативные массивы
	- обеспечивает работу массива перезаписываемых заклинаний-клонформ, используемых в функциях усиления заклинаний
		- предварительно наполняет массив заклинаниями-клонформами
		- регистрирует для события применения магии функцию **OEKSECheckSpellCloneEventFScr**: пользователи заклинаний-клонформ записываются в отдельный массив
	- разрешает квестовых скриптам (**OEKSEArchersWatchQScr**, **OEKSERestrictFunctionsQScr**, **OEKSEFortificationAbilityQScr**, **OEKSEArcaneArcherAbilityQScr**, **OEKSEBattleMagicAbilityQScr**, **OEKSEGlobalAndPCVariablesUpdateQScr**, **OEKSERapidFireQScr**) работать, в противном случае эти скрипты "самоблокируются"
	- рассчитывает повреждения уровневых существ
	- обеспечивает работу интерфейсного "стамина бара" серии атак KSE
2. **OEKSERestrictFunctionsQScr**:
	- обеспечивает работу функции ограничения параметров игрока - при помощи диминишинга или плоских ограничений
	- **OEKSECheckRestictExeptionsFScr**: вводит исключения в эти ограничения, например, во время прохождения определенных заданий
	- **OEKSERestrictFunctionsFScr**:
		- накладывает на игрока ограничения параметров, для облегчения нагрузки на ЦП функция была "размазана" по времени (по фреймам)
		- **OEKSEGlobalAVSetterFScr**: устанавливает глобальные ограничения жизни, маны и выносливости для совместимости с аналогичными функциями в KSE
	- **OEKSECatchPCAbsorbedActorsFScr**: наполняет массив для обеспечения нормальной работы поглощающих атрибуты и параметры заклинаний игрока в случае действия системы ограничений
	- обрабатывает массив актеров, на которых игрок применил эффекты поглощения атрибутов и параметров, для приведения параметров игрока в соответствие с системой ограничений
	- **OEKSECatchPCGetMagicHitFScr**: заставляет принудительно пересчитать параметры игрока после попаданию в него магического эффекта
3. Переключаемая способность "Укрепление":
	- **OEKSEFortificationAbilityQScr**:  обеспечивающая работу способности - расчет уровня способности, применение эффектов на игрока, управление замедлением времени и откатом способности сбивать с ног
	- **OEKSEFortificationAbilityDebufferFScr**: в случае срабатывания, сбивает с ног определенных врагов
	- **OEKSEFortificationAbilityMEScr**: включает/выключает способность
	- **OEKSEFACheckBuffTargetIsPCMEScr**: обеспечивает применение позитивного эффекта способности только к игроку
	- **OEKSEFACheckDebuffTargetIsEnemyFScr**: обеспечивает применение негативного эффекта способности к кому угодно, за исключением игрока
	- **OEKSEFADebuffFScn**: применяет негативный эффект
4. Переключаемая способность "Волшебный стрелок":
	- **OEKSEArcaneArcherAbilityQScr**: обеспечивающая работу способности
	- **OEKSECheckActorIsDodgingFScr**: определяет, проигрывает ли актер анимацию уклонения или нет
	- **OEKSEArcaneArcherMPRegenMEScr**: обеспечивает нестандартную регенерацию маны игрока, т.к. стандартная бует отключена
	- **OEKSEArcaneArcherAbilityMEScr**: включает/выключает способность
	- **OEKSEAAACheckBuffTargetIsPCMEScr**: обеспечивает применение позитивного эффекта способности только к игроку
	- **OEKSEAAACheckDebuffTargetIsEnemyFScr**: обеспечивает применение негативного эффекта способности к кому угодно, за исключением игрока
5. Переключаемая способность "Боевая магия":
	- **OEKSEBattleMagicAbilityQScr**: обеспечивающая работу способности
	- **OEKSECalcActorWeaponDamage**: рассчитывает урон, наносимый актером при использовании текущего оружия
	- **OEKSECheckFreeToPlayAnimState**: проверяет, свободен ли актер для проигрывания новой анимации
	- **OEKSEBattleMagicAbilityMEScr**: включает/выключает способность
	- **OEKSEBMACheckBuffTargetIsPCMEScr**: обеспечивает применение позитивного эффекта способности только к игроку
6. Усиление заклинаний игрока:
	- **OEKSEManageEffectsPowerMenuQScr**: обеспечивает работу меню усиления заклинаний игрока, управляет выводом текста (HTML-подобный формат), воспроизведением звуков и управляет массивом усиленных эффектов
	- **OEKSECheckAllowedMGEFFScr**: проверяет, возможно ли усилить определенный эффект
	- **OEKSEManageEffectsPowerMenuMEScr**: вызывает меню усиления заклинаний
7. **OEKSEArchersWatchQScr**: обеспечивает лучникам нормальную стрельбу, т.к. в движке игры есть баг и у некоторых лучников стрелы просто не вылетают
8. **OEKSEGlobalAndPCVariablesUpdateQScr**: раз в 10 секунд проверяет определенные глобальные настройки. Имеет ступенчатый блок расчетов параметров игрока, разнесенный по времени для снижения нагрузки на ЦП
9. **OEKSERapidFireQScr**: обеспечивает работу системы усиления урона при стрельбе из лука
10. **OEKSEAddSpellsQScr**: добавляет в игру некоторые заклинания и заклинания переключаемых способностей
11. **OEKSEAmbientSoundBurnMEScr**: обеспечивает проигрывание звука "горения", т.к. не реализовать стандартным способом
12. **OEKSECalcPlayerToughtnessCoefficientFScr**: рассчитывает коэффициент для игрока, влияющий на шанс быть сбитым с ног
13. **OEKSECloneRetentionSystemQScr**: система удержания заклинаний-клонформ и их переиспользования
14. **OEKSEGetNewSpellCloneFScr**: возвращает свободное заклинание-клонформу, регистрирует в системе удержания заклинаний-клонформ
15. **OEKSECustomSortObjectsByDistanceToPlayerFScr**: особая сортировка одномерного массива по дистанции между актером и игроком
16. **OEKSEEmergencyEmpowerWipeQScr**: откат значений усиленный заклинаний НПС и существ
17. **OEKSEGetActorFatigueRatio**: рассчитывает состояние выносливости актера
18. **OEKSEGetkMEEffKeyFScr**: извлекает эффект из массива эффектов, доступных для усиления
19. **OEKSESortkMEFScr**: сортирует массив эффектов, доступных для усиления, в алфавитном порядке согласно именам эффектов
20. **OEKSEInsertInInputTextFScr**: вставляет в книгу дополнительной статистики KSE дополнительные отслеживаемые параметры
21. **OEKSEInsertInInputText2FScr**: то же, был превышен размер одного скрипта
22. **OEKSEkeaMEffectCheckAllowedSettingsFScr**: проверяет допустимость настроек основного ini-файла KSE
23. **OEKSETrainingLimitQScr**: вводит ограничения на обучение у учителей
24. **OEKSETESTShowDataQScr**: выводи некоторые глобальные настройки (debug)
25. **OEKSETESTShowShowUIdata**: выводит информацию по вызванному в этот момент режиму меню и полному пути до него (debug)
26. **OEKSEBattleEnvironmentObserverQScr**: отслеживает количество нейтралов/союзников/напарников/призванных существ вокруг игрока
27. **OEKSEGetMeleeAttackAnimGroup**: возвращает идентификатор анимации атаки ближнего боя или 0
28. **OEKSEPCMeleeCombatObserverQScr**: отслеживает врагов вокруг игрока и блокирует и возможность совершить атаку ближнего боя, если врагов слишком много
29. **OEKSEMeleeAttackBlockOScr**: обеспечивает блокировку атаки
30. **OEKSEInsertInInputText3FScr**: добавляет в книгу дополнительной статистики KSE информацию по способности игрока к обороне (т.е. к снижению числа атакующих)
31. **OEKSEInsertInInputText4FScr**: добавляет в книгу дополнительной статистики KSE информацию по способности игрока к атаке (увеличение физического урона в ближнем бою с группой врагов)

## OblivionPatcher.ahk

Копирует файлы патча с сохранением порядка запуска модификаций, дополняет ini-файлы новыми строками с сохраненнием пользовательских настроек, работает в локальном (тесты) и удаленом (пользовательском) режимах

Начиная с определенной версии вызывает срабатывание антивирусов

Написан достаточно колхозно, поэтому - без комментариев
