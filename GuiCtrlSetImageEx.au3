#include <ButtonConstants.au3>
#include <GDIPlus.au3>
#include <SendMessage.au3>
#include <StaticConstants.au3>
#include <WinAPI.au3>
#include <WinAPIGdi.au3>
#include <WinAPIInternals.au3>
#include <WinAPIRes.au3>

If $__g_hGDIPDll = 0 Then
	_GDIPlus_Startup()
	OnAutoItExitRegister('__GCSIE_Exit')
EndIf
Global Const $__g_sGCSIE_Version = '1.3.0.0'
Global Const $__g_sGCSIE_Date = '2018/06/15 15:00:00'
Global Enum $GCSIE_NOTEXT, $GCSIE_LEFT, $GCSIE_RIGHT

Func __GCSIE_Exit()
	_GDIPlus_Shutdown()
EndFunc   ;==>__GCSIE_Exit

;===============================================================================
; Name:             : _GuiCtrlSetImageEx
; Description:		: Funktion zum laden von Grafikdateien (alle die GDI+ unterstuetzt) in ein Pic-Control
;                     oder in ein Button-Control (beim Button auch als Grafik + Text).
;                     Dabei werden die Grafikdateien proportional in das Control eingepasst (skaliert)
;                     Die Grafikdatei darf auch als Variable mit Binaerdaten uebergeben werden.
; Syntax:           : _GuiCtrlSetImageEx([$idCtrl][, $sImgFile][, $sText][, $iTxtPos][, $iFontSize][, $iFontStyle][, $iFontName][, $iFontQuality])
; Parameter(s):		: $idCtrl = ID des Controlelements (kann auch "Default" oder "-1" sein)
;                     $sImgFile = der Pfad und Dateiname der Grafikdatei oder die Grafikdatei als Variable mit Binaerdaten
;                     $sText = der Text, der auf dem Button erscheinen soll
;                     $iTxtPos = die Postion des Textes (links oder rechts von der Grafik)
;                     $iFontSize = die Groesse der Schrift
;                     $iFontStyle = der Schriftstil (Werte wie bei "_GDIPlus_FontCreate()")
;                     $iFontName = Schriftart
;                     $iFontQuality = Schriftqualitaet
; Requirement:		: oben stehende Includes und AutoIt-Version >= v3.3.12.0
; Return Value(s):	: Im Erfolgsfall wird TRUE zurückgegeben (@error = 0). Ansonsten:
;                     @error = 1 wenn das Pic-Control nicht existiert
;                     @error = 2 wenn die Abmessungen des Pic-Control nicht gelesen werden konnten
; Author(s):		: Oscar (www.autoit.de)
; Version / Date:   : 1.3.0.0 / 15.06.2018
;===============================================================================
Func _GuiCtrlSetImageEx($idCtrl, $sImgFile, $sText = '', $iTxtPos = $GCSIE_NOTEXT, $iFontSize = 10, $iFontStyle = 0, $iFontName = 'Arial', $iFontQuality = 4)
	Local $hCtrl, $hParent, $aCtrlPos, $hBitmap, $hGfx, $hImage, $hResize, $hBMP, $tRect, $hPrevImage, $hDC, $iBkColor, $iError = 0
	Local $hBrush, $hFormat, $hFamily, $hFont, $tLayout, $iMsg, $sClassName, $aDim[2] = [0, 0], $iScaleW, $iScaleH, $iScaleF = 1
	If $idCtrl = Default Or $idCtrl <= 0 Then $idCtrl = _WinAPI_GetDlgCtrlID(GUICtrlGetHandle($idCtrl))
	$hCtrl = GUICtrlGetHandle($idCtrl) ; das Handle vom Pic-Control holen
	$hParent = _WinAPI_GetParent($hCtrl) ; das Fenster des Pic-Controls ermitteln
	If $hParent = 0 Then Return SetError(1, 0, False)
	$aCtrlPos = ControlGetPos($hParent, '', $idCtrl) ; die Abmessungen des Pic-Controls ermitteln
	If @error Then Return SetError(2, 0, False)
	$hBitmap = _GDIPlus_BitmapCreateFromScan0($aCtrlPos[2], $aCtrlPos[3]) ; Eine Bitmap erstellen
	$hGfx = _GDIPlus_ImageGetGraphicsContext($hBitmap) ; Graphic-Context der Bitmap holen
	_GDIPlus_GraphicsSetInterpolationMode($hGfx, $GDIP_INTERPOLATIONMODE_HIGHQUALITYBICUBIC)
	Select
		Case _GDIPlus_ImageGetType($sImgFile) = $GDIP_IMAGETYPE_BITMAP ; wenn eine GDI+ Bitmap uebergeben wurde
			$hImage = _GDIPlus_ImageScale($sImgFile, 1, 1) ; Kopie der Bitmap erstellen
		Case IsBinary($sImgFile) ; wenn die Grafikdatei als Binaerdaten uebergeben wurde
			$hImage = _GDIPlus_BitmapCreateFromMemory($sImgFile)
		Case Else ; ansonsten (Grafikdatei befindet sich auf Datentraeger)...
			$hImage = _GDIPlus_BitmapCreateFromFile($sImgFile) ; die Grafikdatei laden
	EndSelect
	$sClassName = _WinAPI_GetClassName($hCtrl)
	Switch $sClassName
		Case 'Button' ; wenn die Grafikdatei fuer ein Button-Control gedacht ist
			If Not BitAND(_WinAPI_GetWindowLong($hCtrl, $GWL_STYLE), $BS_BITMAP) Then GUICtrlSetStyle($idCtrl, $BS_BITMAP)
			If $sText <> '' And $iTxtPos = $GCSIE_NOTEXT Then $iTxtPos = $GCSIE_RIGHT
			$iMsg = $BM_SETIMAGE ; beim Button muss unten (_SendMessage) $BM_SETIMAGE als Message gesendet werden
			If $hImage Then
				$hResize = _GDIPlus_ImageResize($hImage, $aCtrlPos[3] - 10, $aCtrlPos[3] - 10)
				$aDim = _GDIPlus_ImageGetDimension($hResize) ; die Breite und Hoehe der skalierten Grafikdatei holen
				Switch $iTxtPos
					Case $GCSIE_NOTEXT
						_GDIPlus_GraphicsDrawImage($hGfx, $hResize, $aCtrlPos[2] / 2 - $aDim[0] / 2, $aCtrlPos[3] / 2 - $aDim[1] / 2)
					Case $GCSIE_LEFT
						_GDIPlus_GraphicsDrawImage($hGfx, $hResize, $aCtrlPos[2] - $aDim[0] - 8, $aCtrlPos[3] / 2 - $aDim[1] / 2)
					Case $GCSIE_RIGHT
						_GDIPlus_GraphicsDrawImage($hGfx, $hResize, 8, $aCtrlPos[3] / 2 - $aDim[1] / 2)
				EndSwitch
			EndIf
			If $sText <> '' Then ; wenn ein Text auf dem Button angezeigt werden soll
				_GDIPlus_GraphicsSetTextRenderingHint($hGfx, $iFontQuality) ; Textrendering festlegen
				$hBrush = _GDIPlus_BrushCreateSolid(0xFF000000) ; Farbe festlegen (ARGB)
				$hFamily = _GDIPlus_FontFamilyCreate($iFontName) ; Schriftart festlegen
				$hFont = _GDIPlus_FontCreate($hFamily, $iFontSize, $iFontStyle) ; Schriftgroesse und -stil festlegen
				$hFormat = _GDIPlus_StringFormatCreate()
				_GDIPlus_StringFormatSetAlign($hFormat, 1) ; horizontal zentrieren
				_GDIPlus_StringFormatSetLineAlign($hFormat, 1) ; vertikal zentrieren
				Switch $iTxtPos
					Case $GCSIE_LEFT
						$tLayout = _GDIPlus_RectFCreate(0, 0, $aCtrlPos[2] - $aDim[0], $aCtrlPos[3])
					Case $GCSIE_RIGHT
						$tLayout = _GDIPlus_RectFCreate($aDim[0], 0, $aCtrlPos[2] - $aDim[0], $aCtrlPos[3])
				EndSwitch
				_GDIPlus_GraphicsDrawStringEx($hGfx, $sText, $hFont, $tLayout, $hFormat, $hBrush)
			EndIf
		Case 'Static' ; wenn die Grafikdatei fuer ein Pic-Control gedacht ist
			$iMsg = $STM_SETIMAGE ; beim Pic-Control muss unten (_SendMessage) $STM_SETIMAGE als Message gesendet werden
			If $hImage Then
				$aDim = _GDIPlus_ImageGetDimension($hImage) ; die Breite und Hoehe der Grafikdatei holen
				; wenn die Groesse des Pic-Controls kleiner ist, als die Grafikdatei,
				; dann muss die Grafikdatei skaliert werden (Skalierungsfaktor berechnen):
				If ($aCtrlPos[2] < $aDim[0] Or $aCtrlPos[3] < $aDim[1]) Then
					$iScaleW = $aCtrlPos[2] / $aDim[0]
					$iScaleH = $aCtrlPos[3] / $aDim[1]
					$iScaleF = ($iScaleW > $iScaleH ? $iScaleH : $iScaleW)
				EndIf
				$hResize = _GDIPlus_ImageScale($hImage, $iScaleF, $iScaleF)
				$aDim = _GDIPlus_ImageGetDimension($hResize) ; die Breite und Hoehe der skalierten Grafikdatei holen
				_GDIPlus_GraphicsDrawImage($hGfx, $hResize, $aCtrlPos[2] / 2 - $aDim[0] / 2, $aCtrlPos[3] / 2 - $aDim[1] / 2)
			Else ; wenn keine Grafik angegeben wurde
				$hDC = _WinAPI_GetDC($hParent)
				$iBkColor = _WinAPI_GetBkColor($hDC) ; Hintergrundfarbe des Fensters ermitteln
				_WinAPI_ReleaseDC($hParent, $hDC)
				_GDIPlus_GraphicsClear($hGfx, 0xFF000000 + $iBkColor) ; die Bitmap mit der Hintergrundfarbe fuellen
			EndIf
	EndSwitch
	$hBMP = _GDIPlus_BitmapCreateDIBFromBitmap($hBitmap)
	$hPrevImage = _SendMessage($hCtrl, $iMsg, $IMAGE_BITMAP, $hBMP)
	If $hPrevImage Then
		If Not _WinAPI_DeleteObject($hPrevImage) Then _WinAPI_DestroyIcon($hPrevImage)
	EndIf
	$tRect = _WinAPI_CreateRectEx($aCtrlPos[0], $aCtrlPos[1], $aCtrlPos[2], $aCtrlPos[3])
	_WinAPI_InvalidateRect($hParent, $tRect)
	_WinAPI_DeleteObject($hBMP)
	_GDIPlus_FontDispose($hFont)
	_GDIPlus_FontFamilyDispose($hFamily)
	_GDIPlus_StringFormatDispose($hFormat)
	_GDIPlus_BrushDispose($hBrush)
	_GDIPlus_GraphicsDispose($hGfx)
	_GDIPlus_BitmapDispose($hResize)
	_GDIPlus_BitmapDispose($hBitmap)
	_GDIPlus_BitmapDispose($hImage)
	Return SetError(0, 0, True)
EndFunc   ;==>_GuiCtrlSetImageEx
