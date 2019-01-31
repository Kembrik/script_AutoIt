#include <Array.au3>
#include <GUIToolTip.au3>
#include <File.au3>
#include <IE.au3>

$hWnd = WinWait("Path of Exile")
If Not $hWnd Then
    MsgBox(4096, 'программа отсутствует', 'программа отсутствует')
    Exit
 EndIf

While 1
   HotKeySet("#{ESC}", "Terminate")
   ;HotKeySet("!1", "MouseGetPosichin")
   $poe_win = PoE_Active()
   if $poe_win Then
	  HotKeySet("^2", "Main")
	  HotKeySet("^3", "Main")
	  ;HotKeySet("!3", "Worth")
	  ;HotKeySet("!3", "Sort_gam")
	  ;HotKeySet("!4", "All_sale")
   EndIf
WEnd

Func Terminate()
    Exit 0
 EndFunc

 Func PoE_Active()
   If WinActive($hWnd) Then
	   Return 1
   Else
	   Return 0
   EndIf
EndFunc

Func Main()

	ToolTip('')
	Local $outputType = CheckOutputType()
	Global $sObject = ScanObject()
	Global $ArrItems = ReadFile()
	Global $ArrPriorityAffix
	Global $ArrValueAffix = ReadPriorityAffixFile(); уточнить октуальность
	Global $sTypeItem = ItemTypeDefinition()


	if $sTypeItem then
		ItemAttributeDefinition()
		if not $outputType Then OutputClippedArray() ; требуется оптимезация
		if $outputType Then OutputFullArray() ; требуется оптимезация
	EndIf
	;ConsoleWrite ($sTypeItem & @LF)
	;_ArrayDisplay($ArrItems, '$ArrItems')

EndFunc

Func CheckOutputType() ; тип вывода данных 
	switch @HotKeyPressed
    Case "^2"
        return 0
    Case "^3"
        return 1
    EndSwitch
	Return True
EndFunc

Func ScanObject() ; чтение предмета в список
	ClipPut('')
	Sleep(10)
	Send('^c')
	Sleep(10)

	Return ClipGet()
EndFunc

Func ReadFile() ; чтение файла предметов в массив

   Local $NameFile = 'ListOfItems.txt'
   Local $hFile = FileOpen($NameFile, 0)

   If $hFile = -1 Then
	  MsgBox(4096, "Ошибка", "Невозможно открыть файл.")
	  ;Exit
	  Return
   EndIf

   return WritingArrayItems($hFile)
EndFunc

Func WritingArrayItems($hFile) ; запись массива экипировки
   Local $ArrItems[0][2]
   Local $iN_arr = 0
   While 1
		$sLine = FileReadLine($hFile)
		$a = @error
		If $a = -1  Then ExitLoop

		if StringInStr($sLine, '#') Then
			$iN_arr += 1
			ReDim $ArrItems[$iN_arr][2]
			$ArrItems[$iN_arr-1][0] = StringTrimLeft($sLine, 1)
		EndIf
		$ArrItems[$iN_arr-1][1] = $sLine
   WEnd
   FileClose($hFile)
   Return $ArrItems
EndFunc

Func ReadPriorityAffixFile() ; чтение файла сипска приорететных суфиксов и префиксов с минимальными значениями в массив
	Local $NameFile = 'gradation_affix.txt'
	Local $hFile = FileOpen($NameFile, 0)

	If $hFile = -1 Then
		MsgBox(4096, "Ошибка", "Невозможно открыть файл " & $NameFile & ' !')
		;Exit
		Return
	EndIf

	Return WritingPriorityArrayAffix($hFile)
EndFunc

Func WritingPriorityArrayAffix($hFile) ; запись массива приорететных суфиксов и префиксов
   Local $ArrAffix[0][4]
   Local $iN_arr = 0
   Local $iAf = 0
   Local $sLine
   Local $aLine
   While 1
		$sLine = FileReadLine($hFile)
		If @error = -1 Then ExitLoop
		If StringInStr($sLine, '#') Then
			$iAf += 1
		ElseIf not StringRegExp ( $sLine ,'^\h*$') Then
			$iN_arr += 1
			ReDim $ArrAffix[$iN_arr][4]
			$ArrAffix[$iN_arr-1][0] = $iAf
			$aLine = StringSplit($sLine, ',(', 2)
			$ArrAffix[$iN_arr-1][1] = $aLine[0]
			$ArrAffix[$iN_arr-1][2] = $aLine[1]
			;if not @error then $ArrAffix[$iN_arr-1][3] = $aLine[1]
		EndIf
   WEnd
   FileClose($hFile)
   Return $ArrAffix
EndFunc

Func ItemTypeDefinition() ; определение типа предмета
	Local $ArrType
	Local $itemName = PickOutItemName()
	for $i=0 to UBound($ArrItems) - 1
		$ArrType = CreateTypeArray($ArrItems[$i][1])
		for $sType in $ArrType
			if StringInStr($itemName, $sType) then Return $ArrItems[$i][0]
		Next
	Next
EndFunc

Func PickOutItemName() ; выделение имя предмета
	Return StringLeft($sObject, StringInStr($sObject, '--------') - 1)
EndFunc

Func CreateTypeArray($sLine) ; разбиение строки на массив
	Return StringSplit($sLine, ',', 2)
EndFunc

Func ItemAttributeDefinition() ; определение атрибутов предмета

	Local $ObjectCorrupt = CheckOnCorrupted()
	Local $ArrPossibleAffix = ReadPossibleAffixFile()
	Local $arrSumAffix = CheckAffixNumberObject($ArrPossibleAffix)
	$ArrPriorityAffix = DefinitionPriorityArrayAffix($ArrPossibleAffix) ;требуется оптимезация

	Local $keyObjectAffix = HighlightingKeyAffix($ArrPossibleAffix)
	FillArrPriorityAffix($keyObjectAffix) ;требуется оптимезация
	CheckFreeAffix($ObjectCorrupt, $arrSumAffix) ;требуется оптимезация

EndFunc

Func OutputClippedArray() ; вывод  полного массива на экран
	Local $Line = ''
	Local $OutAffix
	Local $iN_arr = UBound($ArrPriorityAffix)-1
	$Line &= $ArrPriorityAffix[$iN_arr][0] & ' ' & $ArrPriorityAffix[$iN_arr][1] & @LF
	for $i=0 to UBound($ArrPriorityAffix) - 2
		if $i and $ArrPriorityAffix[$i][0] > $ArrPriorityAffix[$i-1][0] then $Line &= @LF
		$OutAffix = SearchOutAffix($ArrPriorityAffix[$i][2])
		If $ArrPriorityAffix[$i][1] >= $OutAffix Then
			$Line &= $ArrPriorityAffix[$i][1] & ' ' & $ArrPriorityAffix[$i][2] & @LF
		EndIf
		
	Next
	ToolTip($Line, 900, 450)
	Sleep(2000)
	ToolTip('', 900, 450)
EndFunc

Func SearchOutAffix($Affix)
	
	for $i=0 to UBound($ArrValueAffix)-1
		if $ArrValueAffix[$i][2] = $Affix then Return $ArrValueAffix[$i][1]
	Next
EndFunc

Func OutputFullArray() ; вывод  полного массива на экран
	Local $Line = ''

	for $i=0 to UBound($ArrPriorityAffix) - 2
		if $i and $ArrPriorityAffix[$i][0] > $ArrPriorityAffix[$i-1][0] then $Line &= @LF
		$Line &= $ArrPriorityAffix[$i][1] & ' ' & $ArrPriorityAffix[$i][2] & @LF
	Next

	;SplashTextOn("", $Line,-1 ,-1 ,-1, -1, 4)
	ToolTip($Line, 900, 450)
	Sleep(3000)
	ToolTip('', 900, 450)
EndFunc

Func CheckOnCorrupted() ; проверка осквернен ли предмет
	Return StringInStr($sObject, 'Corrupted')
EndFunc

Func ReadPossibleAffixFile() ; чтение файла возможных суфиксов и префиксов в массив
	Local $NameFile = 'affix_' & $sTypeItem & '.txt'
	Local $hFile = FileOpen($NameFile, 0)

	If $hFile = -1 Then
		MsgBox(4096, "Ошибка", "Невозможно открыть файл " & $NameFile & ' !')
		;Exit
		Return
	EndIf

	Return WritingArrayAffix($hFile)
EndFunc

Func WritingArrayAffix($hFile) ; запись массива возможных суфиксов и префиксов у предмета
   Local $ArrAffix[0][2]
   Local $iN_arr = 0
   Local $iAf = 0
   While 1
		$sLine = FileReadLine($hFile)
		If @error = -1 Then ExitLoop
		If StringInStr($sLine, '#') Then
			$iAf += 1
		ElseIf not StringRegExp ( $sLine ,'^\h*$') Then
			$iN_arr += 1
			ReDim $ArrAffix[$iN_arr][2]
			$ArrAffix[$iN_arr-1][0] = $iAf
			$ArrAffix[$iN_arr-1][1] = $sLine
		EndIf
   WEnd
   FileClose($hFile)
   Return $ArrAffix
EndFunc

Func CheckAffixNumberObject($ArrPossibleAffix) ; проверка количества суфиксов и префиксов у предмета
	Local $sAffixObject = PickOutObjectAffix()
	Local $arrSumAffix[2]
	for $i = 0 to UBound($ArrPossibleAffix) - 1
		if StringInStr($sAffixObject, $ArrPossibleAffix[$i][1]) Then
			if $ArrPossibleAffix[$i][0] <= 2 then $arrSumAffix[0] += 1
			if $ArrPossibleAffix[$i][0] > 2 then $arrSumAffix[1] += 1
		EndIf
	Next
	Return $arrSumAffix
EndFunc

Func PickOutObjectAffix() ; выделение суфиксов и префиксов предмета
	Local $iPass = 9 ; длинна '--------'
	Local $iN = StringInStr($sObject, '--------', 0,-1) + $iPass
	$iN = StringLen($sObject)  - $iN
	Return StringRight($sObject, $iN)
EndFunc

Func DefinitionPriorityArrayAffix($ArrPossibleAffix) ; определение возможных приорететных суфиксов и префиксов у предмета
	;требуется оптимезация
	Local $ArrAffix[0][4]
	Local $iN_arr = 0
	Local $iAf = 0
	for $i=0 to UBound($ArrPossibleAffix) - 1
		if $ArrPossibleAffix[$i][0] = 1 Then
			$iN_arr += 1
			ReDim $ArrAffix[$iN_arr][4]
			$ArrAffix[$iN_arr-1][0] = 1
			$aLine = StringSplit($ArrPossibleAffix[$i][1], '(', 2)
			$ArrAffix[$iN_arr-1][2] = $aLine[0]
			if not @error then $ArrAffix[$iN_arr-1][3] = $aLine[1]
		ElseIf $ArrPossibleAffix[$i][0] = 3 Then
			$iN_arr += 1
			ReDim $ArrAffix[$iN_arr][4]
			$ArrAffix[$iN_arr-1][0] = 2
			$aLine = StringSplit($ArrPossibleAffix[$i][1], '(', 2)
			$ArrAffix[$iN_arr-1][2] = $aLine[0]
			if not @error then $ArrAffix[$iN_arr-1][3] = $aLine[1]
		EndIf
	Next
	Return $ArrAffix
EndFunc

Func HighlightingKeyAffix($ArrPossibleAffix) ; выделение ключевых суфиксов и префиксов предмета в массив
	Local $arrObject = WriteArrayObject()
	Local $arrObjectKeyAffix[0]
	for $Line in $arrObject

		if SelectKeyAffix($Line, $ArrPossibleAffix) then _ArrayAdd($arrObjectKeyAffix, SelectKeyAffix($Line, $ArrPossibleAffix))
	Next
	Return $arrObjectKeyAffix
EndFunc

Func WriteArrayObject() ; запись предмета в массив
	Return StringSplit($sObject, @CRLF)
EndFunc

Func SelectKeyAffix($sAffix, $ArrPossibleAffix) ; отбор значемых суфиксов и префиксов предмета
	for $i = 0 to UBound($ArrPossibleAffix) - 1
		if StringInStr($sAffix, $ArrPossibleAffix[$i][1]) Then
			if $ArrPossibleAffix[$i][0] = 1 or $ArrPossibleAffix[$i][0] = 3 then Return $sAffix
		EndIf
	Next
EndFunc

Func FillArrPriorityAffix($keyObjectAffix) ; заполнение градирируеммого массива суфиксов и префиксов
;требуется оптимезация

	for $Line in $keyObjectAffix
		for $i=0 to UBound($ArrPriorityAffix) - 1
			if $ArrPriorityAffix[$i][3] Then
				$ArrPriorityAffix[$i][1] += FindRightAffix($Line, $ArrPriorityAffix[$i][3]);требуется оптимезация
			Elseif StringInStr($Line, $ArrPriorityAffix[$i][2]) then
				$ArrPriorityAffix[$i][1] += ValueAffix($Line)
			EndIf
		Next
	Next
EndFunc

Func FindRightAffix($Line, $arrAffix) ; поиск нужного суфикса или префикса
	;требуется оптимезация
	Local $aAffix = StringSplit($arrAffix,',)', 2)
	for $string in $aAffix
		if StringInStr($Line, $string) then
			if StringInStr($string, 'to Strength') or StringInStr($string, 'All Attributes') Then
				Return int(ValueAffix($Line)/2)
			ElseIf StringInStr($string, 'and') Then
				Return ValueAffix($Line)*2
			ElseIf StringInStr($string, 'all Elemental') Then
				Return ValueAffix($Line)*3
			Else
				Return ValueAffix($Line)
			EndIf
		EndIf
	Next
EndFunc

Func ValueAffix($Line) ; численное значение суфикса или префикса
	;требуется оптимезация

	Local $iValue = 0
	Local $n_Value = 0
	Local $arrLine = StringSplit($Line,'+ %', 2)
	for $i in $arrLine
		if StringIsDigit($i) Then
			$iValue += $i
			$n_Value += 1
		EndIf
	Next
	Return $iValue/$n_Value
EndFunc

Func CheckFreeAffix($ObjectCorrupt, $arrSumAffix) ;проверка свободных суфиксов и префиксов предмета
	;требуется оптимезация
	if $ObjectCorrupt Then
		for $i = 0 to UBound($arrSumAffix) - 1
			if not $ArrPriorityAffix[$i][1] then _ArrayDelete($ArrPriorityAffix, $i)
		Next
		Return
	EndIf
	for $i = 0 to UBound($arrSumAffix) - 1
		if $arrSumAffix[$i] = 3 Then
			for $j=UBound($ArrPriorityAffix) - 1 to 0 Step -1
				if $ArrPriorityAffix[$j][0] = $i+1 and not $ArrPriorityAffix[$j][1] then _ArrayDelete($ArrPriorityAffix, $j)
			Next
		EndIf
	Next

	Redim $ArrPriorityAffix[UBound($ArrPriorityAffix)+1][4]
	$ArrPriorityAffix[UBound($ArrPriorityAffix)-1][0] = $arrSumAffix[0]
	$ArrPriorityAffix[UBound($ArrPriorityAffix)-1][1] = $arrSumAffix[1]

EndFunc

