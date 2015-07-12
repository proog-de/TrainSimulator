'FreeBASIC
'Train Simulator


#define TurnoutNew      'Draw a simple turnout, not a railway crossing


Const     Version = "V 1.01"
Const FileVersion = "V 1.00"

'    Train Simulator
'    Copyright by oog/proog.de, 2011
'
'    This program is free software: you can redistribute it and/or modify
'    it under the terms of the GNU General Public License as published by
'    the Free Software Foundation, either version 3 of the License, Or
'    (at your option) any later version.
'
'    This program is distributed in the hope that it will be useful,
'    but WITHOUT ANY WARRANTY; without even the implied warranty of
'    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
'    GNU General Public License for more details.
'
'    You should have received a copy of the GNU General Public License
'    along with this program.  If not, see <http://www.gnu.org/licenses/>.

' Whatsnew
' V1.01: Patch - Zero pointer access error when remove a turnout


'File format change
'V 0.40:
'    future compatible file format (html inspired)
'    
'    ############################################
'    ## html inspired file format
'    ############################################
'    
'    executable command:
'      <!command>
'      <!command parameter1,para2,...>
'    
'    data block:
'      <name>
'       [Block]
'      </name>
'
'      .. where [Block] is a list of numeric or string values
'    
'    numeric value (inside a block):
'      <name=n>
'    
'    string value (inside a block):
'      <name="string">
'    
'    ############################################


'V35:
'  added train car name
'V36:
'  added visible flag for tracks
'  just affect new save files, can load V35 files without pproblems


'Coordinates are stored in integers (32 bit)
'Resolution is 1 mm

' German - English
' Weiche = Turnout
' Gerade = Straight track
' Waggon = car
' Nebengleis = Passing siding
' Passagierwaggon = cab car
' Lokomotive - ?
' 

'limit simulated fps
Const CFpsLimit=30.0
Const CFpsCheck=1
Const TimeChecks=20       'perform InTime check every n steps (Tracks, Trains)


Const CGenericTracks=0
Const VisBorder=000         '0..100%
Const SlowSpeed=50
Const FastSpeed=90
Const CShowTrainStops=10    '0=off, n=number of max display list
Const CShowTrainDeliver=1   '0=off, 1=on
Const CShowMoney=1          '0=off, 1=on
Const MaxSpTurnFw=90
Const MaxSpTurnSw=50
Const CSpeedLimit=1         '0=off, 1=on
Const MoneyScale="0"
Const CRailway=1            '0=off, 1=on
Const CEndlessDrag=1
Const CMouseAccLevel=2

#include "GFXPrint.bas"
#include "vge.bas"

'################################################
'## Definitions and constants
'################################################


'convert pixel to world, window 2
#define p2wxw2(x) (((x)-view2.Offx)*view2.Scale)
#define p2wyw2(y) (((y)-view2.Offy)*view2.Scale)

'define data type to save coordinates
#define xyz Integer
'#define xyz Single

#define mapon 1
#define landmapon 1

Const CCamSteps=10            '1..100 number of frames for slide animation
                              'don't set to zero (div by zero error)
Const CScanCam=200            'change cam view after # frames
Const CScanCamActive=1        '0=off, 1=on

Const CZoomMinLevel=10        '1 pixel = 10mm
Const CZoomMaxLevel=100000    '1 pixel = 100m
Const CGroundColor = &H106010 'Default Ground Color
Const CTextColor   = &HFFFFFF 'Default Text Color
Const CMsgBoxColor = &H303030 'Message Box Background Color

'menu
Const MenuBGCol   = &Hc2c2c2  'Menu button backgroung
Const MenuFGCol   = &H101010  'Menu butto foreground
Const MenuAcCol   = &H909090  'Menu active Outline
Const MenuOlCol   = &H606060  'Menu butto Outline
Const MBWidth     = 31        'Menu Button Size
Const MBHeight    = 31        'Menu Button Size
Const MenuMaxX    = 9         'Max menu icon columns
Const MenuMaxY    = 9         'max menu icon lines
Const MaxIcons    = 99        'max number of bmp icons
Const CmdLength   = 20        'max icon command string length
Const MenuName0="Home"
Const MenuName1="Control"
Const MenuName2="Files"
Const MenuName3="Track"
Const MenuName4="Build"
'Const MenuName5="Tools"


Const CDataPath="./data/"
Const CExt=".txt"                 ' file name extension
Const CIniFileNew="tsini"         ' prog configuration
Const CDataFileNew="tsdat"        ' tracks, trains / world
Const CModelFileNew="tsmod"       ' vector models / items
Const CLogFileNew="tslog"         ' vector models / items
Const CExportTrack="tsexp"        ' exported track

Const CMenuIconFile="menuico.bmp" ' menu icon bitmap
Const CSplash="tsimg1.bmp"        ' splash screen

Const MessageTimer=100
Const CMapPerformance=20        ' max # msec to draw bitmaps
Const CDeliverTime=10           ' sec * fps

Const m=1000  '1 Meter
Const PI As Single = 4*Atn(1.0)
Const MaxItems=2000             'vector models placed in world
Const MaxModels=100             'vector model (building, train, ...)
Const MaxBmp=100                'Max loadable bmp files
Const MaxMaps=1000              'Max placeable bmp files as background images
Const MaxTrains=10010
Const MaxCars=100               'max train cars
Const DefMaxCars=12             'max train cars as default value
Const MaxTracks=10010
Const MaxTurnouts=2000
Const WorldX=20, WorldY=15      'World size in km
Const MapRes=10
Const MinAngle=512/64           'smallest angle, 
                                'need MinAngle turns for a track circle





Const ItemNum=1


#define ShowVisBorder

Const click=4       'mouse click or drag
                    'If g.Mousehold>g.Fps/click

Const trackwidth=2.0/2

'Keyboard control
Const K_esc=Chr$(27)                        'ESC
Const K_help=Chr$(255)+Chr$(59)             'F1
Const K_helpdisp=Chr$(255)+Chr$(60)         'F2
Const K_ohd=Chr$(255)+Chr$(61)              'F3
Const K_Controller=Chr$(255)+Chr$(62)       'F4
Const K_F5=Chr$(255)+Chr$(63)               'F5
Const K_F6=Chr$(255)+Chr$(64)               'F6
Const K_F7=Chr$(255)+Chr$(65)               'F7
Const K_F8=Chr$(255)+Chr$(66)               'F8
Const K_F9=Chr$(255)+Chr$(67)               'F9
Const K_F10=Chr$(255)+Chr$(68)              'F10

Const K_edittrackOpen="o"
Const K_edittrackClose="c"
Const K_edittrackInstallTurnout="u"
Const K_edittrackNext="+"
Const K_edittrackPrev="-"
Const K_edittrackSignal="i"
Const K_edittrackForward="f"
Const K_edittrackStation="s"
Const K_edittrackLeft="l"
Const K_edittrackRight="r"
'Const K_edittrackSharpLeft="L"
'Const K_edittrackSharpRight="R"
Const K_edittrackEndtrack="E"
Const K_edittrackInsert=""+Chr$(255)+"R"  'Insert
Const K_edittrackDelete=""+Chr$(255)+"S"  'Delete
Const K_edittrackDeleteBS=""+Chr$(8)      'Delete Backspace
'Const K_edittrackDefaultlength="d"
Const K_edittrackVisible="v"

Const K_SwitchTurnout="u"
Const K_SwitchTurnoutReverse="U"
'Const K_NewItem="n"
Const K_Plus="+"
Const K_Minus="-"
Const K_Insert=Chr$(255)+"R"                'Insert
Const K_Delete=Chr$(255)+"S"                'Delete
Const K_rotateleft="<"
Const K_rotateright=">"
Const K_zoomin=Chr$(255)+"I"                'Pg-Up
Const K_zoomout=Chr$(255)+"Q"               'Pg-Down
Const K_grid="g"
Const K_map="M"
Const K_landmap="m"
Const K_debug="d"
Const K_SelectCamera="1234567890"
Const K_CtrlNext=Chr$(9)                    'Tab
Const K_CtrlPrev=Chr$(255)+Chr$(15)+Chr$(9) 'Shift+Tab
Const K_WatchTrain="w"
Const K_CenterTrack="t"
Const K_Stop="s"
Const K_ManualCtrl=" "
Const K_TrainAutopilot="a"
Const K_AccLess=","
Const K_AccMore="."
Const K_AccReverse="r"
Const K_AccRevMore="k"
Const K_AccFwdMore="l"
Const K_MenuVisible=" "
Const K_CamUp=Chr$(255)+"H"                 'Cursor up
Const K_CamDn=Chr$(255)+"P"                 'Cursor down
Const K_CamLt=Chr$(255)+"K"                 'Cursor left
Const K_CamRt=Chr$(255)+"M"                 'Cursor right

'edit
Const K_CursUp=Chr$(255)+"H"                'Cursor up
Const K_CursDn=Chr$(255)+"P"                'Cursor down
Const K_CursLt=Chr$(255)+"K"                'Cursor left
Const K_CursRt=Chr$(255)+"M"                'Cursor right
Const K_Pos1=Chr$(255)+"G"                  'Pos1
Const K_End=Chr$(255)+"O"                   'End

Const K_Quit=Chr$(27)                       'Esc
Const K_Quit2=Chr$(255)+"k"                 'Window Close-Button

Const invisiblecolor = &HFF00FF

'Train control flags
Const none=&H0000
Const auto=&H0001
Const brake=&H0002
Const restart=&H0004
Const crash=&H8000




'################################################
'## Menu
'################################################


Type MenuBtn
  As Integer icon           'index number of icon bmp
  As Integer state          '0..2 (off, on, inactive), from bmp file left to right
  As Integer locked         'button does not switch, if klicked
  As String*CmdLength cmd   'command, if button has been switched on
End Type


Type TMenu
  As String*CmdLength MName 'name of actual displayed menu (home, build, control..)
  As Integer PosX           'absolute coordinate (pixel)
  As Integer PosY
  As Integer MWidth         'Menu bitmap (pixel)
  As Integer MHeight
  As Integer MBX            'Menu button matrix size
  As Integer MBY
  As Integer Alpha          '255=solid, 0=invisible
  As Integer Fade           'fade from 255 to alpha
  As Integer MouseX         'Icon under mouse cursor
  As Integer MouseY
  As Integer MouseOver      'Mouse moves over menu area
  As String*CmdLength cmd   'command, if button has been switched on
  As Integer CmdState       'icon state after mouse click
  As String*CmdLength cmdh  'icon command help string
  As Integer cmdc           'icon command help counter
  As MenuBtn MB(MenuMaxY,MenuMaxX)
End Type




'################################################
'## Types
'################################################


Enum t_tsmode
  ts_stop=1
  ts_run
  ts_control
  ts_files
  ts_edittrack
  ts_build
End Enum

Type rect
  As Integer minx,miny,maxx,maxy
End Type

Type PTrack As TTrack Ptr
Type PTurnout As TTurnout Ptr
Type PTrackBase As TTrackBase Ptr
Type PTrain As TTrain Ptr
Type PMapR As TMapR Ptr
Type PItem As TItem Ptr
Type PModel As TModel Ptr
Type PBmp As TBmp Ptr
Type PBmp1023 As TBmp1023 Ptr

Type TTrack
  As PTrackBase mytrack 'Where am I driving on?
  As PTrack pf, pr      'forward/reverse (drive train)
  As PTrack pn          'next track (draw, load, save)
  As xyz x, y, z        'position of track start
  As Integer length     'track segment length
  As Integer lengthn    'track segment length to next (unswitched turnout)
  As Integer TNum       'Info: track segment counter
  As String tname       'Info: which type of track (build string)
  As Integer angle      'Info: angle of track segment
  As Integer sin0, cos0 'Info: position offset of left/right track line
  As Integer distance   'Info: distance from start
  As String SigF, SigR  'Info: signal for train control, autopilot
  As PTurnout turn      'Turnout pointer
  As PTrain LockedBy    'pointer to train / NULL
  As Integer visible    '0=hidden tracks
End Type

Type TTurnout
  As p3 SwitchCoor      'switch coordinates, relative to pr1
  As PTrack pr, pf      'actual pointer to track
  As PTrack pr1, pf1    'pointer to track 1
  As PTrack pr2, pf2    'pointer to track 2
  As Integer turn       '1=forward, 2=turned
End Type

Type TTrackBase
  As PTrack start, last 'link pointer to start/last segment
  As String build       'Track build string
  As xyz x, y, z        'position of track start
  As xyz xa, ya, za     'actual position of track end
  As Integer angle,anga 'angle of track start
  As Integer length     'track length
  As String tname       'Track name
  As rect dimension
End Type

Enum TrainState
  ts_top=1
  ts_drive
  ts_deliver
End Enum

Type TTrain
  As String tname       'Train name
  As PTrack tr          'tr=actual track segment
  As Integer ps         'position on track segment
  As Single sp          'speed
  As Integer x,y,z      'coordinates
  As Integer waggons
  As Integer pic
  As Integer waggonpic
  As Integer control    '0=none, 1=brake
  As Integer AutoSpeed  'if AutoSpeed<>0: change train speed
  As Integer uOdometer  'general distance counter, resolution = 1mm
  As Integer TripOdo    'trip distance counter, resolution = 1mm
  As Integer Odometer   'general distance counter, resolution = 1km
  As Integer Damage     'increase when too fast crossing turnouts
  As Integer Credit     'delivery at station increases, driving decreases
  As Integer MaxSpeed   'maximum speed
  As Integer MaxCars    'maximum car capacity
  As TrainState state   'train state nubmer
  As Integer si1, si2, si3  'state vaiables
End Type

Type TMapR
  As Integer x1,y1,z1 'coordinates
  As Integer x2,y2,z2 'coordinates
  As Integer Color
  As PMapR pnext
End Type

Type TItem
  As p3 a,b   'coordinates
  As Integer build
  As Integer Col, ScaleType
End Type

Type TModel
  As String mType
  As String mName
  As String mBuild      'vector graphics commands
End Type

Type TBmp
  As Integer x, y       'coordinates
  As Integer scale      '1230 -> pixel size is 1.23 meter
  As Integer ZoomMin    'zoom range for display
  As Integer ZoomMax    'zoom range for display
  As Integer BmpIndex   'number ob BMP1023-Array
  As String mapname     'symbolic name
End Type

Type TBmp1023
  As String filename    'file name
  As Integer w, h       'size
  As Integer data(1023,1023)
End Type

Type TWorldStatus
 'The world
 As PMapR Map
 As PItem Items(MaxItems)
 As PBmp MapHdr(MaxMaps)
 As PBmp1023 MapData(MaxBmp)
 As PTrackBase Start(MaxTracks)
 As PModel Model(MaxModels)
 As PTurnout Turnouts(MaxTurnouts)
 As PTrain Train(MaxTrains)
End Type

Type TWorldView
 'View

' As Integer WinX,WinY      'Window size and position -> now in vge.bas
' As Integer Debug          'debug view -> now in vge.bas
' As Integer Offx,Offy      'World view position -> now in vge.bas
' As Integer Scale          'World view scale -> now in vge.bas

 As Integer PosX,PosY       'Window position (for drawing a border)
 As Integer VisBorderX,VisBorderY   'Location offset for tracks etc.

 As Integer Cam,CamSteps
 As Integer OldCamX
 As Integer OldCamY
 As Integer OldCamScale
 As Integer CamSlide

 As Integer mapactive
 As Integer landmapactive
 As Integer GridOn
End Type

Enum EditState
  es_Off=1
  es_PlaceTrack
  es_ImportTrackHere
  es_PlaceItem
  es_BuildTurnout
End Enum

Type TGlobals
 'The user interface
 As String buildtrk 'definition of track building characters
 As String ks
 As Integer ofx,ofy                 'Location offset for tracks etc.
 As PTrack EditTrkPtr, EditTrkPtrA
 As PTrackBase EditTrkBasePtr
 As EditState es
 As Integer mousex, mousey, mousewh, mousebt
 As Integer mousexs, mouseys, mousewhs, mousebts
 As Integer mousehold, KlickStart
 As Integer ItemSel, trksel, EditTrk, ctrl
 As String ItemSelName
 As Integer Drag
 As Double now, frame, Fps, Fps0
 As Double AvgTime, AvgMax, ThisTime, LastTime
 As Double ReserveTime
 As Integer FpsLow, SkipFrame, PrintFrame
 As Integer framestotal           'count simulated frames
 As Integer money                 'how much you have
End Type


'################################################
'## Variables
'################################################


'Graphics screen pointer
Dim Shared As Any Ptr win480, win160


'Menu
Dim Shared As Any Ptr MenuIcon(MaxIcons,2)
Dim Shared As String MenuStr
Dim Shared As TMenu Menu


'The world
Dim Shared As t_tsmode tsmode
Dim Shared As TWorldStatus w
Dim Shared As TWorldView wv,wView1,wView2,wView3,wView4
Dim Shared As TView v,View1,View2,View3,View4
Dim Shared As TGlobals g


'Global stuff
Dim Shared As String ks   'user input from keyboard
Dim As PMapR Map1         'temporary pointer (follow chain)
Dim As Integer i, j       'temporary variables
Dim As Integer col        'temporary variable
Dim As String s           'temporary string
Dim As PTrain waggon      'temporary pointer (display train cars)
Dim As Integer wagx, wagy 'temporary coordinates (display train cars)
Dim As Integer ofx, ofy   'Location offset for tracks etc.

Dim Shared As Integer FpsLimit=CFpsLimit
Dim Shared As Integer SpeedScale=360/CFpsLimit
Dim Shared As Single BrakeSteps
Dim Shared As Integer FpsCheck=CFpsCheck
Dim Shared As Integer Railway=CRailway
Dim Shared As Integer MouseCursor
Dim Shared As Integer EndlessDrag=CEndlessDrag
Dim Shared As Integer MouseAccLevel=CMouseAccLevel

Dim Shared As String MenuSelect           'Selected Menu

Dim Shared As Integer helpman=2           'display manual on/off
Dim Shared As Integer OhdFps              'OHD on/off
Dim Shared As Integer Controller          'Controller on/off
Dim Shared As Integer MouseWindow         'window area under mouse cursor

Dim Shared As String DataPath             'ini-file, bitmaps ...
Dim Shared As Integer MapPerformance      'time to draw background bitmaps (msec)

Dim Shared As Integer ZoomMinLevel=CZoomMinLevel
Dim Shared As Integer ZoomMaxLevel=CZoomMaxLevel
Dim Shared As Integer GroundColor=CGroundColor
Dim Shared As Integer ScanCam
Dim Shared As Integer GenericTracks=CGenericTracks
Dim Shared As Integer SpeedLimit=CSpeedLimit
Dim Shared As Integer ShowTrainStops=CShowTrainStops
Dim Shared As Integer ShowTrainDeliver=CShowTrainDeliver
Dim Shared As Integer ShowMoney=CShowMoney


'calculated constants for screen layout
Dim Shared As Integer ScreenWIni
Dim Shared As Integer ScreenW
Dim Shared As Integer ScreenH
Dim Shared As Integer MainViewW
Dim Shared As Integer MainViewH
Dim Shared As Integer SideViewW
Dim Shared As Integer SideViewH
Dim Shared As Integer ScreenX
Dim Shared As Integer ScreenY
Dim Shared As Integer MainViewX
Dim Shared As Integer MainViewY
Dim Shared As Integer SideViewX
Dim Shared As Integer SideViewY


'Track editor
Dim Shared As String ted_dir   'direction lLfRr
Dim Shared As String ted_len   'track length 0..9


Randomize

'Build a track
'A track will be built from a string
'Every letter adds a new segment to the track
'
' f[l] = forward track
' l[l] = left turn track (use 8 times for 180° turn)
' L[l] = sharp left turn (use 16 times for 180° turn)
' r[l] = right turn
' R[l] = sharp right turn
' s[l] = station, 5 times as long as a track
'        entering a station will cause the train to brake
'        until it stops.
' *[n] = place last item n times
'
' [l] = 0..9
' [n] = 2..99
'
' Default length of a new segment is 25 meter
' Lenghth can be changed by addin a single digit behind the letter
' length can be set from 0 (5 m) to 9 (50 m)
'
' Example 1:
' f  = forward 25 meter
' f0 = forward 5 meter
' f1 = forward 10 meter
' l2 = left 15 meter
' l3 = left 20 meter
' R5 = sharp right 30 meter
' r9 = right 50 meter
'
' Example 2: Build track as a "0"
' start with "LLLL" for a 90° Left turn, built with 25 m elements
' add "LLLL9" for a next 90° Left turn with a long 50 m end
' add "LLLL LLLL9" to complete the track
'
' Spaces and line breaks are allowed in the string,
' they will be ignored.


g.BuildTrk="flrLRsec"   'build track characters



'################################################
'## logfile
'################################################


'create new log file

Sub NewLogFile
  Dim As Integer i
  i=FreeFile
  If 0=Open ("./"+CLogFileNew+CExt For Output As #i) Then
    Print #i, "###"
    Print #i, "### TrainSim Logfile ###"
    Print #i, "###"
    Print #i,
    Close #i
  Else
    Print "Error, can't create logfile "+DataPath+CLogFileNew
    Sleep
  EndIf
End Sub


Sub LogFile(s As String)
  Dim As Integer f, r
  
  f=FreeFile
  If 0=Open ("./"+CLogFileNew+CExt For Append As #f) Then
    If InStr(lcase(s), "error") Then
      'Print extra blank Line before Error message
      Print #f,
    EndIf
    Print #f,
    If s<>"" Then
      Print #f, right("00000000000"+str(g.FramesTotal),11)+" "+s;
    EndIf
    Close #f
  EndIf
  
End Sub


Sub LogFileNoBr(s As String)
  Dim As Integer f, r
  
  f=FreeFile
  If 0=Open ("./"+CLogFileNew+CExt For Append As #f) Then
    Print #f, s;
    Close #f
  EndIf
  
End Sub



'################################################
'## Little helper (1)
'################################################


Function InTime(f  As Integer) As Integer
  Dim As Integer i
  
  If FpsCheck Then
    i=(Timer-g.LastTime)<(1.0/(fpslimit+f))
  Else
    i=1
  EndIf
  Return i
End Function


'################################################
'## Views init
'################################################

Sub ViewInit
  win480=imagecreate(MainViewW,MainViewH)
  win160=imagecreate(SideViewW,SideViewH)
  
  'Cls
  Line win480,(0,0)-(View1.WinX-1,View1.WinY-1),GroundColor,BF

  wV.PosX=0+1
  wV.PosY=0+1
  wV.CamSteps=CCamSteps
  
  wView1.PosX=0+1
  wView1.PosY=0+1
  View1.WinX=MainViewW
  View1.WinY=MainViewH
  View1.Scale=1088
  wView1.CamSteps=CCamSteps
  
  wView1.VisBorderX=-(View1.WinX*(VisBorder))/200
  wView1.VisBorderY=-(View1.WinY*(VisBorder))/200
  
  wView1.cam=0
  wView1.MapActive=0
  View1.Debug=0
  wView1.Gridon=0
  
  wView2.PosX=MainViewW+3
  wView2.PosY=0+1
  View2.WinX=SideViewW
  View2.WinY=SideViewH
  View2.Scale=15000
  wView2.CamSteps=CCamSteps
  
  wView2.VisBorderX=-(View2.WinX*(VisBorder))/200
  wView2.VisBorderY=-(View2.WinY*(VisBorder))/200
  
  wView2.cam=0
  wView2.MapActive=0
  View2.Debug=0
  wView2.Gridon=0
  View2.OffX=View2.WinX/2-1001050*m/View2.Scale
  View2.OffY=View2.WinY/2-1000200*m/View2.Scale
  
  View3=View2
  wView3.PosX=MainViewW+3
  wView3.PosY=SideViewH+3
  View3.Scale=800
  wView3.cam=1
  
  v=View1
End Sub


Sub ScreenInit(ScreenWidth As Integer, ScreenHeight As Integer)
  If (ScreenWidth>=640) AndAlso (ScreenWidth<=1920) _
  AndAlso (ScreenHeight>=480) AndAlso (ScreenHeight<=1200) _
  Then
    ScreenW=ScreenWidth
    ScreenH=ScreenHeight
  Else
    ScreenW=640
    ScreenH=480
    LogFile("ScreenInit Error: Illegal Resolution (" _
      +str(ScreenWidth)+","+str(ScreenHeight)+")")
    LogFile("  Set to default (640*480)")
  EndIf
  'calculated constants for screen layout
  MainViewW=ScreenW*3/4-2
  MainViewH=ScreenH-2
  SideViewW=ScreenW/4-2
  SideViewH=ScreenH/3-2
  ScreenX=ScreenW-1
  ScreenY=ScreenH-1
  MainViewX=MainViewW-1
  MainViewY=MainViewH-1
  SideViewX=SideViewW-1
  SideViewY=SideViewH-1
  screenres ScreenW,ScreenH,24
End Sub


Dim Shared As Integer MsgCnt, MsgPtr
Dim Shared As String NewMessage
Dim Shared As String MessageLog(1000)
Sub message(msg As String)
  LogFile("MSG: "+msg)
  MsgCnt=MessageTimer
  NewMessage=msg
  MessageLog(MsgPtr)=msg
  MsgPtr+=1
  If MsgPtr=1000 Then
    MsgPtr=0
  EndIf
End Sub


Function MoneyStr(mn As Integer) As String
  Dim As String r, s
  
  If mn=0 Then
    r="0"
  Else
    s=Str(Abs(mn))+MoneyScale
    Do While Len(s)>3
      r="."+right(s,3)+r
      s=left(s,Len(s)-3)
    Loop
    r=s+r
    If mn<0 Then
      r="-"+r
    EndIf
  EndIf
  Return r  
End Function


Declare Sub MessageBox(title As String)

Function StrVal(ByRef s As String) As Integer
  'convert number (strind) to integer
  'hex numbers start with 0x
  'a "_" is allowed as separator
  Dim As Integer i, p, d, sign
  
  p=1
  'check minus
  If mid(s,p,1)="-" Then
    p=p+1
    sign=-1
  Else
    sign=1
  EndIf
  
  If mid(s,p,2)="0x" Then
    'convert hex
    p+=2
    Do
      d=InStr("0123456789abcdef",lcase(mid(s,p,1)))
      If d=0 Then
        LogFile("Error: Illegal Number Format: "+s)
        MessageBox("Error: Illegal Number Format: "+s)
        End
      EndIf
      i=i Shl 4
      i=i+(d-1)
      p+=1
      'skip number separator (1_000 = 1000)
      Do While ((mid(s,p,1))="_") AndAlso (p<=Len(s))
        p+=1
      Loop
    Loop Until p>Len(s) OrElse (mid(s,p,1)=",")
  Else
    'convert decimal
    Do
      d=InStr("0123456789",mid(s,p,1))
      If d=0 Then
        LogFile("Error: Illegal Number Format: "+s)
        MessageBox("Error: Illegal Number Format: "+s)
        End
      EndIf
      i=i*10
      i=i+(d-1)
      p+=1
      'skip number separator (1_000 = 1000)
      Do While ((mid(s,p,1))="_") AndAlso (p<=Len(s))
        p+=1
      Loop
    Loop Until p>Len(s) OrElse (mid(s,p,1)=",")
  EndIf
  Return i*sign
End Function


'' A function that creates an image buffer with the same 
'' dimensions as a BMP image, and loads a file into it.

Const NULL As Any Ptr = 0


Function bmp_load( ByRef filename As String ) As Any Ptr
  Dim As Integer filenum, bmpwidth, bmpheight
  Dim As Any Ptr img
  '' open BMP file
  filenum = FreeFile()
  If Open( filename For Binary Access Read As #filenum ) <> 0 Then Return NULL
      '' retrieve BMP dimensions
      Get #filenum, 19, bmpwidth
      Get #filenum, 23, bmpheight
  Close #filenum
  '' create image with BMP dimensions
  img = ImageCreate( bmpwidth, Abs(bmpheight) )
  If img = NULL Then Return NULL
  '' load BMP file into image buffer
  If BLoad( filename, img ) <> 0 Then ImageDestroy( img ): Return NULL
  Return img
End Function


Function GetModelIndex(MName As String ) As Integer
  'return model index or zero
  Dim As Integer i
  
  For i=1 To MaxModels
    If (w.Model(i)<>NULL) AndAlso _
    w.Model(i)->MName=MName Then
      Exit For
    EndIf
  Next i
  If i>=MaxModels Then
    i=0   'not found
  EndIf
  Return i
End Function


Function ModelIndex(MName As String ) As Integer
  'return model index or 1
  Dim As Integer i
  
  i=GetModelIndex(MName)
  If i=0 Then
    LogFile("")
    LogFile("ModelIdex Warning: Model "+MName+" not defined.")
    LogFile("  return 1 as default value")
    i=1
  EndIf
  Return i
End Function


Function GetTrainIndex(TName As String ) As Integer
  'return train index or zero
  Dim As Integer i,r
  
  r=0
  For i=1 To MaxTrains
    If (w.Train(i)<>NULL) AndAlso _
    w.Train(i)->TName=TName Then
      r=i
    EndIf
  Next i
  Return r
End Function


Function GetTrackIndex(TName As String ) As Integer
  'return track index or zero
  Dim As Integer i
  
  For i=1 To MaxTracks
    If (w.Start(i)<>NULL) AndAlso _
    w.Start(i)->TName=TName Then
      Exit For
    EndIf
  Next i
  If i>=MaxTracks Then
    i=0   'not found
  EndIf
  Return i
End Function


Sub CrashTrain(Train As PTrain, reason As String)
  Train->control=crash
  If Reason <>"" Then
    Message("Train "+Train->Tname+" crashed by "+reason)
  EndIf
  train->sp=0
  train->control=Crash
  train->AutoSpeed=0
  Train->Pic=GetModelIndex("Ghost Train")
  Train->WaggonPic=GetModelIndex("Ghost Car")
End Sub


Declare Sub ts_te_TrackEnd



'################################################
'## Graphical Menu
'################################################

Sub LoadMenuIcons
  Dim As Any Ptr MenuIcons
  Dim As Integer bmpw, bmph, mx, my, x, y
  
  MenuIcons=bmp_load(DataPath+CMenuIconFile)
  If MenuIcons=0 Then
    LogFile("")
    LogFile("Error: Menu Icon File not found.")
    LogFile("  "+DataPath+CMenuIconFile)
    LogFile("")
  Else
    If 0=ImageInfo (MenuIcons, bmpw, bmph, , , , ) Then
      If bmph>32 Then
        For y=0 To bmph/32-1
          For x=0 To 2
            MenuIcon(y,x)=ImageCreate(MBWidth,MBHeight)
            Get MenuIcons,(x*32,y*32) - Step (MBWidth-1,MBHeight-1), MenuIcon(y,x)
          Next x
        Next y
      EndIf
    Else
      LogFile("")
      LogFile("Error: Invalid Menu Icon File.")
      LogFile("  "+DataPath+CMenuIconFile)
      LogFile("")
    EndIf
  EndIf
End Sub


Sub MenuSetIcon(mx As Integer,my As Integer,_
    icon As Integer,state As Integer,_
    locked As Integer, cmd As String)
    Menu.MB(mx,my).icon=icon
    Menu.MB(mx,my).state=state
    Menu.MB(mx,my).locked=locked
    Menu.MB(mx,my).cmd=cmd
End Sub


Sub Clearmb(mby As Integer, dwin As Any Ptr)
  'clear menu background
  
  If mby>0 And mby<6 Then
    Line dwin, (0,0) - (157, 2+mby*MBHeight), MenuBGCol,BF
  EndIf
End Sub


Sub drawmb(mb As Integer, state As Integer, _
  mby As Integer, mbx As Integer, dwin As Any Ptr)
  'draw a menu button / icon
  
  Dim As Integer x, y, mx, my
  
  If (mbx>=0) AndAlso (mby>=0) _
  AndAlso (MenuIcon(mb,State)<>NULL) Then
    If State=2 Then
      'menu button disabled
      Put dwin, (1+mbx*MBWidth, 1+mby*MBHeight), MenuIcon(mb,State), PSet
      If mb>1 Then
        'draw disabled grid over button
        Put dwin, (1+mbx*MBWidth, 1+mby*MBHeight), MenuIcon(83,0), Alpha,80
      EndIf
    Else
      Put dwin, (1+mbx*MBWidth, 1+mby*MBHeight), MenuIcon(mb,State), PSet
    EndIf
'    Put dwin, (mbx*(MBWidth+1), mby*(MBHeight+1)), MenuIcon(mb,State), PSet
  EndIf
End Sub


Sub MenuIconState(cmd As String, state As Integer)
  Dim As Integer i,j
  
  For i=0 To Menu.MBX
    For j=0 To Menu.MBY
      If Menu.MB(i,j).cmd=cmd Then
        Menu.MB(i,j).state=state
      EndIf
    Next j
  Next i
End Sub


Sub UpdateMenu
  
  'Control Menu
  
  If (g.ctrl<>0) _
  AndAlso (w.Train(g.ctrl)<>0) _
  AndAlso (w.Train(g.ctrl)->control And auto) Then
    MenuIconState("Autopilot",1)
  Else
    MenuIconState("Autopilot",0)
  EndIf
  
  If (g.ctrl<>0) _
  AndAlso (w.Train(g.ctrl)<>0) _
  AndAlso (w.Train(g.ctrl)->control And restart) Then
    MenuIconState("Autostart",1)
  Else
    MenuIconState("Autostart",0)
  EndIf
  
  If (g.ctrl<>0) _
  AndAlso (w.Train(g.ctrl)<>0) _
  AndAlso (w.Train(g.ctrl)->control And brake) Then
    MenuIconState("Stop Train",1)
  Else
    MenuIconState("Stop Train",0)
  EndIf
  
  If (g.ctrl<>0) _
  AndAlso (w.Train(g.ctrl)<>0) _
  AndAlso (wView1.cam=g.ctrl) Then
    MenuIconState("Watch Train",1)
  Else
    MenuIconState("Watch Train",0)
  EndIf
  
'  If (g.ctrl<>0) _
'  AndAlso (w.Train(g.ctrl)<>0) _
'  AndAlso ((w.Train(g.ctrl)->sp<0) _
'  OrElse (w.Train(g.ctrl)->sp>10*SpeedScale)) _
'  Then
'    MenuIconState("Ctrl Backward",2)
'  Else
'    MenuIconState("Ctrl Backward",0)
'  EndIf
'  
'  If (g.ctrl<>0) _
'  AndAlso (w.Train(g.ctrl)<>0) _
'  AndAlso ((w.Train(g.ctrl)->sp>0) _
'  OrElse (w.Train(g.ctrl)->sp<-10*SpeedScale)) _
'  Then
'    MenuIconState("Ctrl Forward",2)
'  Else
'    MenuIconState("Ctrl Forward",0)
'  EndIf
'  
  If (g.ctrl<>0) _
  AndAlso (w.Train(g.ctrl)<>0) _
  AndAlso (w.Train(g.ctrl)->control and brake) _
  Then
    MenuIconState("Stop Train",1)
  Else
    MenuIconState("Stop Train",0)
  EndIf
  
  If (g.ctrl<>0) _
  AndAlso (w.Train(g.ctrl)<>0) _
  AndAlso (Abs(w.Train(g.ctrl)->AutoSpeed)=SlowSpeed) _
  Then
    MenuIconState("Train Slow",1)
  Else
    MenuIconState("Train Slow",0)
  EndIf
  
  If (g.ctrl<>0) _
  AndAlso (w.Train(g.ctrl)<>0) _
  AndAlso (Abs(w.Train(g.ctrl)->AutoSpeed)=FastSpeed) _
  Then
    MenuIconState("Train Fast",1)
  Else
    MenuIconState("Train Fast",0)
  EndIf
  
  'Track Menu
  
  If (g.EditTrkPtr<>0) _
  AndAlso (g.EditTrkPtr->MyTrack->last->pf=0) _
  Then
    MenuIconState("Open Track",1)
  Else
    MenuIconState("Open Track",0)
  EndIf
  
  If (g.EditTrkPtr<>0) Then
    If (g.EditTrkPtr->visible) Then
      MenuIconState("Visible Track",0)
    Else
      MenuIconState("Visible Track",1)
    EndIf
  EndIf
  
  If (g.EditTrkPtr<>0) _
  AndAlso ("l"=left(g.EditTrkPtr->tname,1)) _
  Then
    MenuIconState("Turn Left",1)
  Else
    MenuIconState("Turn Left",0)
  EndIf
  
  If (g.EditTrkPtr<>0) _
  AndAlso ("r"=left(g.EditTrkPtr->tname,1)) _
  Then
    MenuIconState("Turn Right",1)
  Else
    MenuIconState("Turn Right",0)
  EndIf
  
  If (g.es=es_PlaceTrack) _
  Then
    MenuIconState("Place Track",1)
  Else
    MenuIconState("Place Track",0)
  EndIf
  
  
  'Build Menu
  
  If (g.es=es_PlaceItem) _
  Then
    MenuIconState("New Item/Train",1)
  Else
    MenuIconState("New Item/Train",0)
  EndIf
  
  
End Sub

'draw icon menu

Sub DrawMenu(mx As Integer, my As Integer, dwin As Any Ptr)
  Dim As Any Ptr img
  Dim As Integer lin,col
  Dim As Integer ox, oy     'offset
  Dim As Integer tx         'text x size / pixel
  
  If (Menu.MWidth>MBWidth) AndAlso (Menu.MHeight>MBHeight) _
  AndAlso (dwin<>NULL) Then
    UpdateMenu
    
    'create new bitmap for menu
    img = ImageCreate(Menu.MWidth, Menu.MHeight)
    If img<>NULL Then
    
      'clear bitmap
      Line img, (0,0) - Step(Menu.MWidth-1, Menu.MHeight-1), MenuBGCol, BF
      
      'check if mouse is over menu
      If MouseWindow=2 _
      AndAlso (mx>=Menu.PosX) AndAlso (mx<=(Menu.PosX+Menu.MWidth))_
      AndAlso (my>=Menu.PosY) AndAlso (my<=(Menu.PosY+Menu.MHeight)) Then
        Menu.MouseOver=-1
      Else
        Menu.MouseOver=0
      EndIf
      
      'draw menu icons and store icon position under mouse corsor
      Menu.MouseX=-1
      Menu.MouseY=-1
      For lin=0 To Menu.MBY
        oy=Menu.PosY+lin*MBHeight
        For col=0 To Menu.MBX
          ox=Menu.PosX+col*MBWidth
          
          'draw icon
          DrawMB(Menu.MB(lin,col).Icon, Menu.MB(lin,col).state,lin,col,img)
          
          'check if mouse cursor hovers over icon
          If Menu.MouseOver _
          AndAlso (mx>ox+5) AndAlso (mx<(ox+MBWidth-1)) _
          AndAlso (my>oy+5) AndAlso (my<(oy+MBHeight-1))_
          AndAlso (Menu.MB(lin,col).State<>2) Then
            Line img,(ox+5,oy+5) _
            - Step (MBWidth-9,MBHeight-9), _
            &H000000, B, &Haaaa            Menu.MouseX=col
            Menu.MouseY=lin
          EndIf
          
        Next col
      Next lin
      
      'print icon command
      If Menu.MouseOver _
      AndAlso Menu.cmd<>"" Then
      
        If Menu.cmdh<>Menu.cmd Then
          Menu.cmdh=Menu.cmd
          If Menu.cmdh="" Then
            Menu.cmdc=0
          Else
            Menu.cmdc=200
          EndIf
        Else
          If Menu.cmdc>0 Then
            Menu.cmdc-=1
'          Else
'            Menu.cmdh=""
          EndIf
          
          ox=mx+8
          oy=my-15
          tx=(InStr(Menu.cmd,chr(0))-1)*6
          If ox+tx>(158-4) Then
            ox=158-tx-4
          EndIf
          If oy<0 Then oy=15
          If Menu.cmdc>0 Then
            Line img, (ox-1,oy-1) - Step(tx+1,10), &Hf0f0f0, BF
            GfxPrint6 menu.cmd,ox,oy,&H3f3f3f,img
          EndIf
          
        EndIf
        
      EndIf

      
      'Put dwin, (Menu.PosX,Menu.PosY),img,PSet
      If Menu.MouseOver=0 Then
        Put dwin, (Menu.PosX,Menu.PosY),img, Alpha, Menu.Fade
      Else
        Put dwin, (Menu.PosX,Menu.PosY),img,PSet
        Menu.Fade=255
      EndIf
      ImageDestroy img
    EndIf
    If Menu.Fade>Menu.Alpha Then
      Menu.Fade-=1
    EndIf
  EndIf
End Sub


Sub MenuInit(x As Integer, y As Integer, w As Integer, h As Integer,_
  IconsX As Integer, IconsY As Integer, Alpha As Integer)
  Dim As Integer i, j
  
  If (IconsX<=MenuMaxX) AndAlso (IconsY<=MenuMaxY) Then
    Menu.MName=""
    Menu.PosX=x
    Menu.PosY=y
    Menu.MWidth=w
    Menu.MHeight=h
    Menu.MBX=IconsX
    Menu.MBY=IconsY
    Menu.Alpha=Alpha
    For i=0 To Menu.MBX
      For j=0 To Menu.MBY
        MenuSetIcon(i,j,0,2,1,"---")
      Next j
    Next i
  EndIf
End Sub


Sub MenuSwitch(n As String)
  Dim As Integer i, j
  
'  Menu.Fade=255
  Menu.MName=n
  For i=0 To MenuMaxX
    For j=0 To MenuMaxY
      MenuSetIcon(i,j,0,2,1,"---")
    Next j
  Next i
  
  If MenuName0=n Then
    tsmode=ts_run
    Menu.MHeight=158-31*4
    MenuSetIcon(0,0,29,0,0,MenuName1)
    MenuSetIcon(0,1,25,0,0,MenuName2)
    MenuSetIcon(0,2,45,0,0,MenuName3)
    MenuSetIcon(0,3,51,0,0,MenuName4)
    'MenuSetIcon(0,4,26,0,0,MenuName5)
  
  ElseIf MenuName1=n Then
    tsmode=ts_control
    Menu.MHeight=158-31*1
    MenuSetIcon(0,0,29,1,0,MenuName0)
    MenuSetIcon(0,1,25,0,0,MenuName2)
    MenuSetIcon(0,2,45,0,0,MenuName3)
    MenuSetIcon(0,3,51,0,0,MenuName4)
    'MenuSetIcon(0,4,26,0,0,MenuName5)

    MenuSetIcon(1,0,18,0,1,"Ctrl Select +")
    MenuSetIcon(1,1,33,0,1,"Ctrl Speed +")
    MenuSetIcon(1,2,64,0,1,"Ctrl Turn F")
    MenuSetIcon(1,3,53,0,1,"Watch Train")
    
    MenuSetIcon(2,0,17,0,1,"Ctrl Select -")
    MenuSetIcon(2,1,32,0,1,"Ctrl Speed -")
    MenuSetIcon(2,2,65,0,1,"Ctrl Turn R")
    MenuSetIcon(2,3,80,0,1,"Center Track")
    
    MenuSetIcon(3,0,37,0,1,"Stop Train")
    MenuSetIcon(3,1,62,0,1,"Train Slow")
    MenuSetIcon(3,2,63,0,1,"Train Fast")
    MenuSetIcon(3,3,36,0,1,"Autopilot")
    MenuSetIcon(3,4,58,0,1,"Autostart")
  
  ElseIf MenuName2=n Then
    tsmode=ts_files
    Menu.MHeight=158-31*2
    MenuSetIcon(0,0,29,0,0,MenuName1)
    MenuSetIcon(0,1,25,1,0,MenuName0)
    MenuSetIcon(0,2,45,0,0,MenuName3)
    MenuSetIcon(0,3,51,0,0,MenuName4)
    'MenuSetIcon(0,4,26,0,0,MenuName5)

    MenuSetIcon(1,0,60,0,1,"Load")
    MenuSetIcon(1,1,60,0,1,"Import Track")
    MenuSetIcon(1,2,38,0,1,"New World")
    MenuSetIcon(1,3,26,0,1,"F8 Setup")
    
    MenuSetIcon(2,0,61,0,1,"Save")
    MenuSetIcon(2,1,61,0,1,"Export Track")
    MenuSetIcon(2,2,31,0,1,"F4 Messages")
   
    
    
  ElseIf MenuName3=n Then
    tsmode=ts_edittrack
    Menu.MHeight=158-31*0
    MenuSetIcon(0,0,29,0,0,MenuName1)
    MenuSetIcon(0,1,25,0,0,MenuName2)
    MenuSetIcon(0,2,45,1,0,MenuName0)
    MenuSetIcon(0,3,51,0,0,MenuName4)
    'MenuSetIcon(0,4,26,0,0,MenuName5)
    
    MenuSetIcon(1,0,18,0,1,"Select Track")
    MenuSetIcon(1,1,45,0,1,"Open Track")
    MenuSetIcon(1,2,23,0,1,"Place Track")
    MenuSetIcon(1,3,79,0,1,"Track Name")
    MenuSetIcon(1,4,38,0,1,"Remove Track")
    
    MenuSetIcon(2,0,19,0,1,"Rotate Left")
    MenuSetIcon(2,1,39,0,1,"Turn Left")
    MenuSetIcon(2,2,41,0,1,"Track Cursor +")
    MenuSetIcon(2,3,49,0,1,"Track Longer")
    MenuSetIcon(2,4,47,0,1,"Signal Fwd")
    
    MenuSetIcon(3,0,20,0,1,"Rotate Right")
    MenuSetIcon(3,1,40,0,1,"Turn Right")
    MenuSetIcon(3,2,42,0,1,"Track Cursor -")
    MenuSetIcon(3,3,50,0,1,"Track Shorter")
    MenuSetIcon(3,4,48,0,1,"Signal Rev")
    
    MenuSetIcon(4,0,44,0,1,"Rail Insert")
    MenuSetIcon(4,1,43,0,1,"Rail Remove")
    MenuSetIcon(4,2,81,0,1,"Build Turnout")
    MenuSetIcon(4,3,52,0,1,"Visible Track")
    
    
'    MenuSetIcon(1,0,23,0,1,"Place Track")
'    MenuSetIcon(1,1,79,0,1,"Track Name")
'    MenuSetIcon(1,2,38,0,1,"Remove Track")
'    MenuSetIcon(1,3,19,0,1,"Rotate Left")
'    MenuSetIcon(1,4,20,0,1,"Rotate Right")
'    
'    MenuSetIcon(2,0,18,0,1,"Select Track")
'    MenuSetIcon(2,1,45,0,1,"Open Track")
'    MenuSetIcon(2,2,81,0,1,"Build Turnout")
'    MenuSetIcon(2,3,47,0,1,"Signal Fwd")
'    MenuSetIcon(2,4,48,0,1,"Signal Rev")
'    
'    MenuSetIcon(3,0,42,0,1,"Track Cursor -")
'    MenuSetIcon(3,1,41,0,1,"Track Cursor +")
'    MenuSetIcon(3,2,39,0,1,"Turn Left")
'    MenuSetIcon(3,3,40,0,1,"Turn Right")
'    
'    MenuSetIcon(4,0,43,0,1,"Rail Remove")
'    MenuSetIcon(4,1,44,0,1,"Rail Insert")
'    MenuSetIcon(4,2,50,0,1,"Track Shorter")
'    MenuSetIcon(4,3,49,0,1,"Track Longer")
'    MenuSetIcon(4,4,52,0,1,"Visible Track")
    
  ElseIf MenuName4=n Then
    tsmode=ts_build
    Menu.MHeight=158-31*2
    MenuSetIcon(0,0,29,0,0,MenuName1)
    MenuSetIcon(0,1,25,0,0,MenuName2)
    MenuSetIcon(0,2,45,0,0,MenuName3)
    MenuSetIcon(0,3,51,1,0,MenuName0)
    'MenuSetIcon(0,4,26,0,0,MenuName5)

'    MenuSetIcon(1,0,23,0,1,"Place Item")
    MenuSetIcon(1,0,23,0,1,"New Item/Train")
    MenuSetIcon(1,1,54,0,1,"Model +")
    MenuSetIcon(1,2,56,0,1,"Car Model +")
    MenuSetIcon(1,3,79,0,1,"Train Name")
    
    MenuSetIcon(2,0,38,0,1,"Delete")
    MenuSetIcon(2,1,55,0,1,"Model -")
    MenuSetIcon(2,2,57,0,1,"Car Model -")
    
    
'  ElseIf MenuName5=n Then
'    tsmode=ts_edittrack
'    Menu.MHeight=158-31*4
'    MenuSetIcon(0,0,29,0,0,MenuName1)
'    MenuSetIcon(0,1,25,0,0,MenuName2)
'    MenuSetIcon(0,2,45,0,0,MenuName3)
'    MenuSetIcon(0,3,51,0,0,MenuName4)
'    'MenuSetIcon(0,4,26,1,0,MenuName0)
'    
''    MenuSetIcon(1,0,18,0,1,"Select Track +")
''    MenuSetIcon(1,1,47,0,1,"Signal Fwd")
''    MenuSetIcon(1,2,45,0,1,"Open Track")
''    MenuSetIcon(1,3,18,0,1,"Select Track")
''    
''    MenuSetIcon(2,0,17,0,1,"Select Track -")
''    MenuSetIcon(2,1,48,0,1,"Signal Rev")
''    MenuSetIcon(2,2,46,0,1,"Close Track")
'    
''    MenuSetIcon(1,2,61,0,1,"Export Track")
''    MenuSetIcon(2,2,12,0,1,"New Train")
    
  EndIf
End Sub


'menu control by mouse

Sub MenuCall
  If Menu.MouseOver Then
    If (g.Mousebt=0) AndAlso (g.Mousebts=1) _
    AndAlso (Menu.MouseX>=0) AndAlso (Menu.MouseY>=0) _
    Then
      If (Menu.MB(Menu.MouseY,Menu.MouseX).locked=0) Then
        If Menu.MB(Menu.MouseY,Menu.MouseX).State=0 Then
          Menu.MB(Menu.MouseY,Menu.MouseX).State=1
        ElseIf Menu.MB(Menu.MouseY,Menu.MouseX).State=1 Then
          Menu.MB(Menu.MouseY,Menu.MouseX).State=0
        EndIf
      EndIf
    EndIf

    If (Menu.MouseX>=0) AndAlso (Menu.MouseY>=0) Then
      Menu.cmd=Menu.MB(Menu.MouseY,Menu.MouseX).cmd
      Menu.CmdState=Menu.MB(Menu.MouseY,Menu.MouseX).State
    Else
      Menu.cmd=""
      Menu.CmdState=0
    EndIf  EndIf
End Sub


Sub MenuByMouse
  'switch menu by mouse
  
  '################################################
  '## (1) switch Menu
  '################################################
    
  'menu control by mouse
  If Menu.MouseOver Then
    If (g.Mousebt=0) AndAlso (g.Mousebts=1) Then
      
      'Menu switch - home
      If (Menu.Cmd=MenuName0) Then
        MenuSwitch(Menu.Cmd)
      EndIf
      
      
      'Menu switch - train control
      If (Menu.Cmd=MenuName1) Then
        MenuSwitch(Menu.Cmd)
        
        If tsmode=ts_edittrack Then
          ts_te_TrackEnd
        EndIf
        
        'unselect all
        g.es=es_Off
'        g.Ctrl=0
'        v.Cam=0
        g.EditTrk=0
        g.TrkSel=0
        g.ItemSel=0
        g.EditTrkBasePtr=0
        g.EditTrkPtr=0
        g.EditTrkPtrA=0
      EndIf
      
      
      'Menu Files
      If (Menu.Cmd=MenuName2) Then
        g.es=es_Off
        MenuSwitch(Menu.Cmd)
      EndIf
      
      
      'Menu switch - edit track
      If (Menu.Cmd=MenuName3) Then
        MenuSwitch(Menu.Cmd)
        
        'disable other selections
        g.Ctrl=0
        wv.Cam=0
        g.ItemSel=0
      EndIf
      
      
      'Menu switch - build
      If (Menu.Cmd=MenuName4) Then
        MenuSwitch(Menu.Cmd)
        'unselect all
'        g.es=es_Off
'        g.Ctrl=0
'        v.Cam=0
        g.EditTrk=0
'        g.TrkSel=0         'need to place a new train
'        g.ItemSel=0
        g.EditTrkBasePtr=0
'        g.EditTrkPtr=0     'need to place a new train
        g.EditTrkPtrA=0
      EndIf
      
      
      
      
      
  '################################################
  '## (2) send Menu commands to train simulator
  '################################################
      
      
      'send command names
      
      'context menu - control
      If Menu.MName=MenuName1 Then
        ks=Menu.Cmd
      EndIf
      
      
      'context menu - files
      If Menu.MName=MenuName2 Then
        ks=Menu.Cmd
      EndIf
      
      
      'context menu - track
      If Menu.MName=MenuName3 Then
        ks=Menu.Cmd
      EndIf
      
      
      'context menu - build
      If Menu.MName=MenuName4 Then
        ks=Menu.Cmd
      EndIf
      
    EndIf
  EndIf
End Sub


'################################################
'## Functions / Subs (Graphics)
'################################################


Function visible(x As Integer,y As Integer) As Integer
  If (xcoor(x)>=(0-wv.VisBorderX)) And (xcoor(x)<(v.WinX+wv.VisBorderX)) _
  And (ycoor(y)>=(0-wv.VisBorderY)) And (ycoor(y)<(v.WinY+wv.VisBorderY)) Then
    Return 1
  Else
    Return 0
  EndIf
End Function


Function overlap(a1 As Integer,b1 As Integer,a2 As Integer,b2 As Integer) As Integer
  Dim As Integer ol
  ol=0
  'check if length(a1,b1) > length(a2,b2)
  If (b1-a1)>=(b2-a2) Then
    If (a2>a1) And (a2<b1) _
    Or (b2>a1) And (b2<b1) Then ol=1
  Else
    If (a1>a2) And (a1<b2) _
    Or (b1>a2) And (b1<b2) Then ol=1
  EndIf
  Return ol
End Function


Function visrect(x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer) As Integer
  If overlap(p2wx(0), p2wx(v.WinX), x1, x2) _
  And overlap(p2wy(0), p2wy(v.WinY), y1, y2) Then
    Return 1
  Else
    Return 0
  EndIf
End Function


Function SCX As Integer
  'Screen Center GetX
  Return p2wx(v.WinX/2)
End Function


Function SCY As Integer
  'Screen Center GetX
  Return p2wy(v.WinY/2)
End Function


Sub drawgrid(gx1 As Integer, gy1 As Integer, gx2 As Integer, gy2 As Integer, dots As Integer,dwin As Any Ptr)
  Dim As Integer x, y, x1, y1, x2, y2
  
  If v.Scale<=100 Then
    For x=0 To v.WinX
      If (p2wx(x) Mod m)<(v.Scale) Then
        For y=0 To v.WinY
          If (p2wy(y) Mod m)<(v.Scale) Then
            PSet dwin,(x,y),&H00FFFF
          EndIf
        Next
      EndIf
    Next
  EndIf
  
  If (v.Scale<1000) Then
    For x=0 To v.WinX
      If (p2wx(x) Mod (m*10))<(v.Scale) Then
        For y=0 To v.WinY
          If (p2wy(y) Mod (m*10))<(v.Scale) Then
            PSet dwin,(x,y),&H8080FF
            If v.Scale<250 Then
              Line dwin,(x-1,y-1)-(x+1,y+1),&H80c0FF,B
            EndIf
          EndIf
        Next
      EndIf
    Next
  EndIf
  
  If (v.Scale<10000) Then
    For x=0 To v.WinX
      If (p2wx(x) Mod (m*100))<(v.Scale) Then
        For y=0 To v.WinY
          If (p2wy(y) Mod (m*100))<(v.Scale) Then
            PSet dwin,(x,y),&Hffff80
          EndIf
        Next
      EndIf
    Next
  EndIf
  
  If (v.Scale<100000) Then
    For x=0 To v.WinX
      If (p2wx(x) Mod (m*1000))<(v.Scale) Then
        For y=0 To v.WinY
          If (p2wy(y) Mod (m*1000))<(v.Scale) Then
            Line dwin,(x-1,y-1)-(x+1,y+1),&H808080,BF
          EndIf
        Next
      EndIf
    Next
  EndIf
  
  If (v.Scale<1000000) Then
    For x=0 To v.WinX
      If (p2wx(x) Mod (m*10000))<(v.Scale) Then
        For y=0 To v.WinY
          If (p2wy(y) Mod (m*10000))<(v.Scale) Then
            Line dwin,(x-1,y-1)-(x+1,y+1),&HFFFF80,BF
          EndIf
        Next
      EndIf
    Next
  EndIf
  
End Sub


Sub DrawSubTrackHighlighted(T As PTrack, col As Integer,dwin As Any ptr)
  If T->pf<>0 Then
    Line dwin,(xcoor(T->x),ycoor(T->y))-(xcoor(T->pf->x),ycoor(T->pf->y)), col
  EndIf
  Circle dwin,(xcoor(T->x),ycoor(T->y)),3,&H00ff00,,,,F
End Sub


Sub DrawSubTrack(T As PTrack, col As Integer,dwin As Any ptr)
  If T->pf<>0 Then
    Line dwin,(xcoor(T->x),ycoor(T->y))-(xcoor(T->pf->x),ycoor(T->pf->y)), col
  EndIf
End Sub


Sub DrawItemLine(x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer, _
  length As Integer, model As Integer, dwin As Any Ptr)
  Dim As Integer i, i1, j, j1
  Dim As Integer nx1, ny1, nx2, ny2
  Dim As Integer px1, py1, px2, py2
  
      j1=(length/2500)
      j=j1-1
      If j=0 Then
        If visible(x1,y1) OrElse visible(x2,y2) Then
          DrawModel(x1, y1, x2, y2, w.model(model)->mBuild, v, 1, 1, dwin)
        EndIf
      Else
        nx1=x1/10
        ny1=y1/10
        nx2=x2/10
        ny2=y2/10
        For i=0 To j
          i1=i+1
          px1=(nx1+i*(nx2-nx1)/(j1))*10
          py1=(ny1+i*(ny2-ny1)/(j1))*10
          px2=(nx1+i1*(nx2-nx1)/(j1))*10
          py2=(ny1+i1*(ny2-ny1)/(j1))*10
          If visible(px1,py1) OrElse visible(px2,py2) Then
            DrawModel(px1, py1, px2, py2, w.model(model)->mBuild, v, 1, 1, dwin)
          EndIf
        Next i
      EndIf
End Sub


Sub DrawTrackFloor(Track As PTrackBase, selected As Integer, dwin As Any ptr)
  Dim As PTrack T
  Dim As Integer col, i, j, i1, j1
  Dim As Integer nx1, ny1, nx2, ny2
  Dim As Integer px1, py1, px2, py2
  Dim As Integer x1,y1,x2,y2,a, a1, a2
  
  
  'Draw track floor
  If (m/v.Scale)>0.5 Then
    'show more details when zoomed in
    T=Track->start
    Do
    
  #ifdef TurnoutNew
        
        'Draw simple turnout without crossing
        If T->turn=0 _
        OrElse ((T->pn<>NULL) _
        AndAlso (T->pn<>NULL)) _
        Then
          If T->pn>0 Then
            If T->visible Then
              DrawItemLine(T->x, T->y, T->pn->x, T->pn->y, _
              T->lengthn, ModelIndex("Short Rail"), dwin)
            EndIf
          ElseIf T->pf>0 Then
            If T->visible Then
              DrawItemLine(T->x, T->y, T->pf->x, T->pf->y, _
              T->length, ModelIndex("Short Rail"), dwin)
            EndIf
          EndIf
        EndIf        
  #else
        
        'Draw simple turnout with crossing
        If T->pf>0 Then
          If T->visible Then
              DrawItemLine(T->x, T->y, T->pf->x, T->pf->y, _
              T->lengthn, ModelIndex("Short Rail"), dwin)
          ElseIf T->pf>0 Then
            If T->visible Then
              DrawItemLine(T->x, T->y, T->pf->x, T->pf->y, _
              T->length, ModelIndex("Short Rail"), dwin)
            EndIf
          EndIf
        EndIf
        
  #endif
        
        T=T->pn
        
    Loop Until T=0
  EndIf
  
End Sub




Sub DrawTrack(Track As PTrackBase, selected As Integer, dwin As Any ptr)
  Dim As PTrack T
  Dim As Integer col, i, j, i1, j1
  Dim As Integer nx1, ny1, nx2, ny2
  Dim As Integer px1, py1, px2, py2
  Dim As Integer x1,y1,x2,y2,a, a1, a2
  
  
  'Draw track base
  If (tsmode=ts_edittrack) OrElse v.Debug Then
    If selected Then
      Circle dwin,(xcoor(Track->x),ycoor(Track->y)),3+3*m/v.Scale,&H5050ff,,,,F
    Else
      Circle dwin,(xcoor(Track->x),ycoor(Track->y)),3+3*m/v.Scale,&H505060,,,,F
    EndIf
    Circle dwin,(xcoor(Track->x),ycoor(Track->y)),3+3*m/v.Scale,&H707090
  EndIf
  
  
  
  'Draw track
  If (m/v.Scale)>0.5 Then
    'show more details when zoomed in
    T=Track->start
    Do
    
      'draw left/right rails
      'choose color
      col=&H606080
      
      If (tsmode=ts_edittrack) OrElse v.Debug Then
'        If T->tname="s" Then col=&H60c0ff   'Highlight Track "s" = Station
        If T->turn<>0 Then   col=&H8080ff   'Highlight Turnout
        If selected Then col=col+&H2f3f00
        If T->SigF<>"" Then col=&H60c0ff    'Highlight Track with Signal
        If T->SigR<>"" Then col=&H60c0ff    'Highlight Track with Signal
      EndIf
      
      'Highlight Locked Track with red color
      If v.Debug Then
        If T->LockedBy<>NULL Then col=col+&H600000    'debug view
      EndIf

  #ifdef TurnoutNew
        
        'Draw simple turnout without crossing
        If T->turn=0 _
        OrElse ((T->pf<>NULL) AndAlso (T->pf->pf<>NULL)_
        AndAlso (T->pr<>NULL) AndAlso (T->pr->pr<>NULL)) _
        Then
          If T->pf>0 Then
            x1=T->x
            y1=T->y
            x2=T->pf->x
            y2=T->pf->y
            
            If T->visible Then
              Line dwin,(xcoor(x1+T->Sin0), ycoor(y1-T->Cos0)) _
                 -(xcoor(x2+T->pf->Sin0), ycoor(y2-T->pf->Cos0)),col
              Line dwin,(xcoor(x1-T->Sin0), ycoor(y1+T->Cos0)) _
                 -(xcoor(x2-T->pf->Sin0), ycoor(y2+T->pf->Cos0)),col
            EndIf
          EndIf
        EndIf
        
  #else
        
        'Draw simple turnout with crossing
        If T->pf>0 Then
          x1=T->x
          y1=T->y
          x2=T->pf->x
          y2=T->pf->y
          
          If T->visible Then
            Line dwin,(xcoor(x1+T->Sin0), ycoor(y1-T->Cos0)) _
               -(xcoor(x2+T->pf->Sin0), ycoor(y2-T->pf->Cos0)),col
            Line dwin,(xcoor(x1-T->Sin0), ycoor(y1+T->Cos0)) _
               -(xcoor(x2-T->pf->Sin0), ycoor(y2+T->pf->Cos0)),col
          EndIf
        EndIf
        
  #endif
        
        T=T->pn
        
    Loop Until T=0
  Else
    'show less details when zoomed out
    T=Track->start
    Do
      'choose color
      col=&H606080
      
      If (tsmode=ts_edittrack) OrElse v.Debug Then
'        If T->tname="s" Then col=&H60c0ff   'Highlight Track "s" = Station
        If T->turn<>0 Then   col=&H8080ff   'Highlight Turnout
        If selected Then col=col+&H2f3f00
        If T->SigF<>"" Then col=&H60c0ff    'Highlight Track with Signal
        If T->SigR<>"" Then col=&H60c0ff    'Highlight Track with Signal
      EndIf
      
      If T->pf<>0 Then
        If T->visible Then
        Line dwin,(xcoor(T->x), ycoor(T->y))-(xcoor(T->pf->x), ycoor(T->pf->y)), col
        EndIf
      EndIf
      T=T->pn
    Loop Until T=0
  EndIf
  
  'Circles between track segments
  If (tsmode=ts_edittrack) OrElse v.Debug Then
    If (m/v.Scale)>1 Then
      'show more details when zoomed in
      T=Track->start
      Do
        Circle dwin,(xcoor(T->x),ycoor(T->y)),0.5*m/v.Scale,&H00ff00
        T=T->pn
      Loop Until T=0
    EndIf
  EndIf
End Sub


Sub ShowItem(P As PItem, dwin As Any Ptr)
  DrawModel(P->a.x,P->a.y,P->b.x,P->b.y,w.model(P->build)->mBuild,v,P->col,0,dwin)
End Sub


'################################################
'## Little helper
'################################################


'get index number of track by name
Function NumOfTrack(s As String) As Integer
  Dim As Integer i, r
  
  r=0     'default error code
  For i=1 To MaxTracks
    If w.Start(i)<>NULL AndAlso w.Start(i)->TName=s Then
      r=i
      Exit For
    EndIf
  Next i
  NumOfTrack=r
End Function


'get model index number by name
Function NumOfModel(s As String) As Integer
  Dim As Integer i, r

  r=0
  For i=1 To MaxModels
    If w.Model(i)<>NULL Then
      If w.Model(i)->MName=s Then
        r=i
        Exit For
      EndIf
    EndIf
  Next i
  NumOfModel=r
End Function


Function fstr(num As Single, LDigits As Integer, RDigits As Integer) As String
  Dim As String s
  Dim As Integer i
  Dim As Single n
  If num>(10^(LDigits)) Then
    s="#OE#"
  ElseIf -num>(10^(LDigits-1)) Then
    s="#OE#"
  Else
    s=Right(String(LDigits,"0")+Str(Int(Abs(num))),LDigits)+"."
    If RDigits>0 Then
      n=num-Int(num)
      For i=1 To RDigits
        n=n*10
        s=s+Chr(Asc("0")+n Mod 10)
      Next
    EndIf
    If num<0 Then s[0]=Asc("-")
  EndIf
  Function=s
End Function


Sub DrawTextBottom(dwin As Any Ptr, msg As String, _
        wleft As Integer, wright As Integer, _
        bgtype As Integer, bgcolor As Integer)
  
  Dim As Integer y, l, i, p, txlen
  Dim As String ms
  
  ms=msg
  'count and return l=lines
  l=0
  For i=1 To Len(ms)
    If mid(ms,i,1)="|" Then
      l+=1
    EndIf
  Next i
  
  txlen=(wright-wleft)/6
  If bgtype=1 Then
    Line dwin, (wleft, v.WinY-(l)*10-4)-(wright, v.WinY), bgcolor, BF
  EndIf
  
  p=InStr(ms,"|")
  For i=0 To l-1
    GfxPrint6 left(left(ms, p-1),txlen), wleft+1, v.WinY-l*10-2+i*10, CTextColor, dwin
    ms=right(ms,Len(ms)-p)
    p=InStr(ms,"|")
  Next i
End Sub


Sub DrawTextBottomL(dwin As Any Ptr, msg As String, _
        bgtype As Integer, bgcolor As Integer)
  DrawTextBottom(dwin,msg,0,0+26*6,bgtype,bgcolor)
End Sub


Sub DrawTextBottomC(dwin As Any Ptr, msg As String, _
        bgtype As Integer, bgcolor As Integer)
  DrawTextBottom(dwin,msg,MainViewW/2-13*6,MainViewW/2+13*6,bgtype,bgcolor)
End Sub


Sub DrawTextBottomR(dwin As Any Ptr, msg As String, _
        bgtype As Integer, bgcolor As Integer)
  DrawTextBottom(dwin,msg,MainViewW-26*6,MainViewW,bgtype,bgcolor)
End Sub




Function InputBox(title As String, t As String) As String
  Const IBoxX=200
  Const IBoxY=50
  Dim As Any Ptr img = ImageCreate(IBoxX, IBoxY, CMsgBoxColor)
  Dim As String k, s
  
  s=t
  Do
    k=InKey$
    If k>=" " Then
      s=s+k
    ElseIf k=chr(8) Then
      s=left(s, Len(s)-1)
    EndIf
    Line img,(2,2)-(IBoxX-3,IBoxY-3),CTextColor,B
    GfxPrint6 title, 20, 10, CTextColor, img
    GfxPrint6 s+chr(254), 20, 30, CTextColor, img
    Put ((MainViewW-IBoxX)/2, (MainViewH-IBoxY)/2), img, PSet
    Sleep 10
    Line img,(0,0)-(IBoxX-1,IBoxY-1),CMsgBoxColor,BF
  Loop Until (k=chr(10)) OrElse (k=chr(13)) OrElse (k=K_Esc)
  
  If k=K_Esc Then s=t   'change nothing
  
  InputBox=s
End Function


Function YesOrNoBox(title As String) As String
  Const IBoxX=240
  Const IBoxY=50
  Dim As Any Ptr img = ImageCreate(IBoxX, IBoxY, CMsgBoxColor)
  Dim As String k
  
  Line img,(2,2)-(IBoxX-3,IBoxY-3),CTextColor,B
  'print to center
  GfxPrint6 title, (IBoxX-Len(title)*6)/2, 10, CTextColor, img
  GfxPrint6 "Press y or n (yes/no)", (IBoxX-21*6)/2, 30, CTextColor, img
  Put ((MainViewW-IBoxX)/2, (MainViewH-IBoxY)/2), img, PSet
  Do
    Sleep 50
    k=lcase(InKey$)
  Loop Until (k="y") OrElse (k="n") OrElse (k=chr(27))
  YesOrNoBox=k
End Function


Sub MessageBox(title As String)
  Const IBoxX=320
  Const IBoxY=50
  Dim As Any Ptr img = ImageCreate(IBoxX, IBoxY, CMsgBoxColor)
  Dim As String k
  
  LogFile("Box-MSG: "+title)
  Line img,(2,2)-(IBoxX-3,IBoxY-3),CTextColor,B
  'print to center
  GfxPrint6 title, (IBoxX-Len(title)*6)/2, 10, CTextColor, img
  GfxPrint6 "Press a key.", (IBoxX-12*6)/2, 30, CTextColor, img
  Put ((MainViewW-IBoxX)/2, (MainViewH-IBoxY)/2), img, PSet
  Do
    Sleep 50
    k=lcase(InKey$)
  Loop Until k<>""
End Sub


Sub InfoBox(title As String)
  Const IBoxX=320
  Const IBoxY=50
  Dim As Any Ptr img = ImageCreate(IBoxX, IBoxY, CMsgBoxColor)
  Dim As String k
  
  LogFile("Info-MSG: "+title)
  Line img,(2,2)-(IBoxX-3,IBoxY-3),CTextColor,B
  'print to center
  GfxPrint6 title, (IBoxX-Len(title)*6)/2, 20, CTextColor, img
  Put ((MainViewW-IBoxX)/2, (MainViewH-IBoxY)/2), img, PSet
End Sub


Sub TextBox(title As String, p As Any Ptr)
'  Dim As String k
  Const b=8
  Dim As Integer x,y,bx,by
  
'  LogFile("TextBox-MSG: "+title)
  bx=Len(title)*8/2
  by=16/2
  x=(MainViewW-by)/2
  y=(MainViewH-by)/2-80
  
  'print to center
  Line p, (x-bx-4-b,y-by-6-b) - (x+bx+4+b,y+by+4+b), CMsgBoxColor, BF
  Line p, (x-bx-2-b,y-by-4-b) - (x+bx+2+b,y+by+2+b), CTextColor, B
  GfxPrint title,x-bx,y-by,CTextColor,p
End Sub


'################################################
'## Show Messages
'################################################


Sub ShowMessages
  'Dim As String s
  Dim As Integer p, c, i 'w,h,center
  
'  For i=1 To 3
'    Message ("Generate Message "+str(i))
'  Next
  
  Color CTextColor, CGroundColor
  Cls
  
'    center = ((Width And &HFFFF)-26)/2
'    
'    Line ((center-4)*8,8*8) - step(35*8, 40*8), CMsgBoxColor, BF
'    Line ((center-4)*8,8*8) - step(35*8, 40*8), CTextColor, B
'    Color CTextColor, CMsgBoxColor

    
  p=MsgPtr
  If p=0 Then 
    Locate 12
    Print Spc(((Width And &HFFFF)-20)/2);"Message Bufer Is Empty."
    Do: Sleep 10: Loop Until inkey=K_Esc
  Else
    Do
      Cls
      Locate 12
      Print Spc(4);"******************************* Messages ********************************"
      Print
      
      i=p
      c=10
      Do 
        i-=1
        c-=1
        Print
        Print Spc(4);right("   "+str(i),4);": ";MessageLog(i)
      Loop Until (i=0) OrElse (c=0)
      Do
        Sleep 10
        ks=inkey
      Loop Until ks<>""
      Select Case ks
      Case K_CursDn:
        If p>10 Then p-=1
      Case K_CursRt:
        p-=10
        If p<1 Then p=1
      Case K_CursUp:
        p+=1
        If p>MsgPtr Then p=MsgPtr
      Case K_CursLt:
        p+=10
        If p>MsgPtr Then p=MsgPtr
      End Select
    Loop Until ks=K_Esc
  EndIf
  ks=""
End Sub


'################################################
'## Setup
'################################################


Sub SetupScreen
  Dim As String s
  Dim As Integer w,h,center
  
  Do
    Color CTextColor, CGroundColor
    Cls
    
    center = ((Width And &HFFFF)-26)/2
    
    Line ((center-4)*8,8*8) - step(35*8, 40*8), CMsgBoxColor, BF
    Line ((center-4)*8,8*8) - step(35*8, 40*8), CTextColor, B
    Color CTextColor, CMsgBoxColor

    Locate 12
    Print Spc(center);"****** Screen Setup *******"
    Print
    Print Spc(center);"Actual Size: "+str(ScreenW)+"x"+str(ScreenH)
    Print
    Print
    Print Spc(center);"(1) 640x480"
    Print
    Print Spc(center);"(2) 800x600"
    Print
    Print Spc(center);"(3) 1024x768"
    Print
    Print Spc(center);"(4) WxH Input"
    Print
    Print
    Print Spc(center);"(5) FPS Rate Limit="+str(fpsLimit)
    Print
    Print Spc(center);"(6) FPS Check ....=";
    If (fpsCheck) Then
      Print "ON"
    Else
      Print "OFF"
    EndIf
    Print
    Print Spc(center);"(7) BMP Time Limit="+str(MapPerformance)
    
    Locate 44
    Print Spc(center);"(ESC) Back"
    Print
    Do
      Sleep 10
      ks=inkey
    Loop Until ks<>""
    
    Select Case ks
    Case "1":
      ScreenInit(640,480)
      ViewInit
    Case "2":
      ScreenInit(800,600)
      ViewInit
    Case "3":
      ScreenInit(1024,768)
      ViewInit
    Case "4":
      s=InputBox("Screen width",str(ScreenW))
      w=Val(s)
      s=InputBox("Screen height",str(ScreenH))
      h=Val(s)
      ScreenInit(w,h)
      ViewInit
    Case "5":
      fpsLimit=Val(InputBox("FPS Rate Limit",str(fpsLimit)))
    Case "6":
      fpsCheck=fpsCheck=0
    Case "7":
      MapPerformance=Val(InputBox("BMP Time Limit",str(MapPerformance)))
    End Select
  Loop Until ks=K_Esc
  ks=""
End Sub

Sub SetupMouse
  Dim As String s
  Dim As Integer w,h,center

  Do
    Color CTextColor, CGroundColor
    Cls
    center = ((Width And &HFFFF)-26)/2
    
    Line ((center-4)*8,8*8) - step(35*8, 40*8), CMsgBoxColor, BF
    Line ((center-4)*8,8*8) - step(35*8, 40*8), CTextColor, B
    Color CTextColor, CMsgBoxColor
    
    Locate 12
    Print Spc(center);"** Mouse/Display Setup ***"
    Print
    Print
    Print Spc(center);"(1) Drag Accelerator="+str(EndlessDrag)
    Print
    Print Spc(center);"(2) Drag Sensitivity="+str(MouseAcclevel)
    Print
    Print
    Print
    Print
    Print Spc(center);"****** Display Setup *******"
    Print
    Print
    Print Spc(center);"(3) Menu Fade down to="+str(Menu.Alpha)
    Print
    Print Spc(center);"(4) Camera Slides ...="+str(wv.CamSteps)
    Print
    Print Spc(center);"(5) Draw Railway ....=";
    If (railway) Then
      Print "ON"
    Else
      Print "OFF"
    EndIf
    Print
    Print Spc(center);"(6) Show Train Stops ="+str(ShowTrainStops)
    Print
    Print Spc(center);"(7) Show Deliveries  =";
    If (ShowTrainDeliver) Then
      Print "ON"
    Else
      Print "OFF"
    EndIf
    Print
    Print Spc(center);"(8) Show Money ......=";
    If (ShowMoney) Then
      Print "ON"
    Else
      Print "OFF"
    EndIf
    
    Locate 44
    Print Spc(center);"(ESC) Back"
    Print
    Do
      Sleep 10
      ks=inkey
    Loop Until ks<>""
    
    Select Case ks
    Case "1":
      EndlessDrag=Val(InputBox("Drag Accelerator (0=OFF)",str(EndlessDrag)))
    Case "2":
      MouseAcclevel=Val(InputBox("Drag Sensitivity",str(MouseAcclevel)))
    Case "3":
      Menu.Alpha=Val(InputBox(" Menu Fade Value (255=solid)",str(Menu.Alpha)))
    Case "4":
      wv.CamSteps=Val(InputBox("Camera Slides",str(wv.CamSteps)))
    Case "5":
      railway=railway=0
    Case "6":
      ShowTrainStops=Val(InputBox("Show # Of Train Stops",str(ShowTrainStops)))
    Case "7":
      ShowTrainDeliver=ShowTrainDeliver=0
    Case "8":
      ShowMoney=ShowMoney=0
    End Select
  Loop Until ks=K_Esc
  ks=""
End Sub

Sub Setup
  Dim As String s
  Dim As Integer w,h,center
  
  Do
    Color CTextColor, CGroundColor
    Cls
    center = ((Width And &HFFFF)-26)/2
    
    Line ((center-4)*8,8*8) - step(35*8, 40*8), CMsgBoxColor, BF
    Line ((center-4)*8,8*8) - step(35*8, 40*8), CTextColor, B
    Color CTextColor, CMsgBoxColor

    Locate 12
    Print Spc(center);"********** Setup **********"
    Print
    Print
    Print Spc(center);"(1) Screen      ("+str(ScreenW)+"x"+str(ScreenH)+")"
    Print
    Print Spc(center);"(2) Mouse / Display"
    Print
    Print Spc(center);""
    
    Locate 44
    Print Spc(center);"(ESC) Exit"
    Print
    Do
      Sleep 10
      ks=inkey
    Loop Until ks<>""
    
    Select Case ks
    Case "1":
      SetupScreen
    Case "2":
      SetupMouse
    Case "3":
      '
    End Select
  Loop Until ks=K_ESC
  ks=""
End Sub

'################################################
'## Functions / Subs (Simulation)
'################################################


Sub TrainDamage(train As PTrain, dm As Integer)
  Train->Damage+=dm
  g.money-=dm
  If ShowMoney Then
    message("Train "+Train->TName+" Damage by Turnout Speed -$"+MoneyStr(dm))
  Else
    message("Train "+Train->TName+" Damage by Turnout Speed")
  EndIf
End Sub


Sub AutoPilot(train As PTrain)
  Dim As String Signal
  Dim As Integer sp
  
  If Train->sp>0 Then
    Signal=Train->tr->SigF
  Else
    Signal=Train->tr->SigR
  EndIf
  
  'Auto Pilot Signals
  If (train->control And auto) Then
    
    If Signal="stop" Then  'activate train auto stop
      train->control=train->control Or brake
      train->AutoSpeed=0
    EndIf
    
    If Signal="slow" Then  'activate train slow
      If train->sp>=0 Then
        train->AutoSpeed=SlowSpeed
      Else
        train->AutoSpeed=-SlowSpeed
      EndIf
    EndIf

    If Signal="fast" Then  'activate train slow
      If train->sp>=0 Then
        train->AutoSpeed=FastSpeed
      Else
        train->AutoSpeed=-FastSpeed
      EndIf
    EndIf

    If left(Signal,6)="speed:" Then  'activate train slow
      sp=Val(right(Signal,Len(signal)-6))
      If Abs(sp)<1000 Then
        If Train->sp>0 Then
        'set AutoSpeed to signal value
          Train->AutoSpeed=sp
        Else
        'set AutoSpeed to negative value, if train drive backwards
          Train->AutoSpeed=-sp
        EndIf
      EndIf
    EndIf

  EndIf
  
  'Anytime Signals
  If Signal="crash" Then 'activate train crash
    CrashTrain(train,"by Signal")
    If (train->control And crash) = 0 Then
      LogFile("  Track:"+train->tr->mytrack->tName)
      LogFile("  Segment:"+str(train->tr->tNum))
    EndIf
  EndIf
  
  'Check turnout speed and train damage
  If Train->tr->Turn<>0 Then
    If Train->tr->Turn->Turn=1 Then
      'turnout forward
      If Abs(Train->sp)>2*MaxSpTurnFw*SpeedScale Then
        CrashTrain(Train, "Turnout Speed too high")
      ElseIf Abs(Train->sp)>MaxSpTurnFw*SpeedScale Then
        TrainDamage(Train, _
          (Abs(Train->sp)-Abs(MaxSpTurnFw*SpeedScale))*(Train->Waggons+3))
      EndIf
    ElseIf Train->tr->Turn->Turn=2 Then
      'turnout switched (Turn=2)
      If Abs(Train->sp)>2*MaxSpTurnSw*SpeedScale Then
        CrashTrain(Train, "Turnout Speed too high")
      ElseIf Abs(Train->sp)>MaxSpTurnSw*SpeedScale Then
        TrainDamage(Train, _
          (Abs(Train->sp)-Abs(MaxSpTurnSw*SpeedScale))*(Train->Waggons+3))
      EndIf
    EndIf
  EndIf

End Sub


'TrainCar: 0=middle, 1=first, 2=last
'Speed: real speed of the train
'       (cars always have negative speed to get the distance
'        from the train)
Sub LockTrack(Car As PTrain, train As PTrain, TrainCar As Integer, Speed As Integer)
  Dim As longint x1, y1, x2, y2 'Calculation needs higher precision

  If Speed>=0 Then
    If TrainCar=1 Then
    
      'check front track end
      If Car->tr->pf = NULL Then
        'crash own train
        If (train->control And crash) = 0 Then
          CrashTrain(train,"Track End")
          LogFile("  Track:"+train->tr->mytrack->tName)
          LogFile("  Segment:"+str(train->tr->tNum))
        EndIf
      EndIf
      
      'check front collision
      If Car->tr->LockedBy<>NULL _
      AndAlso Car->tr->LockedBy<>Train Then

        'crash own train
        If (train->control And crash) = 0 Then
          CrashTrain(train,"Other Train")
          LogFile("  Track:"+train->tr->mytrack->tName)
          LogFile("  Segment:"+str(train->tr->tNum))
        EndIf

        'crash next train
        If (car->tr->LockedBy->control And crash) = 0 Then
          CrashTrain(car->tr->LockedBy,"Other Train")
          LogFile("  Track:"+car->tr->LockedBy->tr->mytrack->tName)
          LogFile("  Segment:"+str(car->tr->LockedBy->tr->tNum))
        EndIf
      EndIf
      
      'lock track in front
      car->tr->LockedBy=Train
      
      'lock turnout
      If (car->tr->turn<>NULL) _
      AndAlso (car->tr->turn->turn=2) _
      Then
        car->tr->turn->pr1->LockedBy=Train
        car->tr->turn->pr2->LockedBy=Train
      EndIf
      
      
    EndIf
    If TrainCar=2 Then
    
      'unlock track in back
      Car->tr->LockedBy=NULL
      
      'unlock turnout
      If (car->tr<>NULL) _
      AndAlso (car->tr->pr<>NULL) _
      AndAlso (car->tr->pr->turn<>NULL) _
      AndAlso (car->tr->pr->turn->turn=2) _
      Then
        car->tr->pr->turn->pr1->LockedBy=NULL
        car->tr->pr->turn->pr2->LockedBy=NULL
      EndIf
      
    EndIf
  EndIf
  
  If Speed<0 Then
    If TrainCar=2 Then
    
      'check rear track end
      If Car->tr->pr = NULL Then
        'crash own train
        If (train->control And crash) = 0 Then
          message("Crash: Train "+train->TName+" crashed by track end")
          LogFile("  Track:"+train->tr->mytrack->tName)
          LogFile("  Segment:"+str(train->tr->tNum))
        EndIf
        CrashTrain(train,"")
      EndIf
      
      'check rear collision
      If Car->tr->LockedBy<>NULL _
      AndAlso Car->tr->LockedBy<>Train Then

        'crash own train
        If (train->control And crash) = 0 Then
        CrashTrain(train,"Other Train")
          LogFile("  Track:"+train->tr->mytrack->tName)
          LogFile("  Segment:"+str(train->tr->tNum))
        EndIf

        'crash next train
        If (car->tr->LockedBy->control And crash) = 0 Then
        CrashTrain(car->tr->LockedBy,"Other Train")
          LogFile("  Track:"+car->tr->LockedBy->tr->mytrack->tName)
          LogFile("  Segment:"+str(car->tr->LockedBy->tr->tNum))
        EndIf
      EndIf
      'lock track in back
      Car->tr->pf->LockedBy=Train
    EndIf
    If TrainCar=1 Then
      'unlock track in back
      Car->tr->pf->LockedBy=NULL
    EndIf
  EndIf
End Sub


'Sub DoTrainState(train As PTrain)
'End Sub


Sub moveTrain(train As PTrain, tn As Integer)
  Dim As longint x1, y1, x2, y2 'Calculation needs higher precision
  Dim As Integer i
  
  'if it's a train, not a train car
  If tn Then
    
    If train->state=ts_stop Then
    ElseIf train->state=ts_deliver Then
      If train->si1>0 Then
        train->si1-=1
      Else
        train->state=ts_drive
        If (train->control And auto) _
        AndAlso (train->control And restart) Then
          train->AutoSpeed=SlowSpeed
        EndIf
      EndIf
    ElseIf train->state=ts_drive Then
      
      'Check Train Flag Crash
      If (train->control And crash) Then
        train->sp=0
    
      'Check Autopilot Brake
      ElseIf (train->control And brake) Then
        If train->sp>0 Then
          If Abs(train->sp)>BrakeSteps Then
            train->sp-=BrakeSteps
          Else
            train->sp=0
          EndIf
        ElseIf train->sp<0 Then
          If Abs(train->sp)>BrakeSteps Then
            train->sp+=BrakeSteps
          Else
            train->sp=0
          EndIf
        ElseIf train->sp=0 Then
          train->control=train->control And (Not brake)
          
          'check if train stop in station
          If train->tr->TName="s" Then
            If train->state=ts_drive Then
              train->state=ts_deliver
              train->si1=CDeliverTime*FpsLimit
              i=train->waggons*(train->TripOdo)/10000
              train->credit+=i
              g.money+=i
              If ShowTrainDeliver Then
                message("Train ("+str(tn)+") "+train->TName+" delivers $"+MoneyStr(i))
              EndIf
              Train->TripOdo=0
            EndIf
          EndIf
        EndIf
    
      'check AutoSpeed
      ElseIf (train->AutoSpeed <>0) Then
        If     (train->AutoSpeed*SpeedScale) > train->sp Then
          train->sp=train->sp+1
          If SpeedLimit AndAlso (train->sp > train->MaxSpeed*SpeedScale) Then
            train->sp = train->MaxSpeed*SpeedScale
          EndIf
        ElseIf (train->AutoSpeed*SpeedScale) < train->sp Then
          train->sp=train->sp-1
          If SpeedLimit AndAlso (train->sp < -train->MaxSpeed*SpeedScale) Then
            train->sp = -train->MaxSpeed*SpeedScale
          EndIf
        Else
          train->AutoSpeed=0
        EndIf
      EndIf
      
      'check if autospeed reached nearly exact (floting point variable)
      If Abs((train->AutoSpeed*SpeedScale)-train->sp) <=1 Then
        train->sp=train->AutoSpeed*SpeedScale
        train->AutoSpeed=0
      EndIf
      
      'calculate odometer
      train->TripOdo+=train->sp
      train->uOdoMeter+=train->sp
      Do While train->uOdoMeter>1000*m
        train->uOdoMeter=train->uOdoMeter-1000*m
        train->OdoMeter+=1
      Loop
      
    EndIf
  EndIf
  
  
  'calculate train position  
  train->ps=train->ps+train->sp
  
  
  'if left track segment forward, set pointer to next
  Do While (train->ps > train->tr->length)
    If train->tr->pf <> 0 Then
      'drive on next track
      train->ps=train->ps-train->tr->length
      train->tr=train->tr->pf
      
      'if it's a train, not a train car
      If tn Then
        'auto pilot
        AutoPilot(Train)
      EndIf
      
    Else
      'reverse direction if track ends here
      'is needed to avoid endless loop
      'note: collision handling in sub LockTrack()
      train->sp=-train->sp
      train->ps=0
    EndIf
  Loop
  
  'if left track segment backward, set pointer to last
  Do While (train->ps < 0)
    If train->tr->pr <> 0 Then
      train->ps=train->ps+train->tr->pr->length
      train->tr=train->tr->pr
      
      'if it's a train, not a train car
      If tn Then
        'auto pilot
        AutoPilot(Train)
      EndIf
      
    Else
      'reverse direction if track ends here
      'is needed to avoid endless loop
      'note: collision handling in sub LockTrack()
      train->sp=-train->sp
      train->ps=0
    EndIf
  Loop
  
  'calculate X and Y coordinates
  x1=train->tr->x
  y1=train->tr->y
  If train->tr->pf <> 0 Then
    x2=train->tr->pf->x
    y2=train->tr->pf->y
  Else
    x2=x1
    y2=y1
  EndIf

  train->x=(x1*(train->tr->length-train->ps) _
           +x2*train->ps)/train->tr->length
  train->y=(y1*(train->tr->length-train->ps) _
           +y2*train->ps)/train->tr->length
  
  
End Sub


Sub PlaceTrack(T As PTrackBase, Tr As PTrack)
  Dim As Integer lng, x, y, z, angle
  '(2) Coordinates
  lng=25*m
  If Len(Tr->TName)=2 Then
    lng=InStr("0123456789",Right$(Tr->TName,1))*lng/5
  EndIf
  angle=T->anga
  If Left$(Tr->TName,1)="L" Then
    angle=angle-MinAngle*2
  EndIf
  If Left$(Tr->TName,1)="R" Then
    angle=angle+MinAngle*2
  EndIf
  If Left$(Tr->TName,1)="l" Then
    angle=angle-MinAngle
    lng = lng Shr 1
  EndIf
  If Left$(Tr->TName,1)="r" Then
    angle=angle+MinAngle
    lng = lng Shr 1
  EndIf
  If Left$(Tr->TName,1)="s" Then
    lng=25*5*m
  EndIf
  If Left$(Tr->TName,1)="e" Then
    lng=1
  EndIf
  angle=angle And &H1ff
  x=T->xa+Cos(angle*pi/256)*lng
  y=T->ya+Sin(angle*pi/256)*lng
  z=T->za
  Tr->angle=angle
  Tr->x=T->xa
  Tr->y=T->ya
  Tr->z=T->za
  'save actual coordinates
  T->anga=angle
  T->xa=x
  T->ya=y
  T->za=z
End Sub


Sub AddTrack(T As PTrackBase, element As String, visflag As String)
  Dim As PTrack tnew
  Dim As Integer lng, x, y, z, xs, ys, zs, angle
  'check if element builds a track
  If InStr(g.BuildTrk,Left$(element,1)) Then
    T->build=T->build+element
    '(1) memory and pointer
    
    'replace "Allocate" by "New" and "DeAllocate" by "Delete" (hint from fxm / FreeBASIC forum)
    'tnew=CAllocate(sizeof(TTrack))
    tnew=New TTrack
    
    tnew->mytrack=T
    tnew->Tname=element
    tnew->pn=0
    tnew->pf=0
    tnew->pr=0
    
    tnew->turn=0
    If visflag="v" Then
      tnew->visible=0
    Else
      tnew->visible=-1
    EndIf

    If element="s" Then
      tnew->SigF="stop"
      tnew->SigR="stop"
    Else
      tnew->SigF=""
      tnew->SigR=""
    EndIf
    
    If T->start=0 Then  'first track segment
      T->start=tnew
      T->last=tnew
      xs=T->x
      ys=T->y
      zs=T->z
      angle=T->angle
      tnew->TNum=1
    Else
      xs=T->last->x
      ys=T->last->y
      zs=T->last->z
      angle=T->last->angle
      T->last->pn=tnew
      T->last->pf=tnew
      tnew->pf=0
      tnew->pr=T->last
      tnew->TNum=T->last->TNum+1
      T->last=tnew
    EndIf
    PlaceTrack(T, tnew)
  EndIf
End Sub


Sub SetTrackSize(tp As PTrack, CalcDistance As integer)
  Dim As Integer a
  'length
  If tp->pf<>0 Then
    tp->length=Sqr((tp->pf->x-tp->x)^2+(tp->pf->y-tp->y)^2)
  Else
    tp->length=25*m
  EndIf
  If tp->pn<>0 Then
    tp->lengthn=Sqr((tp->pn->x-tp->x)^2+(tp->pn->y-tp->y)^2)
  Else
    tp->lengthn=25*m
  EndIf
  
  If tp->pr<>0 Then
    If CalcDistance<>0 Then tp->distance=tp->pr->distance+tp->length
    'precise drawing
    'Speedup: calculate sin/cos during construction
    'tracks fit exactly at connections
    'average value for angle between two tracks
    If Abs(tp->pr->angle-tp->angle)<255 Then
      a=(tp->pr->angle+tp->angle)/2
    Else
      a=(tp->pr->angle+tp->angle)/2+256
    EndIf
    tp->sin0=Sin(a/256*pi)*trackwidth*m
    tp->cos0=Cos(a/256*pi)*trackwidth*m
  EndIf
End Sub


Sub SwitchTurnout(turnout As PTurnout)
  If turnout<>0 _
  AndAlso turnout->pr1->LockedBy=NULL _
  AndAlso turnout->pr2->LockedBy=NULL _
  AndAlso turnout->pf1->LockedBy=NULL _
  AndAlso turnout->pf2->LockedBy=NULL _
  Then
    'toggle turnout
    If turnout->turn=1 Then
    'set turn on
      turnout->turn=2
      turnout->pf=turnout->pf2
      'set pointer from outside tracks
      turnout->pr1->pf=turnout->pf2
      turnout->pf2->pr=turnout->pr1
      turnout->pr2->pf=turnout->pf1
      turnout->pf1->pr=turnout->pr2
      SetTrackSize(turnout->pr1, 0)
      SetTrackSize(turnout->pr2, 0)
    Else
    'set turn off
      turnout->turn=1
      turnout->pf=turnout->pf1
      'set pointer from outside tracks
      turnout->pr1->pf=turnout->pf1
      turnout->pf2->pr=turnout->pr2
      turnout->pr2->pf=turnout->pf2
      turnout->pf1->pr=turnout->pr1
      SetTrackSize(turnout->pr1, 0)
      SetTrackSize(turnout->pr2, 0)    EndIf
  EndIf
End Sub


'calculate dimensions and world-coordinates
'use ActivateTrack after track build or change
Sub ActivateTrack(T As PTrackBase)
  Dim As PTrack tp
  'calculate track coordinates
  T->xa=T->x
  T->ya=T->y
  T->za=T->z
  T->anga=T->angle
  'calculate track dimension
  T->dimension.maxx=T->x
  T->dimension.minx=T->x
  T->dimension.maxy=T->y
  T->dimension.miny=T->y
  'loop (1) place track segments
  tp=T->start
  Do
    PlaceTrack(T,tp)
    tp=tp->pn
  Loop Until tp->pn=0
  PlaceTrack(T,tp)
  tp=tp->pf
  
  'loop (2) calculate length and rail position offsets
  tp=T->start
  If tp->pr<>0 Then tp->pr->distance=0
  T->length=0
  Do
    If tp<>0 Then SetTrackSize(tp, tp<>T->Start)
    tp=tp->pn
    If tp<>0 Then
      'Main track length
      T->length=T->length+tp->length
      'calculate main track dimension
      If tp->x > T->dimension.maxx Then T->dimension.maxx = tp->x
      If tp->x < T->dimension.minx Then T->dimension.minx = tp->x
      If tp->y > T->dimension.maxy Then T->dimension.maxy = tp->y
      If tp->y < T->dimension.miny Then T->dimension.miny = tp->y
    EndIf
  Loop Until tp=0
End Sub


Sub OpenCloseTrack(T As PTrackBase)
  If T->start->pr=0 Then
    'close track
    'connect start and end track segment
    'calculate length of last track segment
    T->start->pr=T->last
    T->last->pf=T->start
    
    ActivateTrack(T)  
  Else
    'open track
    T->start->pr=0
    T->last->pf=0
  EndIf
  'connect start and end track segment
End Sub


Sub OpenTrack(T As PTrackBase)
  'connect start and end track segment
  T->start->pr=0
  T->last->pf=0
End Sub


Sub CloseTrack(T As PTrackBase)
  'connect start and end track segment
  'calculate length of last track segment
  T->start->pr=T->last
  T->last->pf=T->start
  
  ActivateTrack(T)  
End Sub


'Delete spaces and linebreaks from string
'replace *[n] by n times of last command
Function ExpandTrackString(s As String) As String
  Dim As Integer i, j, k
  Dim As String ds, c
  ds=""
  For i=1 To Len(s)
    If Mid$(s,i,1)>" " Then
      If Mid$(s,i,1)="(" Then
      
        'skip track signal string
        ds=ds+Mid$(s,i,1)
        Do
          i+=1
          ds=ds+Mid$(s,i,1)
        Loop Until Mid$(s,i,1)=")" _
        OrElse i>Len(s)
        
      ElseIf InStr(g.BuildTrk,Mid$(s,i,1)) Then
        'add the build track command
        c=Mid$(s,i,1)
        If InStr("0123456789",Mid$(s,i+1,1)) Then
          c=c+Mid$(s,i+1,1)
          i+=1
        EndIf
        
        'invisible flag
        If ("v"=Mid$(s,i+1,1)) Then
          c=c+Mid$(s,i+1,1)
          i+=1
        EndIf
        
        ds=ds+c
      Else
        If Mid$(s,i,1)="*" Then
          'repeat last track build command n times
          If InStr("0123456789",Mid$(s,i+1,1)) Then
            k=0
            Do While InStr("0123456789",Mid$(s,i+1,1))
              k=k+InStr("0123456789",Mid$(s,i+1,1))-1
              i+=1
              If InStr("0123456789",Mid$(s,i+1,1)) Then k=k*10
            Loop
            If (k>1) And (k<100) Then
              For j=1 To k-1
                ds=ds+c
              Next
            EndIf
          EndIf
        EndIf
      EndIf
    EndIf
  Next
  Return ds
End Function


'################################################
'## Create and Delete Objects
'################################################


Sub CreateItem(index As Integer, x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer, build As Integer, col As Integer, CoorScale As Integer)
  LogFile("Create Item("+str(index)+")")
  If w.Items(index)=NULL Then
    w.Items(index)=New TItem
    w.Items(index)->build=0
    LogFile("  New Item - Memory Reserved")
  Else
    LogFile("  Overwrite Existing Item")
  EndIf
  
  w.Items(index)->a.x=x1
  w.Items(index)->a.y=y1
  w.Items(index)->b.x=x2
  w.Items(index)->b.y=y2
  w.Items(index)->build=build 'house, station, forest...
  w.Items(index)->col=col
  LogFile("  ok")
End Sub


Sub DeleteItem(index As Integer)
  If w.Items(index)<>NULL Then
    LogFile("Delete Item("+str(index)+")")
    DELETE w.Items(index)
    w.Items(index)=NULL
    g.ItemSel=0
    LogFile("  ok")
  EndIf
End Sub


Function NewTrain(Track As Integer, Speed As Integer, _
             Picture As Integer, WaggonPic As Integer, _
             Length As Integer) As Integer
  Dim As Integer i,n
  
  'Set i to next free Train Index
  i=0
  Do
    i+=1
  Loop Until (w.Train(i)=NULL) OrElse (i=MaxTrains)
  
  If (Track<=MaxTracks) AndAlso (i<=MaxTrains) Then
    LogFile("New Train("+str(i)+")")
    If w.Start(Track)=NULL Then
      LogFile("  -Error, Track("+str(Track)+") does not exist.")
    Else
      'check, if train exist or have to be created new
      If w.Train(i)=NULL Then
        w.Train(i)=New TTrain
      EndIf
      
      w.Train(i)->sp=Speed
      If g.EditTrkPtr<>NULL Then
        'place train on selected track segment
        w.Train(i)->tr=g.EditTrkPtr
      Else
        'place train on first track segment, if no track segment selected
        w.Train(i)->tr=w.Start(Track)->start->pn
      EndIf
      w.Train(i)->ps=0
      w.Train(i)->control=none 'auto
      w.Train(i)->waggons=IIF(length<DefMaxCars,Length,DefMaxCars)
      w.Train(i)->pic=Picture
      w.Train(i)->WaggonPic=WaggonPic
      
      'set train name, find a unique name
      n=i
      Do While (GetTrainIndex("Train"+str(n)))
        n+=1
      Loop
      w.Train(i)->TName="Train"+str(n)
      w.Train(i)->Odometer=0
      w.Train(i)->TripOdo=0
      w.Train(i)->Damage=0
      w.Train(i)->Credit=0
      w.Train(i)->MaxSpeed=120
      w.Train(i)->MaxCars=10
      w.Train(i)->State=ts_drive
      w.Train(i)->si1=0
      w.Train(i)->si2=0
      w.Train(i)->si3=0
      
      LogFile("  Track="+w.Start(Track)->TName+"")
    EndIf
    LogFile("  ok")
  Else
    LogFile("New Train("+str(i)+") Error - Too much trains")
  EndIf
  NewTrain=i
End Function


Sub UnLockTrack(tr As PTrack)
  'lock turnout
  If (tr->turn<>NULL) _
  AndAlso (tr->turn->turn=2) _
  Then
    tr->turn->pr1->LockedBy=NULL
    tr->turn->pr2->LockedBy=NULL
  Else
    tr->LockedBy=NULL
  EndIf
End Sub


Sub DeleteTrain(index As Integer)
  Dim As PTrack Tr
  If w.Train(index)<>NULL Then
    LogFile("Delete Train("+str(index)+")")
    
    'Remove Track Lock Flags
    Tr=w.Train(index)->Tr
    Do While tr->pf<>NULL AndAlso tr->pf->LockedBy=w.Train(index)
      UnLockTrack(tr->pf)
      tr=tr->pf
    Loop
    Tr=w.Train(index)->Tr
    Do While tr->pr<>NULL AndAlso  tr->pr->LockedBy=w.Train(index)
      UnLockTrack(tr->pr)
      tr=tr->pr
    Loop
    UnLockTrack(w.Train(index)->Tr)
    
    DELETE w.Train(index)
    w.Train(index)=0
    wv.cam=0
    g.ctrl=0
    LogFile("  ok")
  EndIf
End Sub


Function AddTurnout(t1 As PTrack, t2 As PTrack) As PTurnout
  Dim As PTurnout turnout
  'check if t1 and t2 heve no turnout connects
  If (t1->turn=0) And (t2->turn=0) Then
    LogFile("Add Turnout("+t1->Mytrack->TName+", "+t2->Mytrack->TName+")")
    'memory
    
    'replace "Allocate" by "New" and "DeAllocate" by "Delete" (hint from fxm / FreeBASIC forum)
    'turnout=CAllocate(sizeof(TTurnout))
    turnout=New TTurnout

    'tell the tracks from the turnout
    t1->turn=turnout
    t2->turn=turnout
    'save pointers to connected tracks
    turnout->pr1=t1
    turnout->pr2=t2
    turnout->pf1=turnout->pr1->pf
    turnout->pf2=turnout->pr2->pf
    'set switch coordinates
    turnout->SwitchCoor.x=(t1->x+t2->x)/2
    turnout->SwitchCoor.y=(t1->y+t2->y)/2
    'set turn off
    turnout->turn=1
    'set pointer from outside tracks
    'cross switch
    turnout->pr1->pf=turnout->pf1
    turnout->pf1->pr=turnout->pr1
    turnout->pr2->pf=turnout->pf2
    turnout->pf2->pr=turnout->pr2
    SetTrackSize(turnout->pr1, 0)
    SetTrackSize(turnout->pr2, 0)
    LogFile("  ok")
    Return turnout
  Else
    Return 0
  EndIf
End Function


Sub RemoveTurnout(index As Integer)
  Dim As PTurnout Turnout

  Turnout=w.Turnouts(index)
  If turnout<>NULL Then
    LogFile("Remove Turnout("+Turnout->pr1->Mytrack->TName+", "+Turnout->pr2->Mytrack->TName+")")
    'Cleanup
    'tracks forget the turnout
    turnout->pr1->turn=0
    turnout->pr2->turn=0
    'set pointer from outside tracks
    turnout->pr1->pf=turnout->pf1
    turnout->pf1->pr=turnout->pr1
    turnout->pf2->pr=turnout->pr2
    turnout->pr2->pf=turnout->pf2
    SetTrackSize(turnout->pr1, 0)
    SetTrackSize(turnout->pr2, 0)
    
    g.EditTrkPtr=NULL
    g.EditTrkPtrA=NULL
    
    'replace "Allocate" by "New" and "DeAllocate" by "Delete" (hint from fxm / FreeBASIC forum)
    'DeAllocate turnout
    Delete turnout
    
    LogFile("  ok")
    w.Turnouts(index)=0
    turnout=0
  EndIf
End Sub


Function NewTrack(trkname As String, sx As Integer, sy As Integer, sz As Integer, angle As Integer) As PTrackBase
  Dim As PTrackBase tinfo

  LogFile("Create New Track("+trkname+")")
  tinfo=New TTrackBase

  'set angle to positive 0..511
  Do While angle<0
    angle=angle+512
  Loop
  angle=angle And 511
  
  tinfo->tname=trkname
  tinfo->build=""
  tinfo->start=0
  tinfo->last=0
  tinfo->x=sx
  tinfo->y=sy
  tinfo->z=sz
  tinfo->angle=angle
  tinfo->xa=sx
  tinfo->ya=sy
  tinfo->za=sz
  tinfo->anga=angle
  tinfo->length=0
  LogFile("  ok")
  Return tinfo
End Function  


Sub DeleteTrack(index As Integer)
  Dim As Integer i, j
  
  If w.Start(index)<>0 Then
    LogFile("Delete Track("+str(index)+") "+w.Start(index)->TName)

    'first delete trains running on that track
    For i=1 To MaxTrains
      If w.Train(i)<>0 Then
        If w.Train(i)->tr->mytrack=w.Start(index) Then
          'delete this train
          DeleteTrain(i)
        EndIf
      EndIf
    Next
    LogFile("  Trains deleted")

    'then delete turnouts
    For i=1 To MaxTurnouts
      If w.Turnouts(i)<>0 Then
        If (w.Turnouts(i)->pr1->mytrack=w.Start(g.trksel)) _
        Or (w.Turnouts(i)->pf1->mytrack=w.Start(g.trksel)) _
        Or (w.Turnouts(i)->pr2->mytrack=w.Start(g.trksel)) _
        Or (w.Turnouts(i)->pf2->mytrack=w.Start(g.trksel)) _
        Then
          'delete this turnout
          RemoveTurnout(i)
        EndIf
      EndIf
    Next
    LogFile("  Turnouts deleted")

    'then delete the track
    g.EditTrkPtr=w.Start(index)->start
    
    j=0
    Do While g.EditTrkPtr<>NULL
      j+=1
      'LogFileNoBr("  "+str(j))

      g.EditTrkPtrA=g.EditTrkPtr
      'LogFileNoBr(".")

      g.EditTrkPtr=g.EditTrkPtr->pn
      'LogFileNoBr(".")

      DELETE g.EditTrkPtrA
      'LogFileNoBr(".")

      If j Mod 10 = 0 Then LogFileNoBr(".")
    Loop
    
    LogFile("  ##")
    LogFile("  Track deleted")
    Delete w.Start(index)
    w.Start(index)=0
    g.trksel=0
    g.EditTrkPtr=0
    g.EditTrkPtrA=0
    LogFile("  ok")
  EndIf
End Sub




'Build track from a build-string
Function BuildTrack(trkname As String, ByRef s As String, sx As Integer, sy As Integer, sz As Integer, angle As Integer) As PTrackBase
  Dim As String ts, sig
  Dim As PTrackBase newtrk
  Dim As Integer i
  
  LogFile("")
  LogFile("BuildTrack TrkName="+TrkName)
  ts=ExpandTrackString(s)
  newtrk=NewTrack(trkname, sx, sy, sz, angle)
  i=1
  Do
    If Mid$(ts,i,1)="c" Then
      LogFile("  BuildTrack - Close")
      CloseTrack(newtrk)
      i+=1
    ElseIf Mid$(ts,i,1)="(" Then

      LogFile("  BuildTrack - Signal")

      'Track Signal Fwd
      sig=""
      i+=1
      Do While (Mid$(ts,i,1)<>",") _
      AndAlso (i<Len(ts))
        sig=sig+Mid$(ts,i,1)
        i+=1
      Loop
      newtrk->Last->SigF=sig
      LogFile("BuildTrack SigF="+sig)

      'Track Signal Rev
      sig=""
      i+=1
      Do While (Mid$(ts,i,1)<>")") _
      AndAlso (i<Len(ts))
        sig=sig+Mid$(ts,i,1)
        i+=1
      Loop
      newtrk->Last->SigR=sig
      LogFile("BuildTrack SigR="+sig)

    ElseIf InStr("0123456789",Mid$(ts,i+1,1)) Then
      If ("v"=Mid$(ts,i+2,1)) Then
        AddTrack(newtrk, mid$(ts,i,2),"v")
        i+=3      Else
        AddTrack(newtrk, mid$(ts,i,2),"")
        i+=2
      EndIf
    Else
      If ("v"=Mid$(ts,i+1,1)) Then
        AddTrack(newtrk, Mid$(ts,i,1),"v")
        i+=2
      Else
        AddTrack(newtrk, Mid$(ts,i,1),"")
        i+=1
      EndIf
    EndIf
    
'    ElseIf InStr("0123456789",Mid$(ts,i+1,1)) Then
'      AddTrack(newtrk, mid$(ts,i,2))
'      i+=2
'    Else
'      AddTrack(newtrk, mid$(ts,i,1))
'      i+=1
'    EndIf
    
  Loop Until(i>Len(ts))
  ActivateTrack(newtrk)
  LogFile("  BuildTrack - ok")
  Return newtrk
End Function


'add turnout, return turnout index
Function InstallTurnout(p1 As PTrackBase, i1 As Integer, _
    p2 As PTrackBase, i2 As Integer) As Integer
  Dim As PTrack tp1, tp2
  Dim As Integer i
  tp1=p1->start
  For i=1 To i1
    If tp1->pn<>0 Then tp1=tp1->pn
  Next
  tp2=p2->start
  For i=1 To i2
    If tp2->pn<>0 Then tp2=tp2->pn
  Next
  i=0
  Do
    i+=1
  Loop Until (w.Turnouts(i)=0) OrElse (i>MaxTurnouts)

  If i<=MaxTurnouts Then
    w.Turnouts(i)=AddTurnout(tp1, tp2)
  EndIf
  InstallTurnout=i
End Function


'add turnout, return turnout index
Function TurnoutByName(TName1 As String, TSeg1 As Integer, _
    TName2 As String, TSeg2 As Integer) As Integer
  
  Return InstallTurnout(w.Start(NumOfTrack(TName1)), TSeg1, _
      w.Start(NumOfTrack(TName2)), TSeg2)
End Function




'################################################
'## Train simulation
'################################################


Sub world_sim
  Dim As Integer i
  'move train
  For i=1 To maxtrains
    If w.Train(i)<>0 Then
      MoveTrain(w.Train(i),i)   'i=train number, 0=train car
      LockTrack(w.Train(i),w.Train(i),1,w.Train(i)->sp)   '1=train, first car
    EndIf
  Next
  g.framestotal+=1
End Sub


Function IsTrainVisible(i As Integer) As Integer
  Dim As Integer j, isvisible
  Dim As TTrain waggon
  If w.Train(i)<>0 Then
    'check if train or waggons are visible
    isvisible=visible(w.Train(i)->x,w.Train(i)->y)
    'calculate waggons positions
    waggon.tr=w.Train(i)->tr
    waggon.ps=w.Train(i)->ps
    waggon.control=none
    waggon.sp=-10*m  'Distance between waggons
    For j=1 To w.Train(i)->waggons*2+1
      moveTrain(@waggon,0) '"walk on track" to next waggon
      If j=1 Then
        waggon.sp=-6*m
      Else
        If (j Mod 2)=0 Then
          waggon.sp=-10*m
        Else
          waggon.sp=-6*m
        EndIf
      EndIf
      If visible(waggon.x,waggon.y) Then isvisible+=1
    Next
  EndIf
  Function=isvisible
End Function


'################################################
'## render world graphics
'################################################


Sub world_render(dwin As Any Ptr, show As Integer)

  'show bit 0: print fps and scale info
  'show bit 1: print train speed and track info
  'show bit 2: print train number
  Dim As PMapR Map1
  Dim As Integer i,j,wagx,wagy,col
  Dim As Long x1,x2,cx,y1,y2,cy,cFade
  Dim As TTrain waggon
  Dim As PTurnout Turnout
  Dim As String s    'temporary string
    
    'Cls
    Line dwin,(0,0)-(v.WinX-1,v.WinY-1),GroundColor,BF
    
    'check If camera Point To a valid train
    If w.Train(wv.cam)=NULL Then
      wv.cam=0
    EndIf
    
    'camera follows train

    If wv.cam<>0 Then
      If (wv.CamSlide<>0) Then
'      AndAlso (v.OldCam<>0) _
'      AndAlso (v.Cam<>0) Then
        cfade=wv.CamSlide
        
        x1=wv.OldCamX          /100
        x2= w.Train(wv.Cam)->x /100
        y1=wv.OldCamY          /100
        y2= w.Train(wv.Cam)->y /100
        
        cx=(cFade * x1 + (wv.CamSteps-cFade)*x2)/wv.CamSteps
        cy=(cFade * y1 + (wv.CamSteps-cFade)*y2)/wv.CamSteps
        
        cx=cx*100
        cy=cy*100

        ScreenCenter(cx,cy,v)
        If wv.CamSlide Then
          wv.CamSlide-=1
        EndIf
      Else
        ScreenCenter(w.Train(wv.cam)->x, w.Train(wv.cam)->y,v)
      EndIf
    EndIf

'    If v.cam<>0 Then
'      ScreenCenter(w.Train(v.cam)->x, w.Train(v.cam)->y)
'    EndIf


    '################################################
    '## simple map of random green colors
    '################################################

    #if mapon
      'draw map
      If show And 1 AndAlso wv.mapactive Then
        map1=w.map
        Do While (map1->pnext<>0)
          If visrect(map1->x1,map1->y1,map1->x2,map1->y2) Then
            Line dwin,(xcoor(map1->x1),ycoor(map1->y1)) _
            -(xcoor(map1->x2),ycoor(map1->y2)), map1->Color, BF
          EndIf
          map1=map1->pnext
        Loop
      EndIf
      
    #endif


    '################################################
    '## show a bmp-picture as map
    '################################################


    #if landmapon
    
      Dim As Integer x, y, mpx, mpy
      Dim As Double tnow

      'GfxPrint6 "maph="+str(maph)+" mapw="+str(mapw),320,8,&HFFFFFF,dwin


      'Draw using Pseudo-array / Bitmap array (fastest version)
      'See FreeBASIC Manual, ImageInfo performance example
      'draw map
      tnow=timer    'performance watch
      Dim As Integer map_pitch, k
      Dim As Any Ptr map_pix
      If show And 1 AndAlso wv.landmapactive Then
        If 0=ImageInfo (dwin,,,, map_pitch, map_pix,) Then
          For i=0 To MaxBmp
            
            'calling Timer in a loop will slow down performance
            
            If (Timer-tnow)*1000<MapPerformance _
            AndAlso w.MapHdr(i)<>0 _
            AndAlso w.MapHdr(i)->ZoomMin <= v.scale _
            AndAlso w.MapHdr(i)->ZoomMax >= v.scale _            
            Then
              j=w.MapHdr(i)->BmpIndex
              For y=0 To v.WinY-1 Step 1
                mpy = (p2wy(y)-w.MapHdr(i)->y)/w.MapHdr(i)->scale
                If (mpy>=0) _
                  AndAlso (mpy<w.MapData(j)->h) Then
                  Dim maprow As UInteger Ptr = map_pix + y * map_pitch
                   For x=0 To v.WinX-1 Step 1
                    mpx = (p2wx(x)-w.MapHdr(i)->x)/w.MapHdr(i)->scale
                    If (mpx>=0) AndAlso (mpx<w.MapData(j)->w) Then
                      k=w.MapData(j)->data(mpx, mpy)
'                      If k<>invisiblecolor Then
                        maprow[x] = k
'                      EndIf

'                      maprow[x] = w.MapData(j)->data(mpx, mpy)

                    EndIf
                  Next x
                EndIf
              Next y
            EndIf
          Next i
        EndIf
      EndIf


'      'Draw using Pseudo-array / Bitmap array (fastest version)
'      'See FreeBASIC Manual, ImageInfo performance example
'      'draw map
'      tnow=timer    'performance watch
'      Dim As Integer map_pitch, k
'      Dim As Any Ptr map_pix
'      If v.landmapactive Then
'        If 0=ImageInfo (dwin,,,, map_pitch, map_pix,) Then
'          For i=0 To MaxBmp
'            If (Timer-tnow)*1000<MapPerformance _
'            AndAlso w.MapHdr(i)<>0 _
'            AndAlso w.MapHdr(i)->ZoomMin < v.scale _
'            AndAlso w.MapHdr(i)->ZoomMax > v.scale _            
'            Then
'              j=w.MapHdr(i)->BmpIndex
'              For y=0 To v.WinX-1 Step 1
'                mpy = (p2wy(y)-w.MapHdr(i)->y)/w.MapHdr(i)->scale
'                If (mpy>=0) _
'                  AndAlso (mpy<w.MapData(j)->h) Then
'                  Dim maprow As UInteger Ptr = map_pix + y * map_pitch
'                  For x=0 To v.WinY-1 Step 1
'                    mpx = (p2wx(x)-w.MapHdr(i)->x)/w.MapHdr(i)->scale
'                    If (mpx>=0) AndAlso (mpx<w.MapData(j)->w) Then
'                      k=w.MapData(j)->data(mpx, mpy)
''                      If k<>invisiblecolor Then
'                        maprow[x] = k
''                      EndIf
'
''                      maprow[x] = w.MapData(j)->data(mpx, mpy)
'
'                    EndIf
'                  Next x
'                EndIf
'              Next y
'            EndIf
'          Next i
'        EndIf
'      EndIf


'      'Draw using Pseudo-array / Bitmap array (fastest version)
'      'See FreeBASIC Manual, ImageInfo performance example
'      'draw map
'      Dim As Integer map_pitch
'      Dim As Any Ptr map_pix
'      If v.landmapactive Then
'        If 0=ImageInfo (dwin,,,, map_pitch, map_pix,) Then
'          
'          For y=0 To v.WinX-1 Step 1
'            mpy = (p2wy(y)-w.MapHdr(0)->y)/w.MapHdr(0)->scale
'            If (mpy>=0) _
'              AndAlso (mpy<w.MapData(0)->h) Then
'              Dim maprow As UInteger Ptr = map_pix + y * map_pitch
'              For x=0 To v.WinY-1 Step 1
'                mpx = (p2wx(x)-w.MapHdr(0)->x)/w.MapHdr(0)->scale
'                If (mpx>=0) _
'                  AndAlso (mpx<w.MapData(0)->w) Then
'                  maprow[x] = w.MapData(0)->data(mpx, mpy)
'                EndIf
'              Next x
'            EndIf
'          Next y
'          
'        EndIf
'      EndIf


'      'Draw using Pseudo-array / Bitmap array (fastest version)
'      'See FreeBASIC Manual, ImageInfo performance example
'      'draw map
'      Dim As Integer map_pitch
'      Dim As Any Ptr map_pix
'      If v.landmapactive Then
'        If 0=ImageInfo (dwin,,,, map_pitch, map_pix,) Then
'          For y=0 To v.WinX-1 Step 1
'            mpy = (p2wy(y)-mapposy)/mapscale
'            If (mpy>=0) AndAlso (mpy<maph) Then
'              Dim maprow As UInteger Ptr = map_pix + y * map_pitch
'              For x=0 To v.WinY-1 Step 1
'                mpx = (p2wx(x)-mapposx)/mapscale
'                If (mpx>=0) AndAlso (mpx<mapw) Then
'                  maprow[x] = maparray(mpx, mpy)
'                EndIf
'              Next x
'            EndIf
'          Next y
'        EndIf
'      EndIf



'      'Draw using PSet / Bitmap array (faster version)
'      'draw map
'       If v.landmapactive Then
'        For y=0 To v.WinX-1 Step 1
'          mpy = (p2wy(y)-mapposy)/mapscale
'          If (mpy>=0) AndAlso (mpy<maph) Then
'            For x=0 To v.WinY-1 Step 1
'              mpx = (p2wx(x)-mapposx)/mapscale
'              If (mpx>=0) AndAlso (mpx<mapw) Then
'                PSet dwin, (x,y),maparray(mpx, mpy)
'              EndIf
'            Next x
'          EndIf
'        Next y
'      EndIf



'      'Draw using PSet / Point (very slow)
'      'draw map
'      If v.landmapactive Then
'        For y=0 To v.WinY-1
'          mpy = (p2wy(y)-mapposy)/mapscale
'          If (mpy>=0) AndAlso (mpy<maph) Then
'            For x=0 To v.WinX-1
'              mpx = (p2wx(x)-mapposx)/mapscale
'              If (mpx>=0) AndAlso (mpx<mapw) Then
'                PSet dwin, (x,y), Point(mpx, mpy, map)
'              EndIf
'            Next x
'          EndIf
'        Next y
'      EndIf



    #endif





    
    'draw grid
    If wv.gridon Then drawgrid(0,0,worldx,worldy, _
      (tsmode=ts_edittrack) Or (g.ItemSel<>0), dwin)

    
    'draw track floors

    If (show And 2) AndAlso Railway Then 
      For i=1 To maxtracks
        'check if track exist (Vector <> 0)
        If w.Start(i)<>0 Then
          'check if track is visible on screen
          If visrect(w.Start(i)->dimension.minx, w.Start(i)->dimension.miny, _
             w.Start(i)->dimension.maxx, w.Start(i)->dimension.maxy) Then
            DrawTrackFloor(w.Start(i), g.trksel=i, dwin)
          EndIf
        EndIf
        
        If (i Mod TimeChecks)=0 AndAlso Not InTime(20) Then
          Exit For
        EndIf
      Next
    EndIf


    'draw tracks
    For i=1 To maxtracks
      'check if track exist (Vector <> 0)
      If w.Start(i)<>0 Then
        'check if track is visible on screen
        If visrect(w.Start(i)->dimension.minx, w.Start(i)->dimension.miny, _
           w.Start(i)->dimension.maxx, w.Start(i)->dimension.maxy) Then
          DrawTrack(w.Start(i), g.trksel=i, dwin)
        EndIf
      EndIf
      
      If (i Mod TimeChecks)=0 AndAlso Not InTime(20) Then
        Exit For
      EndIf
    Next
    
    
    'lock track from train
    For i=1 To maxtrains
      'check if train exist (pointer<>0)
      If w.Train(i)<>0 Then
        waggon.tr=w.Train(i)->tr
        waggon.ps=w.Train(i)->ps
        waggon.control=none
        waggon.sp=-10*m  'Distance between waggons (Loc size)
        For j=1 To w.Train(i)->waggons*2+1
          moveTrain(@waggon,0) '"walk on track" to next waggon (middle car)
            
          'claculate position of car
          If j=1 Then
            'Locomotive (Distance)
            waggon.sp=-6*m  'Distance between waggons
          Else
            If (j Mod 2)=0 Then
              wagx=waggon.x
              wagy=waggon.y
              waggon.sp=-10*m  'waggon length
            Else
              'Waggon
              waggon.sp=-6*m  'Distance between waggons
            EndIf
          EndIf
        Next
        LockTrack(@waggon,w.Train(i),2,w.Train(i)->sp) 'draw last car
      EndIf
    Next
    
    'draw train
    For i=1 To maxtrains
      'check if train exist (pointer<>0)
      If w.Train(i)<>0 Then
        'check if train is visible
        If (IsTrainVisible(i)>0) Then
          col=&H8080e0  'Train color
          If i=g.ctrl Then col=&Hc0c0ff 'Highlightet train
          If i=g.ctrl And (w.Train(i)->control And auto) Then col=&H80ff80  'Color of auto controlled train
          If w.Train(i)->control And brake Then col=&Hff8080  'Color of braking train
          waggon.tr=w.Train(i)->tr
          waggon.ps=w.Train(i)->ps
          waggon.control=none
          waggon.sp=-10*m  'Distance between waggons (Loc size)
          For j=1 To w.Train(i)->waggons*2+1
            moveTrain(@waggon,0) '"walk on track" to next waggon (middle car)
            If j=1 Then
              'Locomotive (Distance)
              
              
              If (waggon.tr->visible) Then
              DrawModel(w.Train(i)->x,w.Train(i)->y, _
              waggon.x,waggon.y,w.model(w.Train(i)->pic)->mBuild,v,col,1,dwin)
              EndIf
              
                            waggon.sp=-6*m  'Distance between waggons
            Else
              If (j Mod 2)=0 Then
                wagx=waggon.x
                wagy=waggon.y
                waggon.sp=-10*m  'waggon length
              Else
                'Waggon
                
                If (waggon.tr->visible) Then
                DrawModel(wagx,wagy, waggon.x,waggon.y, _
                w.model(w.Train(i)->WaggonPic)->mBuild, v, &H80e080,1,dwin)
                EndIf
                                waggon.sp=-6*m  'Distance between waggons
              EndIf
            EndIf
          Next
        EndIf
      EndIf
      If (i Mod TimeChecks)=0 AndAlso Not InTime(20) Then
        Exit For
      EndIf
    Next
    
    'First draw all items
    For i=1 To MaxItems
      If w.Items(i)<>0 Then 
        ShowItem(w.Items(i),dwin)
        If (i Mod TimeChecks)=0 AndAlso Not InTime(10) Then
          Exit For
        EndIf
      EndIf
    Next
    
    'Then check if one item is selected
    'If yes, bring it to front (draw it again)
    If (show And 2) Then 
      For i=1 To MaxItems
        If w.Items(i)<>0 Then 
          If i=g.ItemSel Then
            g.ItemSelName=w.Model(w.Items(i)->build)->mName+" ("+str(i)+")"
            ShowItem(w.Items(i),dwin)
            Circle dwin,(xcoor(w.Items(i)->a.x),ycoor(w.Items(i)->a.y)),20,&Hffff00
            Circle dwin,(xcoor(w.Items(i)->b.x),ycoor(w.Items(i)->b.y)),20,&H0080ff
            GfxPrint6 g.ItemSelName,xcoor(w.Items(i)->a.x)-(3*Len(g.ItemSelName)),ycoor(w.Items(i)->a.y)-30,&HFFFFFF,dwin
          Else
            g.ItemSelName=""
          EndIf
        EndIf
      Next
      
      'Draw turnout switches
      If v.Scale<10000 Then
        For i=1 To MaxTurnouts
          If w.Turnouts(i)<>0 Then
            If visible(w.Turnouts(i)->SwitchCoor.x, _
                w.Turnouts(i)->SwitchCoor.y) Then
              Line dwin,(xcoor(w.Turnouts(i)->pr1->x),ycoor(w.Turnouts(i)->pr1->y)) _
                - (xcoor(w.Turnouts(i)->pr2->x),ycoor(w.Turnouts(i)->pr2->y)),&Hc0c000
              If w.Turnouts(i)->pr1->LockedBy<>NULL _
              OrElse w.Turnouts(i)->pr2->LockedBy<>NULL _
              OrElse w.Turnouts(i)->pf1->LockedBy<>NULL _
              OrElse w.Turnouts(i)->pf2->LockedBy<>NULL _
              Then
                'red: turnout is locked
                Circle dwin,(xcoor(w.Turnouts(i)->SwitchCoor.x), _
                  ycoor(w.Turnouts(i)->SwitchCoor.y)),2+1*m/v.Scale,&Hff0000
              ElseIf w.Turnouts(i)->turn=2 Then
                'blue: turnout is crossed
                Circle dwin,(xcoor(w.Turnouts(i)->SwitchCoor.x), _
                  ycoor(w.Turnouts(i)->SwitchCoor.y)),2+1*m/v.Scale,&H0000ff
              Else
                'green: turnout forward (not crossed)
                Circle dwin,(xcoor(w.Turnouts(i)->SwitchCoor.x), _
                  ycoor(w.Turnouts(i)->SwitchCoor.y)),2+1*m/v.Scale,&H00ff00
              EndIf            EndIf
          EndIf
        Next
      EndIf
      
      'Draw selected Tracksegment highlighted
      If g.EditTrkPtr<>0 Then
        DrawSubTrackHighlighted(g.EditTrkPtr,&Hffff00,dwin)
      EndIf
      
      If g.EditTrkPtrA<>0 Then
        DrawSubTrackHighlighted(g.EditTrkPtrA,&Hff0000,dwin)
      EndIf
      
    EndIf
    
    'draw train number on top
    For i=1 To maxtrains
      'check if train exist (pointer<>0)
      If w.Train(i)<>0 Then
        'check if train is visible
        If (IsTrainVisible(i)>0) Then
          'Print train number
          If (show And 4) AndAlso (w.Train(i)->tr->visible) Then
            If v.WinX>200 Then
              GFXPrint(Str$(i),xcoor(w.Train(i)->x)+8,ycoor(w.Train(i)->y)-16,&Hffffff,dwin)
            Else
              GFXPrint6(Str$(i),xcoor(w.Train(i)->x)+4,ycoor(w.Train(i)->y)-12,&Hffffff,dwin)
            EndIf
          EndIf
        EndIf
      EndIf
    Next
    
    
    '################################################
    '## Main (Print status info)
    '################################################
    

    'Print help/info screen
    If show And 1 Then

      
      If helpman AndAlso _
        tsmode<>ts_edittrack Then
        
        If wv.gridon Then 
          If v.Scale>100000 Then
            s="(10km)"
          ElseIf v.Scale>10000 Then
            s="(1km)"
          ElseIf v.Scale>1000 Then
            s="(100m)"
          ElseIf v.Scale>100 Then
            s="(10m)"
          Else
            s="(1m)"
          EndIf
        Else
          s=""
        EndIf
        
        
        DrawTextBottomL(dwin, _
           "Train Simulator  proog.de|"_
          +"-------------------------|"_
          +"F1-F4 Display|"_
          +"  F5  Read Messages|"_
          +"  F8  Setup|"_
          +" 0-9  Watch Train #|"_
          +"  g   Show Grid "+s+"|"_
          +"  m   BG-Bitmap|"_
          +"  M   Map|"_
          +" SPC  Menu Fade|"_
          +"  d   Debug View|"_
          +" CURS Move Camera|"_
          +" PAGE Up/Dn Zoom|"_
          +"|"_
          +" ESC  End Program|"_
          , helpman, &H104020 _
        )

        If ShowTrainStops Then
          j=0
          s=""
          For i=0 To maxtrains
            If (w.train(i)<>0) AndAlso (w.train(i)->sp=0) Then
              s=s+"Train ("+str(i)+") Stopped.|"
              j=j+1
              if j>=ShowTrainStops then exit for
            EndIf
          next i
          
          DrawTextBottomC(dwin,s,helpman,&H104020)
        EndIf


        'context sensitive display
        If g.trksel Then
          'Track is selected, can start editor
          'GfxPrint6 "*Track "+str(g.trksel)+"*",0,0*8+402,&HFFFFFF,dwin
          DrawTextBottomR(dwin, _
             "Track "+str(g.trksel)+" "+w.Start(g.trksel)->TName+"|"_
            +"-------------------------|"_
            +"MOUSE Move|"_
            +"  n   Place New Train|"_
            +"  i   Input Track Name|"_
            +"  e   Track Editor|"_
            +" </>  Rotate|"_
            +" DEL  Delete Track|"_
            , helpman, &H104020 _
          )

        ElseIf g.ItemSel Then
          'Item is selected, can move
          DrawTextBottomR(dwin, _
             "Item "+str(g.ItemSel)+" "+_
                    w.Model(w.Items(g.ItemSel)->build)->mName+"|"_
            +"-------------------------|"_
            +"MOUSE Move/Size|"_
            +" +/-  Change Model|"_
            +" DEL  Delete|"_
            , helpman, &H104020 _
          )

        ElseIf g.ctrl Then
          'Train is selected, can be controlled
          If Int(w.Train(g.ctrl)->sp*2/10)=0 Then
            If w.Train(g.ctrl)->control And crash Then
              s="Train Crashed"     'train has crashed
            ElseIf "s"=w.Train(g.ctrl)->tr->TName Then
              s="Rail Station"      'train stops at station, maybe make some money
              
'              g.money+=(1000*w.Train(g.ctrl)->waggons)
'              message("Train "+w.Train(g.ctrl)->TName+" delivers " _
'                      +str(1000*w.Train(g.ctrl)->waggons)+"$")
                      
            Else
              s="Stop On Track"     'train stops on track
            EndIf
          Else
            s=""
          EndIf
          
          Dim As String s1, s2

          s1=""
          If g.ctrl<>0 Then
            If w.Train(g.ctrl)->control And auto Then
              s1=" (A)"
              If w.Train(g.ctrl)->control And brake Then
                s1=" (S)"
              EndIf
            EndIf
            s2="(Flags "+hex(w.Train(g.ctrl)->control,4)+")"
          EndIf
          
          DrawTextBottomR(dwin, _
             "Train("+str(g.ctrl) _
            +")" _
            +" "+left(w.Train(g.ctrl)->TName,15)+"|"_
            +"Speed "+str(Int(w.Train(g.ctrl)->sp/SpeedScale))+" "+s+"|" _
            +"-------------------------|"_
            +"  a   Assist Driver"+s1+"|"_
            +"  s   Stop - "+s2+"|"_
            +"  l   Speed Fwd|"_
            +"  k   Speed Rev|"_
            +" u/U  Next/Prev Turnout|"_
            +" TAB  Select Next Train|"_
            +"  w   Watch Train|"_
            +"  t   Watch Track|"_
            , helpman, &H104020 _
          )
          
        Else
          'Nothing selected
          DrawTextBottomR(dwin, _
             "MOUSE |"_
            +"CLICK Select Train|"_
            +"DRAG  Move Map|"_
            +"WHEEL Zoom|"_
            +"-------------------------|"_
            +"MX="+str(Menu.MouseX)+", MY="+str(Menu.MouseY)_
                  +", MO="+str(Menu.MouseOver)+"|"_
            +"CMD: "+Menu.cmd+", "+str(Menu.CmdState)+"|"_
            , helpman, &H104020 _
          )
        EndIf


      EndIf
    EndIf
    
    
    
    'Print track editor info
    If show And 8 Then
    
      'If Left$(ks,3)=K_edittrackFlag Then
      
      If tsmode=ts_edittrack Then
      
        If g.trksel Then
          'Track is selected, can start editor
          'GfxPrint6 "*Track "+str(g.trksel)+"*",0,0*8+402,&HFFFFFF,dwin
          DrawTextBottom(dwin, _
             "Edit Track "+str(g.trksel)+" "+w.Start(g.trksel)->TName+"|"_
            +"-------------------------|"_
            +"MOUSE Move Track|"_
            +" +/-  Move Track Cursor|"_
            +" o/c  Open/Close Track|"_
            +" INS  New Track Segment|"_
            +" DEL  Delete Track Seg.|"_
            +" l/r  Track Left/Right|"_
            +" L/R  Sharp Left/Right|"_
            +"  f   Track Forward|"_
            +"  s   Rail Station|"_
            +"  i   Input Signal F/R|"_
            +"  v   invisible on/off|"_
            +" 0-9  Length|"_
            +"  e   End Track Editor|"_
            , 320, 479, helpman, &H104020 _
          )

        ElseIf g.ItemSel Then
          'Item is selected, can move
          DrawTextBottom(dwin, _
             "*Item "+str(g.ItemSel)+" "+_
                    w.Model(w.Items(g.ItemSel)->build)->mName+"|"_
            +"-------------------------|"_
            +"MOUSE Move/Size|"_
            +" +/-  Change Model|"_
            +" DEL  Delete|"_
            , 320, 479, helpman, &H104020 _
          )

        ElseIf g.ctrl Then
          'Train is selected, can be controlled
          If Int(w.Train(g.ctrl)->sp*2/10)=0 Then
            If "s"=w.Train(g.ctrl)->tr->TName Then
              s="Rail Station"      'train stops at station, maybe make some money
            Else
              s="Stop On Track"     'train stops on track
            EndIf
          Else
            s=""
          EndIf
          
          
          DrawTextBottom(dwin, _
             "*Train "+str(g.ctrl)+" "+_
                    w.model(w.Train(g.ctrl)->pic)->mName+"|"_
            +"Speed "+str(Int(w.Train(g.ctrl)->sp*2/10))+" "+s+"|"_
            +"-------------------------|"_
            +"  s   Stop|"_
            +"  a   Auto Halt|"_
            +" l/.  Speed Fwd|"_
            +" k/,  Speed Rev|"_
            +" u/U  Next/Prev Turnout|"_
            +" TAB  Select Next Train|"_
            +"  w   Watch Train|"_
            +"  t   Watch Track|"_
            +" +/-  Train Length|"_
            , 320, 479, helpman, &H104020 _
          )
          
        Else
          'Nothing selected
          DrawTextBottom(dwin, _
             "*MOUSE |"_
            +"CLICK To Select|"_
            +"DRAG  Move Map|"_
            +"WHEEL Zoom|"_
            , 320, 479, helpman, &H104020 _
          )
        EndIf
      




        If (g.EditTrkBasePtr<>NULL) AndAlso (g.EditTrkPtr<>NULL) Then
          s="** Track editor **|" _
           +"-------------------------|" _
           +" "+g.EditTrkBasePtr->tname+"|" _
           +" #="+Str$(Int(g.EditTrkPtr->tnum)) _
           +" Name="+g.EditTrkPtr->tname+"|"_
           +" length="+Str$(Int(g.EditTrkPtr->length/m*10)/10) _
           +" distance="+Str$(Int(g.EditTrkPtr->distance/m*10)/10)+"|"_
           +" Turnout="+Str$(Abs(g.EditTrkPtr->turn<>0))+"|" _
           +" X="+Str$(Int(g.EditTrkPtr->x/m*10)/10)+"|" _
           +" Y="+Str$(Int(g.EditTrkPtr->y/m*10)/10)+"|" _
           +" Z="+Str$(Int(g.EditTrkPtr->z/m*10)/10)+"|" _
           +" <="+Str$(Int(g.EditTrkPtr->angle))+"|" _
           +" Fwd Signal="+g.EditTrkPtr->SigF+"|" _
           +" Rev Signal="+g.EditTrkPtr->SigR+"|"
        Else
          s="  ** Track editor **|" _
           +"-------------------------|" _
           +"  No Track selected!|||"
        EndIf  


        DrawTextBottom(dwin,s,0,158,helpman,&H104020)

        
        
'        Line dwin,(0,48)-(28*6+4,162),&H104020,BF
'        GfxPrint6 "** Track editor ** ["+ks+"]",2,50,&HFFFFFF,dwin
'        
'        If g.EditTrkBasePtr<>0 Then
'          GfxPrint6 " "+g.EditTrkBasePtr->tname _
'            ,2,60,&HFFFFFF,dwin
'        EndIf
'        
'        'Draw selected Tracksegment highlighted
'        
'        If g.EditTrkPtr<>0 Then
'          GfxPrint6 " #="+Str$(Int(g.EditTrkPtr->tnum))+ _
'            " Name="+g.EditTrkPtr->tname _
'            ,2,80,&Hffffff,dwin
'          GfxPrint6 " length="+Str$(Int(g.EditTrkPtr->length/m*10)/10)+ _
'            " distance="+Str$(Int(g.EditTrkPtr->distance/m*10)/10) _
'            ,2,90,&Hffffff,dwin
'          GfxPrint6 " Turnout="+Str$(Abs(g.EditTrkPtr->turn<>0)) _
'            ,2,100,&Hffffff,dwin
'          GfxPrint6 " X="+Str$(Int(g.EditTrkPtr->x/m*10)/10) _
'            ,2,110,&Hffffff,dwin
'          GfxPrint6 " Y="+Str$(Int(g.EditTrkPtr->y/m*10)/10) _
'            ,2,120,&Hffffff,dwin
'          GfxPrint6" Z="+Str$(Int(g.EditTrkPtr->z/m*10)/10)+ _
'            " <="+Str$(Int(g.EditTrkPtr->angle)) _
'            ,2,130,&Hffffff,dwin
'
'          GfxPrint6 " Fwd Signal="+g.EditTrkPtr->SigF _
'            ,2,140,&Hffffff,dwin
'          GfxPrint6 " Rev Signal="+g.EditTrkPtr->SigR _
'            ,2,150,&Hffffff,dwin
'
''          GfxPrint6 " Fwd Signal="+Str$(g.EditTrkPtr->sigf.Signaltype)+ _
''            " SigValue="+Str$(g.EditTrkPtr->sigf.SignalValue) _
''            ,2,140,&Hffffff,dwin
''          GfxPrint6 " Rev Signal="+Str$(g.EditTrkPtr->sigr.Signaltype)+ _
''            " SigValue="+Str$(g.EditTrkPtr->sigr.SignalValue) _
''            ,2,150,&Hffffff,dwin
'
'        EndIf  
  
      EndIf

    EndIf


    '################################################
    '## OHD - FPS and Scale
    '################################################

    
    If show And 2 AndAlso ohdfps Then
      If ohdfps=1 Then
        Line dwin,(0,0)-(v.WinX-1,49),&H104020,BF
      EndIf
      
      'Reserve Time values of RT10<10 are critical and cause flicker on screen
      'Set FrameRate to lower values or reduce usage of background bitmaps
      GfxPrint6 "FPS="+Str$(Int(g.Fps))_
        +" RT10="+str(Int(g.ReserveTime*10)) _
        +" Scale=1/"+Str$(v.Scale) _
        ,0,0,&Hffffff,dwin

'      GfxPrint6 "FPS="+Str$(Int(g.Fps))+"/"+Str$(Int(g.Fps0))_
'        +" Skip="+Str$(g.SkipFrame)_
'        +" AvTm="+Str$(Int(g.AvgTime*1000))_
'        +" AMax="+Str$(Int(g.AvgMax*1000))_
'        +" Scale=1/"+Str$(v.Scale) _
'        ,0,0,&Hffffff,dwin
      
'        GfxPrint6 "FPS="+Str$(Int(g.Fps*10)/10)+"/"+Str$(Int(g.Fps0*10)/10)+ _
'          " Skip="+Str$(g.SkipFrame)+" Scale=1/"+Str$(v.Scale) _
'          ,0,0,&Hffffff,dwin

'        'Scale
'
'        GfxPrint6 "Scale=1/"+Str$(v.Scale) _
'          ,0,0,&Hffffff,dwin


      'GPS
      
      Dim As String gpsxh, gpsxl, gpsyh, gpsyl
      
      gpsxh=Str$(Int(p2wx(v.WinX/2)/m))
      gpsxl=right(gpsxh,3)
      gpsxh=left(gpsxh,Len(gpsxh)-3)
      gpsyh=Str$(Int(p2wy(v.WinY/2)/m))
      gpsyl=right(gpsyh,3)
      gpsyh=left(gpsyh,Len(gpsyh)-3)
      GfxPrint6 "GPS X="+gpsxh+"."+gpsxl+ _    
                " Y="+gpsyh+"."+gpsyl,320,0,&Hffffff,dwin      
      
      If ShowMoney Then
        GfxPrint6 "Money=$"+MoneyStr(g.Money), _
          320,10,&Hffffff,dwin
'        GfxPrint6 "Money=$"+MoneyStr(g.Money) _
'          +" SimF="+left(str(g.FramesTotal),10),320,10,&Hffffff,dwin
      EndIf
      
      If w.Train(g.ctrl)<>NULL Then
        GfxPrint6 _
          "  === Train ===" _
          ,320,20,&Hffffff,dwin      
        GfxPrint6 _
          "Trip="+str(Int(w.Train(g.ctrl)->TripOdo/1000))+"m " _
          +"Odo="+str(w.Train(g.ctrl)->Odometer)+"km" _
          ,320,30,&Hffffff,dwin
        If ShowMoney Then
          GfxPrint6 _
            "$"+MoneyStr(w.Train(g.ctrl)->Credit) _
            +" Damage="+MoneyStr(w.Train(g.ctrl)->Damage) _
            ,320,40,&Hffffff,dwin
        EndIf      EndIf
      
    EndIf
    
    If g.ctrl>0 Then: i=g.ctrl: Else: i=1: EndIf
    
    If show And 2 AndAlso ohdfps Then
      If g.ctrl<>0 Then
        s="Train="+Str$(g.ctrl)+" Sp="+fstr((w.Train(g.ctrl)->sp)/SpeedScale,3,1)+ _
          " Track="+w.Train(g.ctrl)->tr->mytrack->tName+ _
          ", "+str(w.Train(g.ctrl)->tr->tNum)+ _
          ", ("+w.Train(g.ctrl)->tr->tName+")"
        If (wv.cam<>0) And (wv.cam<>g.ctrl) Then
          s=s+" (Watch train "+Str$(wv.cam)+")"
        EndIf
        GfxPrint6 s,0,10,&Hffffff,dwin
      EndIf
    EndIf
    

'    If show And 1 AndAlso v.gridon Then
'      If helpman Then
'        i=390
'      Else
'        i=v.WinY-10
'      EndIf
'      
'      If v.Scale>100000 Then
'        GfxPrint6 "Grid 10km",0,i,&Hffffff,dwin
'      ElseIf v.Scale>10000 Then
'        GfxPrint6 "Grid 1km",0,i,&Hffffff,dwin
'      ElseIf v.Scale>1000 Then
'        GfxPrint6 "Grid 100m",0,i,&Hffffff,dwin
'      ElseIf v.Scale>100 Then
'        GfxPrint6 "Grid 10m",0,i,&Hffffff,dwin
'      Else
'        GfxPrint6 "Grid 1m",0,i,&Hffffff,dwin
'      EndIf
'      
'    EndIf
    
    
    If show And 1 Then
      If MsgCnt>0 Then
        MsgCnt-=1
        TextBox(NewMessage, dwin)
'        Line dwin,(32,v.WinY/2-16-80)-(v.WinX-30,v.WinY/2+20-80),&H104020,BF
'        GfxPrint6 NewMessage,(v.WinX-6*Len(NewMessage))/2,v.WinY/2-80,&Hffffff,dwin
      EndIf
    EndIf
    
'    If (Menu.MouseOver=0) AndAlso (g.Mousehold>g.Fps/click) Then
'      'hide mouse on drag
'      'GfxPrint6 "* DRAG *",8,32,&Hffffff,dwin
'      setmouse ,,0
'    Else
'      setmouse ,,1
'    EndIf
    
    'change mouse cursor to indicate drag
    
    If (Menu.MouseOver=0) AndAlso (g.Mousehold>g.Fps/click) Then
      'hide mouse on drag
      'GfxPrint6 "* DRAG *",8,32,&Hffffff,dwin
      MouseCursor=0
    Else
      MouseCursor=1
    EndIf
    
    setmouse ,,MouseCursor
    
    If v.Debug Then
      
      'draw border (debug/test)
#ifdef ShowVisBorder
      If VisBorder>0 Then
        Line dwin,(0-wv.VisBorderX, 0-wv.VisBorderY)- _
        (v.WinX+wv.VisBorderX, v.WinY+wv.VisBorderY), _
        &H808080,b,&b10000001100000011000000110000001
      EndIf
#endif
      
'      GfxPrint6 "Mouse: X="+Str$(p2wx(g.Mousex)/m)+"/"+Str$(p2wx(g.Mousex)/m), _
'      0,64,&Hffffff,dwin
'      s="...... X="+Str$(g.Mousex)+" Y="+Str$(g.Mousey)+" W="+Str$(g.Mousewh)+" B="+Str$(g.Mousebt)
'      If g.Mousehold>g.Fps/click Then
'        s=s+" *DRAG*"
'      EndIf
'      GfxPrint6 s,0,72,&Hffffff,dwin
       
       'Center cross
       Line dwin,(v.WinX/2,v.WinY/2-10)-(v.WinX/2,v.WinY/2-5),&Ha0a000
       Line dwin,(v.WinX/2,v.WinY/2+10)-(v.WinX/2,v.WinY/2+5),&Ha0a000
       Line dwin,(v.WinX/2-10,v.WinY/2)-(v.WinX/2-5,v.WinY/2),&Ha0a000
       Line dwin,(v.WinX/2+10,v.WinY/2)-(v.WinX/2+5,v.WinY/2),&Ha0a000
       
'      If g.trksel<>0 Then
'        s="Track........:"+w.Start(g.trksel)->tname+" "+ _
'          Str$(w.Start(g.trksel)->length/m)+" Meter"
'        GfxPrint6 s,0,80,&Hffffff,dwin
'          
'        s="Coor X="+Str$(w.Start(g.trksel)->x/m)+ _
'          " Y="+Str$(w.Start(g.trksel)->y/m)+ _
'          " Z="+Str$(w.Start(g.trksel)->z/m)+ _
'          " <="+Str$(w.Start(g.trksel)->angle)
'        GfxPrint6 s,0,88,&Hffffff,dwin
'        
'        s="Track size"+Str$(i)+ _
'          " X:"+Str$(Int(w.Start(g.trksel)->dimension.minx/m))+ _
'          "-"+Str$(Int(w.Start(g.trksel)->dimension.maxx/m))+ _
'          " Y:"+Str$(Int(w.Start(g.trksel)->dimension.miny/m))+ _
'          "-"+Str$(Int(w.Start(g.trksel)->dimension.maxy/m))
'        GfxPrint6 s,0,96,&Hffffff,dwin
'        GfxPrint6 "Track build..:"+Str$(w.Start(g.trksel)->build) _
'          ,0,104,&Hffffff,dwin
'      EndIf
      
'      If g.ctrl<>0 Then
'        If w.Train(i)<>0 Then
'          GfxPrint6 "Current track segment" _
'          ,0,112,&Hffffff,dwin
'          s="Tr."+Str$(w.Train(i)->tr->TNum)+ _
'            " N="+Str$(w.Train(i)->tr->tname)+ _
'            " X="+Str$(Int(w.Train(i)->tr->x/m))+ _
'            " Y="+Str$(Int(w.Train(i)->tr->y/m))+ _
'            " L="+Str$(w.Train(i)->tr->length/m)+ _
'            " <="+Str$(Int(w.Train(i)->tr->angle))
'          GfxPrint6 s,0,120,&Hffffff,dwin
'                
'          s="Distance="+Str$(w.Train(i)->tr->distance/m)+ _
'            " SigF="+w.Train(i)->tr->SigF+ _
'            " SigR="+w.Train(i)->tr->SigR
'          GfxPrint6 s,0,128,&Hffffff,dwin
'          
'          s="Turn="+Str$(w.Train(i)->tr->turn<>0)
'          GfxPrint6 s,0,136,&Hffffff,dwin
'        EndIf
'      EndIf

'      If g.ItemSel<>0 Then
'        GfxPrint6 "Item........:"+Str$(g.ItemSel),0,144,&Hffffff,dwin
'      EndIf
      
'      For i=1 To 10
'        If w.Train(i)<>0 Then
'          If i=g.ctrl Then: s="* ": Else: s="- ": EndIf
'          If i=v.cam Then: s=s+"w ": Else: s=s+"- ": EndIf
'          s=s+"T:"+Str$(i)+" Sp="+Str$(Int(w.Train(i)->sp*2)/10)
'          If IsTrainVisible(i) Then
'            s=s+" */"
'          Else
'            s=s+" ./"
'          EndIf
'          If visrect(w.Train(i)->tr->mytrack->dimension.minx, _
'             w.Train(i)->tr->mytrack->dimension.maxx, _
'             w.Train(i)->tr->mytrack->dimension.miny, _
'             w.Train(i)->tr->mytrack->dimension.maxy) Then
'             s=s+"* "
'           Else
'             s=s+". "
'           EndIf
'          GfxPrint6 s,0,144+i*8,&Hffffff,dwin
'        EndIf
'      Next
      
    EndIf

'    If v.Debug Then
'      'Print function key code
'      If Left$(ks,1)=Chr(255) Then
'        GfxPrint6 "FnKey="+Mid$(ks,2,1)+Str$(ks[1]),v.WinX/2,8,&Hffffff,dwin
'      Else
'        GfxPrint6 "Key="+ks,v.WinX/2,8,&Hffffff,dwin
'      EndIf
'    EndIf

'    'display graphics on screen
'    Put(0,0),dwin,PSet

End Sub









'################################################
'## Train Simulator engine
'################################################

'Sub ts_help
'  Dim As Integer i, j, lefttab
'  
'  'Cls
'  Line win480,(0,0)-(v.WinX-1,v.WinY-1),&H106010,BF
'  i=0   'pixel line counter
'  j=10   'pixels per line
'  lefttab=(v.WinX _
'       -Len("=====================================================================")*6)/2
'  GfxPrint6 "=====================================================================",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "Train Simulator "+Version,lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "=====================================================================",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "Program:     (C) oog / proog.de 2011, License: GPL V3",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "Subs, Libs:  Fragmeister, FreeBASIC Forum",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "Maps:        (C) OpenStreetMap contributors, CC-BY-SA ",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "UK Maps:     Contains Ordnance Survey data",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "             (C) Crown copyright and database right 2010. ",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "=====================================================================",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "Homepage: proog.de",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "Forum:    freebasic.net/forum Index -> Projects -> Train Simulator",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "          http://freebasic.net/forum/viewtopic.php?t=18185",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "=====================================================================",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "This program is free software: you can redistribute it and/or modify",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "it under the terms of the GNU General Public License as published by",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "the Free Software Foundation, either version 3 of the License, Or",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "(at your option) any later version.",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "This program is distributed in the hope that it will be useful,",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "but WITHOUT ANY WARRANTY; without even the implied warranty of",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "GNU General Public License for more details.",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "You should have received a copy of the GNU General Public License",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "along with this program.  If not, see <http://www.gnu.org/licenses/>.",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "=====================================================================",lefttab,i,&Hffffff,win480:i=i+j
'  GfxPrint6 "",lefttab,i,&Hffffff,win480:i=i+j
'  Put (0,0),win480,alpha,200
'End Sub

Const PageStart="  ("
Const ManualLines=155
Dim Shared As String*69 ManualText(ManualLines)=>{ _
  "Train Simulator "+Version,_
  "=====================================================================",_
  "",_
  "Program:     (C) oog / proog.de 2011, License: GPL V3",_
  "Subs, Libs:  Fragmeister, FreeBASIC Forum",_
  "Maps:        (C) OpenStreetMap contributors, CC-BY-SA ",_
  "UK Maps:     Contains Ordnance Survey data",_
  "             (C) Crown copyright and database right 2010. ",_
  "",_
  "=====================================================================",_
  "",_
  "Homepage: proog.de",_
  "Forum:    freebasic.net/forum Index -> Projects -> Train Simulator",_
  "          http://freebasic.net/forum/viewtopic.php?t=18185",_
  "",_
  "=====================================================================",_
  "",_
  "This program is free software: you can redistribute it and/or modify",_
  "it under the terms of the GNU General Public License as published by",_
  "the Free Software Foundation, either version 3 of the License, Or",_
  "(at your option) any later version.",_
  "",_
  "This program is distributed in the hope that it will be useful,",_
  "but WITHOUT ANY WARRANTY; without even the implied warranty of",_
  "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the",_
  "GNU General Public License for more details.",_
  "",_
  "You should have received a copy of the GNU General Public License",_
  "along with this program.  If not, see <http://www.gnu.org/licenses/>.",_
  "",_
  "=====================================================================",_
  "  Select manual page: (0) (1) (2) ... (ESC)",_
  _
  _
  _
  "  (1) - Overview",_
  "=====================================================================",_
  "The Menu:",_
  "  Use the 'Space' key to view/hide the menu",_
  "  The buttons at the top line select a menu (Control, Files...)",_
  "  Press the button again to flip the menu in/out",_
  " ",_
  "Quickstart:",_
  "* Press 1, 2, 3,... to select different trains",_
  "* Press PgUp / PgDn or use mouse wheel to change zoom level",_
  "* Press 's' to stop the selected train",_
  "* Press ',' or '.' to change speed",_
  "* Press cursor keys to move map or hold mouse button and drag",_
  "* Press 'd' to switch debug view on/off",_
  "* Press 'g' to switch grid on/off",_
  " ",_
  "=====================================================================",_
  "  Select manual page: (0) (1) (2) ... (ESC)",_
  _
  _
  _
  "  (2) - Train Control",_
  "=====================================================================",_
  "Menu buttons:",_
  "  left/right black arrow: select train +/-",_
  "  up/down green arrow...: change speed in steps by 5 or 10",_
  "  ctrl turn f/r.........: switch front or rear turnout from train",_
  "  watch train...........: set camera to controlled train",_
  "                          (watch and control can be independant)",_
  "  center track..........: set camera to track of controlled train",_
  "  stop/slow/fast........: set train speed level",_
  "  AutoPilot.............: train stops in station and handle signals",_
  "  Autostart.............: train start from station after a while, if",_
  "                          train has been stopped by the autopilot",_
  "Select a train:",_
  "  click on train, hit key '1'..'0', press TAB / Shift+TAB",_
  "=====================================================================",_
  "  Select manual page: (0) (1) (2) ... (ESC)",_
  _
  _
  _
  "  (3) - Files",_
  "=====================================================================",_
  "Menu buttons:",_
  "  Load .......: load a saved world, enter folder name, default='data'",_
  "  Save .......: save actual world",_
  "  Import Track: import a single track to center of screen",_
  "  Export Track: export a selected track, enter filename",_
  "  New World ..: clear the actual world",_
  "",_
  "The load-function expect three files:",_
  "  tsini.txt: global setup for screen, zoom, framerate and",_
  "             optional background bitmap files",_
  "  tsmod.txt: description of vector models 'items' like trains or",_
  "             buildings",_
  "  tsdat.txt: the world (tracks, turnouts, trains, placed items",_
  "             and actual setup)",_
  "",_
  "Tracks can be exported as separate files. Imported tracks are placed",_
  "to the center of the screen. Tracks can be imported many times as",_
  "a copy.",_
  "",_
  "File formats are XML-inpired. They are completely readable and can",_
  "be posted to a forum to share the worlds with others.",_
  "",_
  "Train Simulator files are read from and stored into folders, which",_
  "name you can specify. Please note, that the Train Simulator does not",_
  "save bitmap files. They should be copied manually.",_
  "",_
  "=====================================================================",_
  "  Select manual page: (0) (1) (2) ... (ESC)",_
  _
  _
  _
  "  (4) - Build Track",_
  "=====================================================================",_
  "Build an example track:",_
  "* Click 'Place Track' to activate new track placement, then click at",_
  "  a free area on the map to place a new track",_
  "* Press '+' to move the cursor to the first track segment",_
  "* Press 'INS' 5 times to insert forward tracks",_
  "* Press 'l' or 'r' for a left or right turn",_
  "* Press 'INS' 32 times for a 180° turn",_
  "* Press 'r' or 'l' to change from turn into forward direction",_
  "* Press 'INS', then 's' to build a railroad station",_
  "* Press 'INS' 3 times, then add another 180° turn to close the track",_
  "* After the second turn, switch to forward direction and press 'INS'",_
  "  until you nearly closed the track",_
  "* Select 'Tools' menu an press 'Close Track' to connect both sides",_
  "  If you are asked to select a track first, click on the track root,",_
  "  the circle at the first track segment. Blue color indicates",_
  "  selection.",_
  "* Zoom out until you see the station, then select the station track",_
  "  segment by clicking at the small green circle.",_
  "",_
  "Place a train at the selected track segment",_
  "* Select 'Build' menu and click at 'New Item/Train'",_
  "  If a track segment is selected, a new train will be placed there.",_
  "* Select 'Control' Menu and check, if the train is running.",_
  "* Select 'Build' Menu, then select the train by mouse click, then",_
  "  adjust the length by pressing '+'/'-'. ",_
  "* Change train model 'Model +/-' and 'Car Model +/-'",_
  "* Click 'Train Name' and change Name to 'My first Train'",_
  "=====================================================================",_
  "  Select manual page: (0) (1) (2) ... (ESC)",_
  _
  _
  _
  "  (5) - Build",_
  "=====================================================================",_
  "Menu buttons:",_
  "  New Item/Train: Click, to activate item placement. The button keeps",_
  "                  locked, until you place an item or push the button",_
  "                  again. Click on the map to place the item.",_
  "                  To place a train, first select a track segment",_
  "                  (Menu Track), then click this button.",_
  "  Delete .......: Delete selected item or train (crashed train)",_
  "  Model +/- ....: Change train or item model. Press +/- instead.",_
  "  Car Model +/- : Change train car model",_
  "  Train Name ...: Enter/Change train name (Backspace key supported)",_
  "",_
  "  Select an item: Click at the yellow point",_
  "                  (press 'd' for debug view)",_
  "  Move an item .: Drag the yellow point (use arrow keys to move map)",_
  "  Scale an item : Drag the blue point",_
  "=====================================================================",_
  "  Select manual page: (0) (1) (2) ... (ESC)"_
  }


Sub ts_manualpage(page As Integer)
  Dim As Integer i, j, lefttab, start, count
  
  i=-1   'pixel line counter
  j=10   'pixels per line
  start=page
  count=0
  lefttab=(v.WinX-Len(ManualText(0))*6)/2
  
  If page>0 Then
    Do
      i+=1
      If PageStart=left(ManualText(i),3) Then start-=1
    Loop Until (i>=ManualLines) _
    OrElse (start=0)
  Else
    i=0
  EndIf
  
  If i<ManualLines-2 Then
    start=i'+1
    
    For i=start+1 To ManualLines
      If PageStart=left(ManualText(i),3) Then Exit For
      count=i
    Next i
    
    'Cls
    Line win480,(0,0)-(v.WinX-1,v.WinY-1),&H106010,BF
'    GfxPrint6 ":(Page "+str(page) _
'             +", start="+str(start) _
'             +", count="+str(count) _
'             +"):",lefttab,(-2)*j+(v.WinY-32*j)/2,&Hffffff,win480
    For i=start To count
      GfxPrint6 ManualText(i),lefttab,(i-start)*j+(v.WinY-32*j)/2,&Hffffff,win480
    Next i
'    Put (0,0),win480,alpha,200
    Put (1,1),win480,PSet
  EndIf
End Sub


'Sub ts_help
'  ts_manualpage(0)
'End Sub


Sub ts_manual
  Dim As String k
  Dim As Integer p
  
  Select Case Menu.MName
  Case MenuName1
    p=2
  Case MenuName2
    p=3
  Case MenuName3
    p=4
  Case MenuName4
    p=5
'  Case MenuName5
'    p=6
  Case Else
    p=0
  End Select
  
  ts_manualpage(p)
  Do
    Sleep 10
    k=inkey
    p=InStr("0123456789",k)
    If p Then
      ts_manualpage(p-1)
    EndIf
  Loop Until k=k_esc
End Sub


Sub ts_DrawController(v As TView, win As Any Ptr)
  Dim Train As PTrain
  Dim As Integer i, j, l
  Dim As Integer px,py,pxm,pym
  Dim As String s, st1, st2
  Const wd=120
  Const ht=24
  
  'Draw Controller
  '121*24 pixel
  
  px=(v.WinX-wd)/2
  pxm=px+wd
  py=v.WinY-ht
  pym=py+ht
  
  If Controller _
  OrElse ((g.ctrl<>0) AndAlso (w.Train(g.ctrl)->AutoSpeed<>0)) _
  OrElse ((g.ctrl<>0) AndAlso (w.Train(g.ctrl)->Control And Brake)) _
  Then
    i=1+((v.WinX-103)\2)
    Line win,(px,py) - (pxm,pym), MenuBGCol, BF
    
    If g.ctrl<>0 Then
      Train=w.Train(g.ctrl)
      If Controller _
      OrElse (Train->AutoSpeed <> 0) _
      OrElse (Train->Control And Brake) _
      Then
      
      
        s= str(g.ctrl)+" "+left(Train->TName,10) _
        +" "+str(Int(Train->sp/SpeedScale))
        If Train->AutoSpeed <> 0 Then
          s=s+"/"+str(Int(Train->AutoSpeed))
        EndIf
        
        
        If Train->AutoSpeed=0 Then
          st1=" "+str(g.ctrl)+" "
          st2=" "+str(Int(Train->sp/SpeedScale))+" "
        Else
          st1=" "+str(g.ctrl)+" "
          st2=" "+str(Int(Train->sp/SpeedScale)) _
             +"/"+str(Int(Train->AutoSpeed))+" "
        EndIf
        l=Len(st1)+Len(st2)
        s= st1+left(Train->TName+"                    ",20-l)+st2
        
        GfxPrint6 s,px,py+1,MenuFGCol,win
        
        'speed bar
        j=Train->sp*50/SpeedScale/Train->MaxSpeed
        Line win,(i+51,py+12) - (i+51+j,pym-4), &H202080, BF
        
        'autospeed bar
        If Train->AutoSpeed<>0 Then
          j=Train->AutoSpeed*50/Train->MaxSpeed
          Line win,(i+51,py+14) - (i+51+j,pym-6), &H20a020, BF
        EndIf
        
        'speed bar outline
        Line win,(i,py+10) - (i+102,pym-2), MenuFGCol, B
        'zero line
        Line win,(i+51,py+10) - (i+51,pym-2), MenuFGCol, B
      EndIf
    Else
      GfxPrint6 "No Train Control Set",px,py+1,MenuFGCol,win
'      GfxPrint6 "********************",px,py+11,MenuFGCol,win
    EndIf
  EndIf
End Sub


Sub ts_helpman
  helpman=helpman+1
  If helpman=3 Then
    helpman=0
  EndIf
End Sub


Sub ts_ohd
  OhdFps=OhdFps+1
  If OhdFps=3 Then
    OhdFps=0
  EndIf
End Sub


Sub ts_Controller
  Controller=(Controller=0)
End Sub


Sub ts_TrainCarAdd
  If g.ctrl<>0 Then
    If w.train(g.ctrl)->waggons < MaxCars Then
      w.train(g.ctrl)->waggons +=1
    EndIf
  EndIf
End Sub


Sub ts_TrainCarSub
  If g.ctrl<>0 Then
    If w.train(g.ctrl)->waggons >0 Then
      w.train(g.ctrl)->waggons -=1
    EndIf
  EndIf
End Sub


Sub ts_TrainPicNext
  'Menu train control
  If g.ctrl<>0 Then
    LogFile("Set Train+ from "+str(w.train(g.ctrl)->pic))
    Do
      w.train(g.ctrl)->pic +=1
      If w.train(g.ctrl)->pic = MaxModels Then w.train(g.ctrl)->pic=0
    Loop Until w.model(w.train(g.ctrl)->pic)<>NULL _
    OrElse w.train(g.ctrl)->pic=1
    LogFile("  to "+str(w.train(g.ctrl)->pic))
  EndIf
End Sub


Sub ts_TrainPicPrev
  'Menu train control
  If g.ctrl<>0 Then
    LogFile("Set Train- from "+str(w.train(g.ctrl)->pic))
    Do
      w.train(g.ctrl)->pic -=1
      If w.train(g.ctrl)->pic = 0 Then w.train(g.ctrl)->pic=MaxModels
    Loop Until w.model(w.train(g.ctrl)->pic)<>NULL _
    OrElse w.train(g.ctrl)->pic=1
    LogFile("  to "+str(w.train(g.ctrl)->pic))
  EndIf
End Sub


Sub ts_CarPicNext
  'Menu train control
  If g.ctrl<>0 Then
    LogFile("Set CAR+ from "+str(w.train(g.ctrl)->waggonpic))
    Do
      w.train(g.ctrl)->waggonpic +=1
      If w.train(g.ctrl)->waggonpic = MaxModels Then w.train(g.ctrl)->waggonpic=0
    Loop Until w.model(w.train(g.ctrl)->waggonpic)<>NULL _
    OrElse w.train(g.ctrl)->waggonpic=1
    LogFile("  to "+str(w.train(g.ctrl)->waggonpic))
  EndIf
End Sub


Sub ts_CarPicPrev
  'Menu train control
  If g.ctrl<>0 Then
    LogFile("Set CAR- from"+str(w.train(g.ctrl)->waggonpic))
    Do
      w.train(g.ctrl)->waggonpic -=1
      If w.train(g.ctrl)->waggonpic = 0 Then w.train(g.ctrl)->waggonpic=MaxModels
    Loop Until w.model(w.train(g.ctrl)->waggonpic)<>NULL _
    OrElse w.train(g.ctrl)->waggonpic=1
    LogFile("  to "+str(w.train(g.ctrl)->waggonpic))
  EndIf
End Sub


  'switch turnout from selected train


Sub ts_SwitchTunoutNext
  'switch turnout in front of train
  Dim As Integer i
  
  If g.ctrl<>0 Then
    i=0
    g.EditTrkPtr=w.Train(g.ctrl)->tr
    Do
      i+=1
      If g.EditTrkPtr->turn<>0 Then
        SwitchTurnout(g.EditTrkPtr->turn)
        Exit Do
      EndIf
      g.EditTrkPtr=g.EditTrkPtr->pf
    Loop Until (i>100) Or (g.EditTrkPtr=0)
    g.EditTrkPtr=0
  EndIf
End Sub


Sub ts_SwitchTurnoutPrev
  'switch turnout behind train
  Dim As Integer i
  
  If g.ctrl<>0 Then
    i=0
    g.EditTrkPtr=w.Train(g.ctrl)->tr
    Do
      i+=1
      If g.EditTrkPtr->turn<>0 Then
        SwitchTurnout(g.EditTrkPtr->turn)
        Exit Do
      EndIf
      g.EditTrkPtr=g.EditTrkPtr->pr
    Loop Until (i>100) Or (g.EditTrkPtr=0)
    g.EditTrkPtr=0
  EndIf
End Sub


Sub ts_SwitchTunoutFwd
  'switch turnout in forward direction
  If g.ctrl<>0 Then
    If w.Train(g.ctrl)->sp>=0 Then
      ts_SwitchTunoutNext
    Else
      ts_SwitchTurnoutPrev
    EndIf
  EndIf
End Sub


Sub ts_SwitchTurnoutRev
  If g.ctrl<>0 Then
    If w.Train(g.ctrl)->sp<0 Then
      ts_SwitchTunoutNext
    Else
      ts_SwitchTurnoutPrev
    EndIf
  EndIf
End Sub




'################################################
'## Train Simulator engine - Track Editor
'################################################




Sub ts_te_start
  'if no track selected, auto select last track
'  If g.trksel=0 Then
'    g.TrkSel=MaxTracks
'    Do
'      g.TrkSel-=1
'    Loop Until (g.TrkSel=0) OrElse (w.start(g.TrkSel)<>NULL)
'  EndIf
  'set editor to selected track
  If g.trksel<>0 Then
    If g.EditTrk=0 Then
      g.EditTrk=g.trksel
      g.EditTrkBasePtr=w.Start(g.trksel)
      g.EditTrkPtr=g.EditTrkBasePtr->last
    EndIf
    If g.EditTrkPtr<>NULL Then
      ScreenCenter(g.EditTrkPtr->x,g.EditTrkPtr->y,v)
    EndIf
  EndIf
'  ActivateTrack(w.Start(g.trksel))
End Sub


  '## Track editor (2):
  '## Functions that need a valid v.EditTrkPtr


Sub ts_te_Name
  Dim As String s, n
  
  If w.Start(g.EditTrk)<>NULL Then
    n=w.Start(g.EditTrk)->TName
    s=InputBox("Enter Track Name",n)
    If n<>s Then
      If GetTrackIndex(s) Then
        MessageBox("Error: Name already exist.")
      Else
        w.Start(g.EditTrk)->TName=s
      EndIf
    EndIf
  EndIf
End Sub


Sub ts_te_SelectTrack
  'edit track (select next track)
  'Reset LockedBy-Flag
  If (g.EditTrkPtr<>NULL) _
  AndAlso (g.EditTrkPtr<>g.EditTrkBasePtr->start) _
  Then
    g.EditTrkPtr=g.EditTrkBasePtr->start
  Else
    Do
      g.EditTrk+=1
      If g.EditTrk=MaxTracks Then
        g.EditTrk=1
      EndIf
    Loop Until (w.Start(g.EditTrk)<>NULL) _
    OrElse (g.EditTrk=1)
    
    If (w.Start(g.EditTrk)<>NULL) Then
      g.TrkSel=g.EditTrk
      g.EditTrkBasePtr=w.Start(g.EditTrk)
      g.EditTrkPtr=g.EditTrkBasePtr->start
      ScreenCenter(g.EditTrkPtr->x,g.EditTrkPtr->y,v)
    EndIf
  EndIf
End Sub


'Sub ts_te_SelectPrevTrack
'  'edit track (select next track)
'  'Reset LockedBy-Flag
'  Do
'    g.EditTrk-=1
'    If g.EditTrk<=0 Then
'      g.EditTrk=MaxTracks
'    EndIf
'  Loop Until (w.Start(g.EditTrk)<>NULL) _
'  OrElse (g.EditTrk=1)
'  
'  If (w.Start(g.EditTrk)<>NULL) Then
'    g.TrkSel=g.EditTrk
'    g.EditTrkBasePtr=w.Start(g.EditTrk)
'    g.EditTrkPtr=g.EditTrkBasePtr->start
'    ScreenCenter(g.EditTrkPtr->x,g.EditTrkPtr->y,v)
'  EndIf
'End Sub
'
'
'Sub ts_te_SelectNextTrack
'  'edit track (select next track)
'  'Reset LockedBy-Flag
'  Do
'    g.EditTrk+=1
'    If g.EditTrk=MaxTracks Then
'      g.EditTrk=1
'    EndIf
'  Loop Until (w.Start(g.EditTrk)<>NULL) _
'  OrElse (g.EditTrk=1)
'  
'  If (w.Start(g.EditTrk)<>NULL) Then
'    g.TrkSel=g.EditTrk
'    g.EditTrkBasePtr=w.Start(g.EditTrk)
'    g.EditTrkPtr=g.EditTrkBasePtr->start
'    ScreenCenter(g.EditTrkPtr->x,g.EditTrkPtr->y,v)
'  EndIf
'End Sub


Sub ts_te_InstallTurnout
  Dim As Integer i
  
  'first check, if turnout exist and must be removed
  If (g.EditTrkPtr->Turn<>0) Then
    'Cleanup
    'find the corresponding turnout slot
    i=0
    Do
      i+=1
      
   'fxm speedup trick (using OrElse)
    Loop Until  (i>MaxTurnouts) _
        OrElse ((w.Turnouts(i)<>NULL) AndAlso (w.Turnouts(i)->pr1=g.EditTrkPtr)) _
        OrElse ((w.Turnouts(i)<>NULL) AndAlso (w.Turnouts(i)->pr2=g.EditTrkPtr))
         
    If i<>MaxTurnouts Then
      'Now i is the number of the slot
      message("Remove turnout "+Str$(i))
      RemoveTurnout(i)
    Else
      message("Error: could not locate turnout slot.")
    EndIf
    g.EditTrkPtrA=0
  EndIf
  'Check if pointer A point to track
  If (g.EditTrkPtrA<>0) Then
    'Check if tracks have a turnout
    'Remove pointer A if same as Edit Pointer
    If (g.EditTrkPtrA=g.EditTrkPtr) Then
      g.EditTrkPtrA=NULL
    ElseIf (g.EditTrkPtrA->Turn=0) And (g.EditTrkPtr->Turn=0) Then
      'Create a new turnout
      'find a free turnout slot
      i=0
      Do
        i+=1
      Loop Until (w.Turnouts(i)=0) OrElse (i>MaxTurnouts)
      If i<>MaxTurnouts Then
        'Now free turnout slot is i
        
        'check if tracks are parallel
        'angle ist an integer (0..511)
        Dim As Integer ang1, ang2
        
        ang1=Abs(g.EditTrkPtrA->angle - g.EditTrkPtr->angle) And 511
        If ang1<256 Then
          ang2=ang1
        Else
          ang2=512-ang1
        EndIf
        
        If ang2 <= MinAngle Then 'angle between tracks
          message("Create turnout "+Str$(i))
          w.Turnouts(i)=AddTurnout(g.EditTrkPtrA, g.EditTrkPtr)
          g.EditTrkPtrA=0
        Else
          message("Error: Tracks not parallel ("_
          +str(g.EditTrkPtrA->angle)+" <> "_
          +str(g.EditTrkPtr->angle)+") angle512="_
          +str(ang2))
        EndIf
      EndIf
    EndIf
  Else
    'set pointer A
    g.EditTrkPtrA=g.EditTrkPtr
  EndIf
End Sub


Sub ts_te_Next
  'edit track (select next)
  'Reset LockedBy-Flag
  If g.EditTrkPtr->pn<>0 Then
    g.EditTrkPtr=g.EditTrkPtr->pn
    ScreenCenter(g.EditTrkPtr->x,g.EditTrkPtr->y,v)
    g.EditTrkPtr->LockedBy=NULL
  Else
    g.EditTrkPtr=g.EditTrkPtr->mytrack->start
    ScreenCenter(g.EditTrkPtr->x,g.EditTrkPtr->y,v)
    g.EditTrkPtr->LockedBy=NULL
  EndIf
End Sub


Sub ts_te_prev
  'edit track (select previous)
  'Reset LockedBy-Flag
  If g.EditTrkPtr->pr<>0 Then
    If g.EditTrkPtr->pr->pn=g.EditTrkPtr Then
      g.EditTrkPtr=g.EditTrkPtr->pr
      ScreenCenter(g.EditTrkPtr->x,g.EditTrkPtr->y,v)
      g.EditTrkPtr->LockedBy=NULL
    Else
      g.EditTrkPtr=g.EditTrkPtr->mytrack->last
      ScreenCenter(g.EditTrkPtr->x,g.EditTrkPtr->y,v)
      g.EditTrkPtr->LockedBy=NULL
    EndIf
  Else
    g.EditTrkPtr=g.EditTrkPtr->mytrack->last
    ScreenCenter(g.EditTrkPtr->x,g.EditTrkPtr->y,v)
    g.EditTrkPtr->LockedBy=NULL
  EndIf
End Sub




Sub ts_te_SetStation
  'edit track (set track station)
  If g.EditTrk<>0 Then
    g.EditTrkPtr->tname="s"'+Mid$(g.EditTrkPtr->tname,2,1)
    g.EditTrkPtr->SigF="stop"
    g.EditTrkPtr->SigR="stop"
    ActivateTrack(w.Start(g.EditTrk))
  EndIf
End Sub

'Sub ts_te_SetForward
'  'edit track (set track forward)
'  If g.EditTrk<>0 Then
'    g.EditTrkPtr->tname="f"+Mid$(g.EditTrkPtr->tname,2,1)
'    ActivateTrack(w.Start(g.EditTrk))
'  EndIf
'End Sub
'
'Sub ts_te_SetLeft
'  'edit track (set track left)
'  If g.EditTrk<>0 Then
'    g.EditTrkPtr->tname="l"+Mid$(g.EditTrkPtr->tname,2,1)
'    ActivateTrack(w.Start(g.EditTrk))
'  EndIf
'End Sub
'
'Sub ts_te_SetRight
'  'edit track (set track right)
'  If g.EditTrk<>0 Then
'    g.EditTrkPtr->tname="r"+Mid$(g.EditTrkPtr->tname,2,1)
'    ActivateTrack(w.Start(g.EditTrk))
'  EndIf
'End Sub
'
'Sub ts_te_SetSharpLeft
'  'edit track (set track left)
'  If g.EditTrk<>0 Then
'    g.EditTrkPtr->tname="L"+Mid$(g.EditTrkPtr->tname,2,1)
'    ActivateTrack(w.Start(g.EditTrk))
'  EndIf
'End Sub
'
'Sub ts_te_SetSharpRight
'  'edit track (set track right)
'  If g.EditTrk<>0 Then
'    g.EditTrkPtr->tname="R"+Mid$(g.EditTrkPtr->tname,2,1)
'    ActivateTrack(w.Start(g.EditTrk))
'  EndIf
'End Sub
'




Sub ts_TrackTurnLeft
  'edit track (track turn left)
  Dim As String c1, c2
  Dim As Integer i
  
  If g.EditTrk<>0 Then
    c1=left(g.EditTrkPtr->tname,1)
    If Len(g.EditTrkPtr->tname)=2 Then
      c2=right(g.EditTrkPtr->tname,1)
    Else
      c2=""
    EndIf
    
    i=InStr("fr",c1)
    If i>0 Then
      c1=mid("lf",i,1)
    EndIf
    
'    i=InStr("lfrR",c1)
'    If i>0 Then
'      c1=mid("Llfr",i,1)
'    EndIf
    
    g.EditTrkPtr->tname=c1+c2
    ActivateTrack(w.Start(g.EditTrk))
  EndIf
End Sub


Sub ts_TrackTurnRight
  'edit track (track turn right)
  Dim As String c1, c2
  Dim As Integer i
  
  If g.EditTrk<>0 Then
    c1=left(g.EditTrkPtr->tname,1)
    If Len(g.EditTrkPtr->tname)=2 Then
      c2=right(g.EditTrkPtr->tname,1)
    Else
      c2=""
    EndIf
    
    i=InStr("lf",c1)
    If i>0 Then
      c1=mid("fr",i,1)
    EndIf
    
'    i=InStr("Llfr",c1)
'    If i>0 Then
'      c1=mid("lfrR",i,1)
'    EndIf
    
    g.EditTrkPtr->tname=c1+c2
    ActivateTrack(w.Start(g.EditTrk))
  EndIf
End Sub





Sub ts_te_SetVisible
  'edit track (set track visible)
  If g.EditTrk<>0 Then
    g.EditTrkPtr->visible=(g.EditTrkPtr->visible=0)
    ActivateTrack(w.Start(g.EditTrk))
  EndIf
End Sub

Sub ts_te_SetEnd
  'edit track (set track end segment)
  If g.EditTrk<>0 Then
    g.EditTrkPtr->tname="e"
    ActivateTrack(w.Start(g.EditTrk))
  EndIf
End Sub


Sub ts_te_NewTrackMP
  'create a new track at mouse pointer
  Dim As Integer i
  
'  If (tsmode=ts_edittrack) AndAlso ("y"=YesOrNoBox("Place new Track?")) Then
  If (tsmode=ts_edittrack) Then
    'set i to next free track pointer
    i=1
    Do While (W.Start(i)<>NULL)
      i+=1
    Loop
    
    If i<MaxTracks Then
      'build initial track
      w.Start(i)=BuildTrack("Track"+str(i), "effe", _
        p2wx(g.MouseX), p2wy(g.MouseY), 0, 0)
      
      g.trksel=i
      g.EditTrk=g.trksel
      g.EditTrkBasePtr=w.Start(g.trksel)
      g.EditTrkPtr=g.EditTrkBasePtr->last->pr
    EndIf
  EndIf
  
End Sub


Sub PlaceInsertTrack(T As PTrack, Tr As PTrack)
  Dim As Integer lng, x, y, z, angle
  '(2) Coordinates
  lng=25*m
  angle=T->angle
  If Left$(Tr->TName,1)="L" Then
    angle=angle-MinAngle*2
  EndIf
  If Left$(Tr->TName,1)="R" Then
    angle=angle+MinAngle*2
  EndIf
  If Left$(Tr->TName,1)="l" Then
    angle=angle-MinAngle
  EndIf
  If Left$(Tr->TName,1)="r" Then
    angle=angle+MinAngle
  EndIf
  If Left$(Tr->TName,1)="s" Then
    lng=25*5*m
  EndIf
  If Left$(Tr->TName,1)="e" Then
    lng=1
  EndIf
  If Len(Tr->TName)=2 Then
    lng=InStr("0123456789",Right$(Tr->TName,1))*lng/5
  EndIf
  
  
  angle=angle And &H1ff
  x=T->x+Cos(angle*pi/256)*lng
  y=T->y+Sin(angle*pi/256)*lng
  z=T->z
  
  Tr->angle=angle
  Tr->x=T->x
  Tr->y=T->y
  Tr->z=T->z
  'save actual coordinates
  T->angle=angle
  T->x=x
  T->y=y
  T->z=z
End Sub


Sub InsertTrack(T As PTrack)
  Dim As PTrack tnew, tp
  Dim As Integer n
  
  'track segment number
  n=T->TNum+1
  
  tnew=New TTrack
  tnew->mytrack=T->mytrack
  If T->Tname="s" Then
    'replace stration by forward track
    tnew->Tname="f"
    LogFile("InsertTrack s->f")
  Else
    tnew->Tname=T->Tname
    LogFile("InsertTrack "+T->Tname)
  EndIf
  
  'insert tnew behind t
  'link front of new track
  tnew->pn=T->pn
  tnew->pf=T->pf
  If T->pn<>NULL Then T->pn->pr=tnew
  'link rear of new track
  tnew->pr=T
  T->pn=tnew
  T->pf=tnew
  
  tnew->visible=T->visible
  tnew->SigF=""
  tnew->SigR=""
  
  'renumber track segments until end of track
  tp=tnew
  tp->TNum=n
  Do
    tp=tp->pn
    n+=1
    tp->TNum=n
  Loop Until (tp=NULL) OrElse (tp->tName="e")
  
  PlaceInsertTrack(T, tnew)
    
End Sub



Sub BuildDefaultModels
Dim As Integer i,j

  'Build Items for drwaing (Train, House)
  i=0
  
  'Building: House
  i+=1
  w.model(i)=new TModel
  w.model(i)->mType="building"
  w.model(i)->mName="House"
  w.model(i)->mBuild= _
     VectZoomOut(255) _
      +VectColor(&H800000) _
      +VectLine(0,-125,0,125) _
    +VectEndZoom _
    +VectZoomIn(255) _
      +VectColor(&H801515) _
      +VectFBox(-50,-125,50,125) _
    +VectEndZoom _
    +VectZoomIn(80) _
      +VectColor(1) _
      +VectLine(-50,-125,0,-100) _
      +VectLine(0,-100,50,-125) _
      +VectLine(-50,125,0,100) _
      +VectLine(0,100,50,125) _
      +VectLine(0,-100,0,100) _
    +VectEndZoom _
    +VectZoomIn(10) _
      +VectColor(&H808000) _
      +VectFCircle(25,0,10) _    +VectEndZoom _
  
  
  'Building: Station
  i+=1
  w.model(i)=new TModel
  w.model(i)->mType="building"
  w.model(i)->mName="Rail Station"
  w.model(i)->mBuild= _
     VectZoomOut(255) _
      +VectColor(&H800000) _
      +VectLine(0,-50,0,50) _
    +VectEndZoom _
    +VectZoomIn(255) _
      +VectColor(&H404030) _
      +VectFBox(-50,-125,50,125) _
      +VectColor(&H801515) _
      +VectFBox(-20,-50,20,50) _
    +VectEndZoom _
    +VectZoomIn(80) _
      +VectColor(1) _
      +VectLine(-20,-50,0,-40) _
      +VectLine(0,-40,20,-50) _
      +VectLine(-20,50,0,40) _
      +VectLine(0,40,20,50) _
      +VectLine(0,-40,0,40) _
    +VectEndZoom _
  
  
  'Building: Tunnel
  i+=1
  w.model(i)=new TModel
  w.model(i)->mType="building"
  w.model(i)->mName="Tunnel"
  w.model(i)->mBuild= _
     VectZoomOut(255) _
      +VectColor(&H800000) _
      +VectLine(0,-50,0,50) _
    +VectEndZoom _
    +VectZoomIn(255) _
      +VectColor(GroundColor) _
      +VectFBox(-75,-50,75,100) _
      +VectColor(&H404030) _
      +VectFBox(-75,-100,75,-50) _
      +VectFBox(-100,-125,-75,100) _
      +VectFBox(100,-125,75,100) _
      +VectFTri(-75,-100,-25,-100,-75,-125) _
      +VectFTri(75,-100,25,-100,75,-125) _
    +VectEndZoom _
  
  
  'forest
  i+=1
  w.model(i)=new TModel
  w.model(i)->mType="vegetation"
  w.model(i)->mName="Forest"
  w.model(i)->mBuild=VectColor(&H008040)
  For j=1 To 10
    w.model(i)->mBuild=w.model(i)->mBuild+VectFCircle(20+Rnd*210-125,25+Rnd*200-125,5+Rnd*10)
  Next
  w.model(i)->mBuild=w.model(i)->mBuild+VectColor(&H00a030)
  For j=1 To 10
    w.model(i)->mBuild=w.model(i)->mBuild+VectFCircle(20+Rnd*210-125,25+Rnd*200-125,5+Rnd*10)
  Next
  
  
  i+=1
  w.model(i)=new TModel
  w.model(i)->mType="train"
  w.model(i)->mName="Short Rail"
  w.model(i)->mBuild= _
     VectVehicle _
    +VectColor(&H404040) _
    +VectFBox(-120,-55,120,55) _
    +VectZoomIn(255) _
      +VectColor(&H505050) _
      +VectFBox(-80,-10,80,10) _
    +VectEndZoom _
    +VectZoomIn(40) _
      +VectColor(&H707070) _
      +VectFBox(-43,-55,-37,55) _
      +VectFBox(37,-55,43,55) _
    +VectEndZoom _
    +VectZoomIn(30) _
      +VectColor(&H404040) _
      +VectFCircle(-47,0,3) _
      +VectFCircle(-33,0,3) _
      +VectFCircle(33,0,3) _
      +VectFCircle(47,0,3) _
    +VectEndZoom _
  
  
  'Trains
  i+=1
  w.model(i)=new TModel
  w.model(i)->mType="train"
  w.model(i)->mName="Red Train"
  w.model(i)->mBuild= _
     VectVehicle _
    +VectZoomOut(200) _
      +VectColor(1) _
      +VectLine(-20,-70,20,70) _
      +VectLine(20,-70,-20,70) _
    +VectEndZoom _
    +VectZoomIn(200) _
      +VectColor(&H802020) _
      +VectFBox(-20,-65,20,65) _
    +VectEndZoom _
    +VectZoomOut(100) _
      +VectColor(1) _
      +VectFCircle(0,0,30) _
    +VectEndZoom _
    +VectZoomIn(100) _
      +VectColor(1) _
      +VectFBox(-18,-10,18,30) _
      +VectColor(&H202060) _
      +VectLine(-15,-55,-15,-15) _
      +VectLine(15,-55,15,-15) _
      +VectLine(-15,35,-15,55) _
      +VectLine(15,35,15,55) _
    +VectEndZoom _
    +VectZoomIn(40) _
      +VectColor(&H303030) _
      +VectFCircle(-15,-68,3) _
      +VectFCircle(15,-68,3) _
      +VectFCircle(-15,68,3) _
      +VectFCircle(15,68,3) _
    +VectEndZoom _
  
  
  i+=1
  w.model(i)=new TModel
  w.model(i)->mType="train"
  w.model(i)->mName="Blue Train"
  w.model(i)->mBuild= _
     VectVehicle _
    +VectZoomOut(200) _
      +VectColor(1) _
      +VectLine(-20,-70,20,70) _
      +VectLine(20,-70,-20,70) _
    +VectEndZoom _
    +VectZoomIn(200) _
      +VectColor(&H4040e0) _
      +VectFBox(-20,-68,20,68) _
    +VectEndZoom _
    +VectZoomOut(100) _
      +VectColor(1) _
      +VectFCircle(0,0,30) _
    +VectEndZoom _
    +VectZoomIn(100) _
      +VectColor(1) _
      +VectFCircle(0,0,15) _
      +VectColor(&H405050) _
      +VectFTri(-18,-60,0,-65,18,-60) _  
      +VectFTri(-18,-60,-18,-55,0,-60) _  
      +VectFTri(18,-60,18,-55,0,-60) _  
      +VectFTri(-18,60,0,65,18,60) _  
      +VectFTri(-18,60,-18,55,0,60) _  
      +VectFTri(18,60,18,55,0,60) _  
      +VectColor(&H202060) _
      +VectLine(-15,-40,-15,40) _
      +VectLine(15,-40,15,40) _
    +VectEndZoom _
    +VectZoomIn(60) _
      +VectColor(&H4040e0) _
      +VectFTri(-20,-68,20,-68,0,-73) _
      +VectFTri(-20,68,20,68,0,73) _
    +VectEndZoom _
    +VectZoomIn(40) _
      +VectColor(&H303030) _
      +VectFCircle(-15,-73,3) _
      +VectFCircle(15,-73,3) _
      +VectFCircle(-15,73,3) _
      +VectFCircle(15,73,3) _
    +VectEndZoom _
  
  
  i+=1
  w.model(i)=new TModel
  w.model(i)->mType="train"
  w.model(i)->mName="Orange Train"
  w.model(i)->mBuild= _
     VectVehicle _
    +VectZoomOut(200) _
      +VectColor(1) _
      +VectLine(-20,-70,20,70) _
      +VectLine(20,-70,-20,70) _
    +VectEndZoom _
    +VectZoomIn(200) _
      +VectColor(&Hc09000) _
      +VectFBox(-20,-65,20,65) _
    +VectEndZoom _
    +VectZoomOut(100) _
      +VectColor(1) _
      +VectFCircle(0,0,30) _
    +VectEndZoom _
    +VectZoomIn(100) _
      +VectColor(1) _
      +VectFBox(-18,-10,18,30) _
      +VectColor(&H202060) _
      +VectLine(-15,-55,-15,-15) _
      +VectLine(15,-55,15,-15) _
      +VectLine(-15,35,-15,55) _
      +VectLine(15,35,15,55) _
    +VectEndZoom _
    +VectZoomIn(40) _
      +VectColor(&H303030) _
      +VectFCircle(-15,-68,3) _
      +VectFCircle(15,-68,3) _
      +VectFCircle(-15,68,3) _
      +VectFCircle(15,68,3) _
    +VectEndZoom _
  
  
  i+=1
  w.model(i)=new TModel
  w.model(i)->mType="train"
  w.model(i)->mName="Green Train"
  w.model(i)->mBuild= _
     VectVehicle _
    +VectZoomOut(200) _
      +VectColor(1) _
      +VectLine(-20,-70,20,70) _
      +VectLine(20,-70,-20,70) _
    +VectEndZoom _
    +VectZoomIn(200) _
      +VectColor(&H208040) _
      +VectFBox(-20,-68,20,68) _
    +VectEndZoom _
    +VectZoomOut(100) _
      +VectColor(1) _
      +VectFCircle(0,0,30) _
    +VectEndZoom _
    +VectZoomIn(100) _
      +VectColor(&H305040) _
      +VectFBox(-14,-40,14,40) _
      +VectColor(1) _
      +VectFCircle(0,0,15) _
      +VectColor(&H405050) _
      +VectFTri(-18,-60,-2,-65,-2,-60) _
      +VectFTri(-18,-60,-18,-55,-2,-60) _
      +VectFTri(18,-60,2,-65,2,-60) _
      +VectFTri(18,-60,18,-55,2,-60) _
      +VectFTri(-18,60,-2,65,-2,60) _
      +VectFTri(-18,60,-18,55,-2,60) _
      +VectFTri(18,60,2,65,2,60) _
      +VectFTri(18,60,18,55,2,60) _
      +VectColor(&H106010) _
      +VectLine(-15,-40,-15,40) _
      +VectLine(15,-40,15,40) _
    +VectEndZoom _
    +VectZoomIn(60) _
      +VectColor(&H208040) _
      +VectFTri(-20,-68,20,-68,0,-73) _
      +VectFTri(-20,68,20,68,0,73) _
    +VectEndZoom _
    +VectZoomIn(40) _
      +VectColor(&H303030) _
      +VectFCircle(-15,-73,3) _
      +VectFCircle(15,-73,3) _
      +VectFCircle(-15,73,3) _
      +VectFCircle(15,73,3) _
    +VectEndZoom _
  
  
  i+=1
  w.model(i)=new TModel
  w.model(i)->mType="train"
  w.model(i)->mName="Ghost Train"
  w.model(i)->mBuild= _
     VectVehicle _
    +VectZoomOut(200) _
      +VectColor(1) _
      +VectLine(-20,-70,20,70) _
      +VectLine(20,-70,-20,70) _
    +VectEndZoom _
    +VectZoomIn(200) _
      +VectColor(&Hd0d0d0) _
      +VectLine(-20,-68,-20,68) _
      +VectLine(20,-68,20,68) _
    +VectEndZoom _
    +VectZoomOut(100) _
      +VectColor(1) _
      +VectCircle(0,0,30) _
    +VectEndZoom _
    +VectZoomIn(100) _
      +VectColor(1) _
      +VectCircle(0,0,15) _
      +VectColor(&Hd0d0d0) _
      +VectLine(-18,-60,0,-65) _  
      +VectLine(0,-65,18,-60) _
      +VectLine(-18,60,0,65) _
      +VectLine(0,65,18,60) _
      +VectColor(&H101010) _
      +VectLine(-10,50,10,50) _
      +VectFBox(-11,55,-9,45) _
      +VectFBox(11,55,9,45) _
      +VectLine(-10,-50,10,-50) _
      +VectFBox(-9,-55,-11,-45) _
      +VectFBox(9,-55,11,-45) _
      +VectColor(&Ha0a0a0) _
      +VectLine(-15,-40,-15,40) _
      +VectLine(15,-40,15,40) _
    +VectEndZoom _
    +VectZoomIn(60) _
      +VectColor(&Hd0d0d0) _
      +VectLine(-20,-68,0,-73) _
      +VectLine(20,-68,0,-73) _
      +VectLine(-20,68,0,73) _
      +VectLine(20,68,0,73) _
    +VectEndZoom _
    +VectZoomIn(40) _
      +VectColor(&H303030) _
      +VectCircle(-15,-73,3) _
      +VectCircle(15,-73,3) _
      +VectCircle(-15,73,3) _
      +VectCircle(15,73,3) _
    +VectEndZoom _
  
  
  'Train Cars  
  i+=1
  w.model(i)=new TModel
  w.model(i)->mType="traincar"
  w.model(i)->mName="Brown Car"
  w.model(i)->mBuild= _
     VectVehicle _
    +VectZoomOut(200) _
      +VectColor(&H808040) _
      +VectLine(-20,-70,20,70) _
      +VectLine(20,-70,-20,70) _
    +VectEndZoom _
    +VectZoomIn(200) _
      +VectColor(&H808040) _
      +VectFBox(-20,-70,20,70) _
    +VectEndZoom _
    +VectZoomIn(100) _
      +VectColor(&H202020) _
      +VectBox(-15,-50,15,50) _
    +VectEndZoom _
    +VectZoomIn(40) _
      +VectColor(&H303030) _
      +VectFCircle(-15,-73,3) _
      +VectFCircle(15,-73,3) _
      +VectFCircle(-15,73,3) _
      +VectFCircle(15,73,3) _
    +VectEndZoom _
  
  
  i+=1
  w.model(i)=new TModel
  w.model(i)->mType="traincar"
  w.model(i)->mName="White Car"
  w.model(i)->mBuild= _
     VectVehicle _
    +VectZoomOut(200) _
      +VectColor(&Hb0b0b0) _
      +VectLine(-20,-70,20,70) _
      +VectLine(20,-70,-20,70) _
    +VectEndZoom _
    +VectZoomIn(200) _
      +VectColor(&Hb0b0b0) _
      +VectFBox(-20,-70,20,70) _
    +VectEndZoom _
    +VectZoomIn(100) _
      +VectColor(&Hc0c0c0) _
      +VectFBox(-15,-60,15,60) _
      +VectColor(&Hf0f0f0) _
      +VectLine(-15,-60,-15,60) _
      +VectLine(15,-60,15,60) _
    +VectEndZoom _
    +VectZoomIn(40) _
      +VectColor(&H303030) _
      +VectFCircle(-15,-73,3) _
      +VectFCircle(15,-73,3) _
      +VectFCircle(-15,73,3) _
      +VectFCircle(15,73,3) _
    +VectEndZoom _
  
  
  i+=1
  w.model(i)=new TModel
  w.model(i)->mType="traincar"
  w.model(i)->mName="Blue Car"
  w.model(i)->mBuild= _
     VectVehicle _
    +VectZoomOut(200) _
      +VectColor(&H3060a0) _
      +VectLine(-20,-70,20,70) _
      +VectLine(20,-70,-20,70) _
    +VectEndZoom _
    +VectZoomIn(200) _
      +VectColor(&H3060a0) _
      +VectFBox(-20,-70,20,70) _
    +VectEndZoom _
    +VectZoomIn(100) _
      +VectColor(&H203060) _
      +VectBox(-15,-60,15,-30) _
      +VectBox(-15,-15,15,15) _
      +VectBox(-15,30,15,60) _
    +VectEndZoom _
    +VectZoomIn(40) _
      +VectColor(&H303030) _
      +VectFCircle(-15,-73,3) _
      +VectFCircle(15,-73,3) _
      +VectFCircle(-15,73,3) _
      +VectFCircle(15,73,3) _
    +VectEndZoom _
  
  
  i+=1
  w.model(i)=new TModel
  w.model(i)->mType="traincar"
  w.model(i)->mName="Grey Car"
  w.model(i)->mBuild= _
     VectVehicle _
    +VectZoomOut(200) _
      +VectColor(&H808080) _
      +VectLine(-20,-70,20,70) _
      +VectLine(20,-70,-20,70) _
    +VectEndZoom _
    +VectZoomIn(200) _
      +VectColor(&H808080) _
      +VectFBox(-20,-70,20,70) _
    +VectEndZoom _
    +VectZoomIn(100) _
      +VectColor(&H506050) _
      +VectFBox(-15,-60,15,-10) _
      +VectFBox(-15,10,15,60) _
    +VectEndZoom _
    +VectZoomIn(40) _
      +VectColor(&H303030) _
      +VectFCircle(-15,-73,3) _
      +VectFCircle(15,-73,3) _
      +VectFCircle(-15,73,3) _
      +VectFCircle(15,73,3) _
    +VectEndZoom _
  
  
  i+=1
  w.model(i)=new TModel
  w.model(i)->mType="traincar"
  w.model(i)->mName="Ghost Car"
  w.model(i)->mBuild= _
     VectVehicle _
    +VectZoomOut(200) _
      +VectColor(&Hd0d0d0) _
      +VectLine(-20,-70,20,70) _
      +VectLine(20,-70,-20,70) _
    +VectEndZoom _
    +VectZoomIn(200) _
      +VectColor(&Hd0d0d0) _
      +VectBox(-20,-70,20,70) _
    +VectEndZoom _
    +VectZoomIn(100) _
      +VectColor(&H101010) _
      +VectLine(-10,50,10,50) _
      +VectFBox(-11,55,-9,45) _
      +VectFBox(11,55,9,45) _
      +VectLine(-10,-50,10,-50) _
      +VectFBox(-9,-55,-11,-45) _
      +VectFBox(9,-55,11,-45) _
    +VectEndZoom _
    +VectZoomIn(40) _
      +VectColor(&H303030) _
      +VectCircle(-15,-73,3) _
      +VectCircle(15,-73,3) _
      +VectCircle(-15,73,3) _
      +VectCircle(15,73,3) _
    +VectEndZoom _
  
End Sub


Function CheckEditTrkPtr As Integer
  If g.EditTrkPtr=NULL Then
    Message("Select track segment first")
  EndIf
  Return g.EditTrkPtr<>NULL
End Function


'Function CheckGEditTrk As Integer
'  If g.EditTrk=0 Then
'    Message("Select track segment first")
'  EndIf
'  Return  g.EditTrk<>0
'End Function


Sub ts_te_insert
  'edit track (insert new track)
  If g.EditTrkPtr<>0 Then
    If g.EditTrkPtr->TName<>"e" Then
      InsertTrack(g.EditTrkPtr)
      'g.EditTrkPtr=g.EditTrkPtr->pn
      If g.EditTrkPtr->pn<>0 Then g.EditTrkPtr=g.EditTrkPtr->pn
      ActivateTrack(w.Start(g.EditTrk))
      ScreenCenter(g.EditTrkPtr->x,g.EditTrkPtr->y,v)
    Else
      Message("Can't insert at end segment")
    EndIf
  EndIf
End Sub


Sub ts_te_delete
  'edit track (delete track)
  Dim As PTrack tp
  Dim As Integer n
  
  If (g.EditTrk<>0) AndAlso (g.EditTrkPtr<>NULL) _
  AndAlso (g.EditTrkPtr->TName<>"e") _
  Then
    If (g.EditTrkPtr->pr<>0) AndAlso (g.EditTrkPtr->pf<>0) _
    AndAlso (g.EditTrkPtr->mytrack->start<>g.EditTrkPtr) _
    AndAlso (g.EditTrkPtr->mytrack->last<>g.EditTrkPtr) _
    Then
      
      'renumber track segments until end of track
      tp=g.EditTrkPtr
      n=tp->TNum
      Do
        tp=tp->pn
        tp->TNum=n
        n+=1
      Loop Until (tp=NULL) OrElse (tp->tName="e")
      
      g.EditTrkPtr->pr->pn=g.EditTrkPtr->pn
      g.EditTrkPtr->pr->pf=g.EditTrkPtr->pf
      g.EditTrkPtr->pf->pr=g.EditTrkPtr->pr
      g.EditTrkPtrA=g.EditTrkPtr
      g.EditTrkPtr=g.EditTrkPtr->pf
      
      'replace "Allocate" by "New" and "DeAllocate" by "Delete" (hint from fxm / FreeBASIC forum)
      'DeAllocate g.EditTrkPtrA
      Delete g.EditTrkPtrA
      g.EditTrkPtrA=0
      g.EditTrkPtr=g.EditTrkPtr->pr
    Else
      Message("Can't insert at end segment")
    EndIf
    ScreenCenter(g.EditTrkPtr->x,g.EditTrkPtr->y,v)
    ActivateTrack(w.Start(g.EditTrk))
  EndIf
End Sub


Sub ts_te_setlength
  'edit track (set length)
  'allowed tracks sre "LlfrR"
  'don't change length of special tracks like station (s)
  If CheckEditTrkPtr Then
    If InStr("LlfrR",left(g.EditTrkPtr->tname,1)) Then
      'check if track is allowed for length change
      If Right$(ks,1)="4" Then
        'default length
        g.EditTrkPtr->tname=Left$(g.EditTrkPtr->tname,1)
      Else
        'different length
        g.EditTrkPtr->tname=Left$(g.EditTrkPtr->tname,1)+Right$(ks,1)
      EndIf
      ActivateTrack(w.Start(g.EditTrk))
    EndIf
  EndIf
End Sub


Sub ts_te_setlonger
  'edit track
  If CheckEditTrkPtr Then
    If Len(g.EditTrkPtr->tname)=1 Then
      g.EditTrkPtr->tname=g.EditTrkPtr->tname+"5"
    ElseIf InStr("012345678",right(g.EditTrkPtr->tname,1)) Then
      g.EditTrkPtr->tname=Left(g.EditTrkPtr->tname,1) _
                         +chr(Asc(right(g.EditTrkPtr->tname,1))+1)
    EndIf
    If right(g.EditTrkPtr->tname,1)="4" Then
      g.EditTrkPtr->tname = left(g.EditTrkPtr->tname,1)
    EndIf
    ActivateTrack(w.Start(g.EditTrk))
  EndIf
End Sub


Sub ts_te_setshorter
  'edit track
  If CheckEditTrkPtr Then
    If Len(g.EditTrkPtr->tname)=1 Then
      g.EditTrkPtr->tname=g.EditTrkPtr->tname+"3"
    ElseIf InStr("123456789",right(g.EditTrkPtr->tname,1)) Then
      g.EditTrkPtr->tname=Left$(g.EditTrkPtr->tname,1) _
                         +chr(Asc(right(g.EditTrkPtr->tname,1))-1)
    EndIf
    If right(g.EditTrkPtr->tname,1)="4" Then
      g.EditTrkPtr->tname = left(g.EditTrkPtr->tname,1)
    EndIf
    ActivateTrack(w.Start(g.EditTrk))
  EndIf
End Sub


'Sub ts_te_setdefaultlength
'  'edit track (set default length)
'  If CheckEditTrkPtr Then
'    g.EditTrkPtr->tname=Left$(g.EditTrkPtr->tname,1)
'    ActivateTrack(w.Start(g.EditTrk))
'  EndIf
'End Sub



  '## Track editor (3):
  '## Other Functions
  
Sub ts_te_signal
  'edit track signal f/r
  
  If tsmode=ts_edittrack _
  AndAlso CheckEditTrkPtr _
  Then
    g.EditTrkPtr->SigF=lcase(InputBox("(1) Input Fwd Signal",g.EditTrkPtr->SigF))
    g.EditTrkPtr->SigR=lcase(InputBox("(2) Input Rev Signal",g.EditTrkPtr->SigR))
  EndIf
End Sub


Sub ts_TrackSigFwd
  'edit track signal
  
  If tsmode=ts_edittrack _
  AndAlso CheckEditTrkPtr _
  Then
    g.EditTrkPtr->SigF=lcase(InputBox("Input Fwd Signal",g.EditTrkPtr->SigF))
  EndIf
End Sub


Sub ts_TrackSigRev
  'edit track signal
  
  If tsmode=ts_edittrack _
  AndAlso CheckEditTrkPtr _
  Then
    g.EditTrkPtr->SigR=lcase(InputBox("Input Rev Signal",g.EditTrkPtr->SigR))
  EndIf
End Sub


Sub ts_TrackPlaceNew
  'edit track, set state
  
  If tsmode=ts_edittrack Then
    g.es=es_PlaceTrack
  EndIf
End Sub


Sub ts_te_TrackEnd
  'edit track (end)
  
  If g.EditTrk<>0 Then
    ActivateTrack(w.Start(g.EditTrk))
    g.EditTrkPtr=0
    g.EditTrk=0
  EndIf
  g.trksel=0
End Sub


'Sub ts_NewTrain
'  If g.trksel<>0 _
'  AndAlso "y"=YesOrNoBox("Place a new Train?") Then
'    'Add train to track
'    NewTrain(g.trksel, 10*SpeedScale, _
'      ModelIndex("Red Train")+g.trksel Mod  4, _
'      ModelIndex("Brown Car")+g.trksel Mod  4, 2)
'  EndIf
'End Sub


Sub ts_TrainName
  Dim As String s, n
  
  If g.ctrl<>0 Then
    'Delete Train
    n=w.Train(g.ctrl)->TName
    s=InputBox("Enter Train Name",n)
    If n<>s Then
      If GetTrainIndex(s) Then
        MessageBox("Error: Name already exist.")
      Else
        w.Train(g.ctrl)->TName=s
      EndIf
    EndIf
  Else
    Message("Select a train first")
  EndIf
End Sub


Sub ts_DeleteTrain
  If g.ctrl<>0 _
  AndAlso "y"=YesOrNoBox("Delete selected train number "+str(g.ctrl)+"?") Then
    'Delete Train
    LogFile("Delete a Train")
    DeleteTrain(g.ctrl)
  EndIf
End Sub


Sub ts_NewItem
  Dim As Integer i
  
  'place new item
  If (g.ItemSel=0) Then
    'Add first item (index i=1)
    i=1
    Do While (w.Items(i)<>0)
      i+=1
    Loop
    If i<MaxItems Then
      w.Items(i)=New TItem
      g.ItemSel=i
      CreateItem(i,p2wx(g.Mousex),p2wy(g.Mousey), _
        p2wx(g.Mousex)+50*m,p2wy(g.Mousey),ItemNum,&Hc00000,ScaleBuilding)
      LogFile("New item "+Str$(i))
    EndIf
  EndIf
End Sub


Sub ts_DeleteItem
  If g.ItemSel<>0 _
  AndAlso "y"=YesOrNoBox("Delete selected Item?") Then
    'Delete Item
    LogFile("")
    LogFile("Delete an Item")
    DeleteItem(g.ItemSel)
  EndIf
End Sub


Sub ts_ItemChangeNext
  If g.ItemSel<>0 Then
    Do
      w.Items(g.ItemSel)->build+=1
      If w.Items(g.ItemSel)->build=MaxModels Then
        w.Items(g.ItemSel)->build=1
      EndIf
    Loop Until w.Model(w.Items(g.ItemSel)->build)<>0 _
    OrElse w.Items(g.ItemSel)->build=1
  EndIf
End Sub


Sub ts_ItemChangePrev
  If g.ItemSel<>0 Then
    Do
      w.Items(g.ItemSel)->build-=1
      If w.Items(g.ItemSel)->build=0 Then
        w.Items(g.ItemSel)->build=MaxModels
      EndIf
    Loop Until w.Model(w.Items(g.ItemSel)->build)<>0 _
    OrElse w.Items(g.ItemSel)->build=1
  EndIf
End Sub


Sub ts_NewTrack
  Dim As Integer i
  
  If "y"=YesOrNoBox("Place new Track at Mouse Pointer?") Then
    LogFile("")
    LogFile("Create a New Track")
    i=0
    Do
      i+=1
    Loop Until (w.Start(i)=0) Or (i>MaxTracks)
    If i<=MaxTracks Then
      w.Start(i)=NewTrack("Track "+Str$(i), _
        p2wx(g.Mousex), p2wy(g.Mousey), 0, 0)
      AddTrack(w.Start(i),"e","")
      AddTrack(w.Start(i),"f","")
      AddTrack(w.Start(i),"e","")
      CloseTrack(w.Start(i))
      ActivateTrack(w.Start(i))
      OpenTrack(w.Start(i))
    EndIf
  EndIf
End Sub


Sub ts_DeleteTrack
  If g.trksel<>0 _
  AndAlso "y"=YesOrNoBox("Delete Track and Trains on Track?") Then
    'Delete track
    LogFile("Delete a Track")
    DeleteTrack(g.trksel)
  EndIf
End Sub


Sub ts_RotateTrackLeft
  If g.trksel<>0 Then
    'rotate
    w.Start(g.trksel)->angle=w.Start(g.trksel)->angle-MinAngle
    
    'avoid negative angles
    Do While w.Start(g.trksel)->angle<0
      w.Start(g.trksel)->angle+=512
    Loop
    
    'avoid angles >511
    w.Start(g.trksel)->angle=w.Start(g.trksel)->angle And 511
    
    ActivateTrack(w.Start(g.trksel))
  EndIf
End Sub


Sub ts_RotateTrackRight
  If g.trksel<>0 Then
    'rotate
    w.Start(g.trksel)->angle=w.Start(g.trksel)->angle+MinAngle
    
    'avoid negative angles
    Do While w.Start(g.trksel)->angle<0
      w.Start(g.trksel)->angle+=512
    Loop
    
    'avoid angles >511
    w.Start(g.trksel)->angle=w.Start(g.trksel)->angle And 511
    
    ActivateTrack(w.Start(g.trksel))
  EndIf
End Sub


Sub ts_DeleteWorld
  Dim As Integer i
  
  'Delete everything in the world
  LogFile("")
  LogFile("Cleanup the World")
  
  'delete all models
  For i=0 To MaxModels
    Delete(w.Model(i))
   w.Model(i)=0
  Next i
  LogFile("  all models deleted")
  
  'delete all items
  For i=0 To MaxItems
    If w.Items(i)<>NULL Then InfoBox("Delete Item "+str(i))
    DeleteItem(i)
  Next i
  LogFile("  all items deleted")
  
  'delete all trains
  For i=1 To MaxTrains
    If w.Train(i)<>NULL Then InfoBox("Delete Train "+str(i))
    DeleteTrain(i)
  Next i
  LogFile("  all trains deleted")
  
  'delete all turnouts
  For i=1 To MaxTurnouts
    If w.Turnouts(i)<>NULL Then InfoBox("Delete Turnout "+str(i))
    RemoveTurnout(i)
  Next i
  LogFile("  all turnouts deleted")
  
  'delete all tracks
  For i=0 to MaxTracks
    If w.Start(i)<>NULL Then InfoBox("Delete Track "+str(i))
    DeleteTrack(i)
  Next i

  'delete all bit header
  For i=0 To MaxMaps
    If w.MapHdr(i)<>NULL Then InfoBox("Delete Bitmap Header "+str(i))
    DELETE w.MapHdr(i)
    w.MapHdr(i)=0
  Next i
  
  'delete all bitmaps
  For i=0 To MaxBmp
    If w.MapData(i)<>NULL Then InfoBox("Delete Bitmap "+str(i))
    DELETE w.MapData(i)
    w.MapData(i)=0
  Next i

  InfoBox("Build default vector models")
  BuildDefaultModels
  
  LogFile("Cleanup the World - done.")
  LogFile("")
  
End Sub




'################################################
'## Map / Bitmap loader
'################################################

Function LoadBmpNew(n As String) As Integer
  Dim As Any Ptr map
  Dim As Integer i, bi
  Dim As Integer mapw, maph, mx, my
  
  LoadBmpNew=1  'return code - error
  
  'set bi to bitmap, if already exist
  bi=0
  For i=1 To MaxBmp
    If w.MapData(i)->filename=n Then
      bi=i
      Exit For
    EndIf
  Next i
  
  'create new memory element, if necessary
  If bi=0 Then
    For i=1 To MaxBmp
      If w.MapData(i)=NULL Then
        bi=i
        Exit For
      EndIf
    Next i
    w.MapData(bi)=new TBmp1023
  EndIf
  
  map = bmp_load(DataPath+n)
  w.MapData(bi)->filename=n
  If map <> NULL Then
    If 0=ImageInfo (map, mapw, maph, , , , ) Then
      If mapw>1024 Then mapw=1024
      If maph>1024 Then maph=1024
      w.MapData(bi)->w=mapw
      w.MapData(bi)->h=maph
      
      For my=0 To maph-1
        For mx=0 To mapw-1
          w.MapData(bi)->data(mx,my)=Point(mx, my, map)
        Next mx
      Next my
    
      ImageDestroy map
      LoadBmpNew=0   'return code - OK
      Cls
      
    EndIf
  Else
    MessageBox("LoadBmp Error: can't load Bitmap "+DataPath+n)
    LogFile("")
    LogFile("LoadBmp Error: can't load Bitmap "+DataPath+n)
    LoadBmpNew=1
  EndIf
End Function


Function PlaceMap(MapName As String, filename As String _
                , x As Integer, y As Integer _
                , scale As Integer _
                , ZoomMin As Integer, ZoomMax As Integer _
                ) As Integer

  Dim As Integer i, bi, mi
  
  PlaceMap=1  'return code - error
  
  'set bi to bitmap, if already exist
  bi=0
  For i=1 To MaxBmp
    If w.MapData(i)->filename=FileName Then
      bi=i
      Exit For
    EndIf
  Next i
  
  If bi=0 Then
    MessageBox("PlaceMap Error: MissingBitmap "+FileName)
    LogFile("")
    LogFile("PlaceMap Error: MissingBitmap "+FileName)
    PlaceMap=1
  EndIf
  
  'set mi to map header, if already exist
  mi=0
  For i=1 To MaxMaps
    If (w.MapHdr(i)<>NULL) AndAlso (w.MapHdr(i)->MapName=MapName) Then
      mi=i
      Exit For
    EndIf
  Next i
  
  'create new map header, if necessary
  If mi=0 Then
    For i=1 To MaxMaps
      If w.MapHdr(i)=NULL Then
        mi=i
        Exit For
      EndIf
    Next i
    w.MapHdr(mi)=new TBmp
  EndIf
  
  w.MapHdr(mi)->MapName = MapName
  w.MapHdr(mi)->x = x
  w.MapHdr(mi)->y = y
  w.MapHdr(mi)->scale = scale
  w.MapHdr(mi)->ZoomMin = ZoomMin
  w.MapHdr(mi)->ZoomMax = ZoomMax
  w.MapHdr(mi)->BmpIndex = bi
  LogFile("  PlaceMap - BMP-Index="+str(bi)+", HDR-Index="+str(mi))
  PlaceMap=0  'return code - OK
End Function


Function NewMap(index As Integer, n As String, BmpIndex As Integer _
                , x As Integer, y As Integer _
                , scale As Integer _
                , ZoomMin As Integer, ZoomMax As Integer _
                ) As Integer

  NewMap=1  'return code - error

  If w.MapData(BmpIndex) <> NULL Then
  
    'create new memory element, if necessary
    If w.MapHdr(index)=NULL Then
      w.MapHdr(index)=new TBmp
    EndIf

    w.MapHdr(index)->x = x
    w.MapHdr(index)->y = y
    w.MapHdr(index)->scale = scale
    w.MapHdr(index)->ZoomMin = ZoomMin
    w.MapHdr(index)->ZoomMax = ZoomMax
    w.MapHdr(index)->BmpIndex = BmpIndex
    NewMap=0  'return code - OK
  EndIf
End Function


'fade rgb between two colors c1 and c2
'fade=0: return c1
'fade=255: return c2

Function FadeRGB(c1 As Integer, c2 As Integer, _
                 fade As Integer) As Integer
  Dim As Integer r, g, b, r1, g1, b1, r2, g2, b2
  
  If fade>255 Then fade=255
  
  r1=c1 Shr 16
  g1=c1 Shr 8 And 255
  b1=c1 And 255

  r2=c2 Shr 16
  g2=c2 Shr 8 And 255
  b2=c2 And 255
  
  r=(r1*(255-fade)+r2*fade) Shr 8
  g=(g1*(255-fade)+g2*fade) Shr 8
  b=(b1*(255-fade)+b2*fade) Shr 8
  
  FadeRGB=r Shl 16+g Shl 8+b
End Function


Sub CreateBmp(index As Integer, n As String, _
                BmpWidth As Integer, BmpHeight As Integer, _
                TLColor As Integer, _
                TRColor As Integer, _
                BLColor As Integer, _
                BRColor As Integer)

  Dim As Integer x, y, c1, c2, c3, c4, co

  
  'create new memory element, if necessary
  If w.MapData(index)=NULL Then
    w.MapData(index)=new TBmp1023
  EndIf

  w.MapData(index)->filename=n
  If BmpWidth>1024 Then BmpWidth=1024
  If BmpHeight>1024 Then BmpHeight=1024
  w.MapData(index)->w=BmpWidth
  w.MapData(index)->h=BmpHeight
  
  For y=0 To BmpHeight-1
    c1=FadeRGB(TLColor,BLColor,y*256/BmpHeight)
    c2=FadeRGB(TRColor,BRColor,y*256/BmpHeight)
    For x=0 To BmpWidth-1
      w.MapData(index)->data(x,y)=FadeRGB(c1,c2,x*256/BmpWidth)
    Next x
  Next y

End Sub



'################################################
'## trains.ini init-file
'################################################


Dim Shared As String ini_s
Dim Shared As Integer ini_f, ini_lnum

' read a string from ini-file, count line number

Function IniRead As String
  Dim As String s

  Line Input #ini_f, s
  s=trim(s)
  ini_lnum+=1
  IniRead=s
End Function




'################################################
'## Track build tool
'################################################


Function RebuildTrackString(i As Integer) As String
'  Dim As Integer er, df
  Dim As String s, last
  Dim As Integer cnt
  Dim As PTrack pt
  
  'run through track segments and rebuild track string
  s=""
  pt=w.Start(i)->start
  Do
    If ((last<>"") AndAlso (last<>pt->tname)) OrElse (cnt=8) Then
      s=s+" "
      cnt=0
    EndIf
    cnt+=1
    s=s+pt->tname
    last=pt->tname
    'check for visigle flag
    If (pt->visible=0) Then
      s=s+"v"
    EndIf
    'check for signals
    If (pt->SigF<>"") OrElse (pt->SigR<>"") Then
      s=s+"("+pt->SigF+","+pt->SigR+")"
    EndIf
    pt=pt->pn
  Loop Until pt=w.Start(i)->last
  If (last<>"") AndAlso (last<>pt->tname) Then
    s=s+" "
  EndIf
  s=s+pt->tname
  
  'check if tack is closed
  If w.Start(i)->start=w.Start(i)->last->pf Then
    s=s+" c"
  EndIf
  Return s
End Function


Function fdec(n As Integer, comment As String) As String
  fdec="  "+left(str(n)+"            ",12)+"# "+comment
End Function

Function fhex(n As Integer, comment As String) As String
  fhex="  0x"+hex(n,6)+"    "+"# "+comment
End Function


'################################################
'## New Data File Handling
'################################################
'
'

Sub FileGeneration(fn As String, gen As Integer)
  Dim As Integer er, df
  Dim As Integer i
  
  LogFile("FileGeneration:"+fn)
  df=FreeFile
  For i=gen To 1 Step -1
    er=Open(DataPath+fn+"_"+str(i)+CExt For Input As #df)
    Close #df
    If er=0 Then
      'rename file: result=Name(oldname, newname)
      'ChDir(DataPath)
      er = Name(DataPath+fn+"_"+str(i)+CExt, DataPath+fn+"_"+str(i+1)+CExt)
      'ChDir("..")
      LogFile("  rename: "+DataPath+fn+"_"+str(i)+CExt+"->"+DataPath+fn+"_"+str(i+1)+CExt+", er="+str(er))
    EndIf
  Next i
  er=Open(DataPath+fn+CExt For Input As #df)
  Close #df
  If er=0 Then
    'rename file (oldname, newname)
    er = Name(DataPath+fn+CExt, DataPath+fn+"_1"+CExt)
    LogFile("  rename: "+DataPath+fn+CExt+"->"+DataPath+fn+"_1"+CExt+", er="+str(er))
  EndIf
End Sub



'Sub FileGeneration(fn As String, gen As Integer)
'  Dim As Integer er, df
'  Dim As Integer i
'  
'  LogFile("FileGeneration:"+fn)
'  df=FreeFile
'  For i=gen To 1 Step -1
'    er=Open(DataPath+fn+"_"+str(i)+CExt For Input As #df)
'    If er=0 Then
'      'rename file (oldname, newname)
'      er = Name(DataPath+fn+"_"+str(i)+CExt,DataPath+fn+"_"+str(i+1)+CExt)
'      LogFile("FileGeneration rename 1: "+DataPath+fn+"_"+str(i)+CExt+", er="+str(er))
'    EndIf
'  Next i
'  er=Open(DataPath+fn+CExt For Input As #df)
'  If er=0 Then
'    'rename file (oldname, newname)
'    er = Name(DataPath+fn+CExt,DataPath+fn+"_1"+CExt)
'    LogFile("FileGeneration rename 2: "+DataPath+fn+CExt+", er="+str(er))
'  EndIf
'End Sub



Sub SaveBlockStart(filenum As Integer, depth As Integer, n As String)
  Print #filenum, Space(depth*2)+"<"+lcase(n)+">"
End Sub

Sub SaveBlockEnd(filenum As Integer, depth As Integer, n As String)
  Print #filenum, Space(depth*2)+"</"+lcase(n)+">"
End Sub

Sub SaveInt(filenum As Integer, depth As Integer, n As String, i As Integer)
  Dim As String s, st
  Dim As Integer l
  
  s=str(i)
  If i>=0 Then
    l=3   'positive: 3 digits
  Else
    l=4   'negative: 3 digits + sign
  EndIf
  Do while Len(s)>l
    st="_"+right(s,3)+st
    s=left(s,Len(s)-3)
  Loop
  st=s+st
  Print #filenum, Space(depth*2)+"<"+lcase(n)+"="+st+">"
'  Print #filenum, Space(depth*2)+"<"+lcase(n)+"="+str(i)+">"
End Sub

Sub SaveIntHex(filenum As Integer, depth As Integer, n As String, i As Integer)
  Print #filenum, Space(depth*2)+"<"+lcase(n)+"=0x"+hex(i)+">"
End Sub

Sub SaveStr(filenum As Integer, depth As Integer, n As String, value As string)
  Print #filenum, Space(depth*2)+"<"+lcase(n)+"="+chr(34)+value+chr(34)+">"
End Sub

Sub SaveStrBlock(filenum As Integer, depth As Integer, n As String, value As string)
  Dim As String s
  
  SaveBlockStart(filenum,depth,n)
  s=value
  Do
    Print #filenum, space((depth+1)*2)+left(s,32)
    If Len(s)>32 Then
      s=right(s,Len(s)-32)
    Else
      s=""
    EndIf
  Loop Until s=""
  SaveBlockEnd(filenum,depth,n)
End Sub


Sub SaveIniFileNew(fn As String)
  Dim As Integer er, df
'  Dim As String s
  Dim As Integer i
  Dim As PTrack pt
  
  df=FreeFile
  er=Open(DataPath+fn+CExt For Output As #df)
  If er=0 Then
    Print #df, "####################################"
    Print #df, "#"
    Print #df, "# train simulator init file"
    Print #df, "#"
    Print #df, "####################################"
    Print #df,
    Print #df,
    SaveStr(df,0,"version",FileVersion)
    Print #df,


    Print #df,
    Print #df, "####################################"
    Print #df, "#"
    Print #df, "# global settings"
    Print #df, "#"
    Print #df, "####################################"
    Print #df,

    SaveBlockStart(df,0,"globalsetup")
    Print #df,
    Print #df, "# Display Setup"
    SaveInt(df,1,"screenw",ScreenW)
    SaveInt(df,1,"screenh",ScreenH)
    SaveInt(df,1,"zoommin",ZoomMinLevel)
    SaveInt(df,1,"zoommax",ZoomMaxLevel)
    SaveIntHex(df,1,"groundcolor",GroundColor)
    SaveInt(df,1,"endlessdrag",EndlessDrag)
    SaveInt(df,1,"mouseacclevel",MouseAccLevel)
    SaveInt(df,1,"railway",1)
    Print #df,
    Print #df, "# Framerate and Performance Setup"
    SaveInt(df,1,"fpslimit",FpsLimit)
    SaveInt(df,1,"fpscheck",FpsCheck)
    SaveInt(df,1,"bitmaptime",MapPerformance)
    Print #df,
    Print #df, "# Cheat (0=speed limit off)"
    SaveInt(df,1,"speedlimit",SpeedLimit)
    Print #df,
    Print #df, "# Cheat (Create Number of Test Tracks)"
    SaveInt(df,1,"generictracks",GenericTracks)
    Print #df,
    Print #df, "# Visual Effencs and Messages"
    SaveInt(df,1,"menufade",Menu.Alpha)
    SaveInt(df,1,"cameraslide",wv.CamSteps)
    SaveInt(df,1,"showtrainstops",ShowTrainStops)
    SaveInt(df,1,"showtraindeliver",ShowTrainDeliver)
    SaveInt(df,1,"showmoney",ShowMoney)
    
    Print #df,
    SaveBlockEnd(df,0,"globalsetup")
    Print #df,
    Print #df,
    Print #df, "# Background images / bitmaps"
    
    For i=1 To MaxMaps
      If (w.MapHdr(i)<>NULL) Then
        Print #df,
        SaveBlockStart(df,0,"placemap")
        SaveStr(df,1,"map",w.MapHdr(i)->MapName)
        SaveStr(df,1,"file",w.MapData(w.MapHdr(i)->BmpIndex)->filename)
        SaveInt(df,1,"posx",w.MapHdr(i)->x)
        SaveInt(df,1,"posy",w.MapHdr(i)->y)
        SaveInt(df,1,"scale",w.MapHdr(i)->scale)
        SaveInt(df,1,"zoommin",w.MapHdr(i)->ZoomMin)
        SaveInt(df,1,"zoommax",w.MapHdr(i)->ZoomMax)
        SaveBlockEnd(df,0,"placemap")
      EndIf
    Next i
    
    Close (df)
  Else
    Cls
    Print "Error - Can't save file "+DataPath+fn+CExt
    Sleep
    Cls
  EndIf
End Sub


Sub SaveDataFileNew(fn As String)
  Dim As Integer er, df
'  Dim As String s
  Dim As Integer i
  Dim As PTrack pt
  
  df=FreeFile
  er=Open(DataPath+fn+CExt For Output As #df)
  If er=0 Then
    Print #df, "####################################"
    Print #df, "#"
    Print #df, "# train simulator data file"
    Print #df, "#"
    Print #df, "####################################"
    Print #df,
    Print #df, "####################################"
    Print #df, "#"
    Print #df, "# tracks"
    Print #df, "#"
    Print #df, "# angle:"
    Print #df, "#   0 = east,  128 = south"
    Print #df, "# 256 = west,  384 = north"
    Print #df, "#"
    Print #df, "####################################"
    Print #df,
    SaveStr(df,0,"version",FileVersion)
    Print #df,

    For i=0 To MaxTracks
      If w.Start(i)<>NULL Then
        Print #df, "# Track "+str(i)+": "+w.Start(i)->tName
        SaveBlockStart(df,0,"track")
        SaveStr(df,1,"name",w.Start(i)->tName)
        SaveInt(df,1,"posx",w.Start(i)->x)
        SaveInt(df,1,"posy",w.Start(i)->y)
        SaveInt(df,1,"posz",w.Start(i)->z)
        SaveInt(df,1,"angle",w.Start(i)->angle)
        SaveStrBlock(df,1,"build",RebuildTrackString(i))
        SaveBlockEnd(df,0,"track")
        Print #df,
      EndIf
    Next i


    Print #df,
    Print #df, "####################################"
    Print #df, "#"
    Print #df, "# Turnouts"
    Print #df, "#"
    Print #df, "####################################"
    Print #df,

    For i=0 To MaxTurnouts
      If w.Turnouts(i)<>NULL Then
        Print #df, "# Turnout "+str(i)
        SaveBlockStart(df,0,"turnout")
        SaveStr(df,1,"name1",w.Turnouts(i)->pr1->mytrack->tName)
        SaveInt(df,1,"tracksegment1",w.Turnouts(i)->pr1->tNum)
        SaveStr(df,1,"name2",w.Turnouts(i)->pr2->mytrack->tName)
        SaveInt(df,1,"tracksegment2",w.Turnouts(i)->pr2->tNum)
        SaveInt(df,1,"turnstate",w.Turnouts(i)->Turn)
        SaveBlockEnd(df,0,"turnout")
        Print #df,
      EndIf
    Next i


    Print #df,
    Print #df, "####################################"
    Print #df, "#"
    Print #df, "# Trains"
    Print #df, "#"
    Print #df, "####################################"
    Print #df,

    For i=0 To MaxTrains
      If w.Train(i)<>NULL Then
        Print #df, "# Train "+str(i)
        SaveBlockStart(df,0,"train")
        SaveStr(df,1,"name",w.Train(i)->TName)
        
        SaveStr(df,1,"trainpic",w.model(w.Train(i)->pic)->mName)
        SaveStr(df,1,"carpic",w.model(w.Train(i)->WaggonPic)->mName)
        SaveStr(df,1,"trackname",w.Train(i)->tr->mytrack->tName)
        SaveInt(df,1,"numcars",w.Train(i)->waggons)
        SaveInt(df,1,"tracksegment",w.Train(i)->tr->tNum)
        SaveInt(df,1,"position",w.Train(i)->ps)
        SaveInt(df,1,"speed",w.Train(i)->sp/SpeedScale)
        SaveIntHex(df,1,"control",w.Train(i)->control)

        SaveInt(df,1,"uOdometer",w.Train(i)->uOdometer)
        SaveInt(df,1,"TripOdo",w.Train(i)->TripOdo)
        SaveInt(df,1,"Odometer",w.Train(i)->Odometer)
        SaveInt(df,1,"Damage",w.Train(i)->Damage)
        SaveInt(df,1,"Credit",w.Train(i)->Credit)
        SaveInt(df,1,"MaxSpeed",w.Train(i)->MaxSpeed)
        SaveInt(df,1,"MaxCars",w.Train(i)->MaxCars)
        SaveInt(df,1,"state",w.Train(i)->state)
        SaveInt(df,1,"si1",w.Train(i)->si1)
        SaveInt(df,1,"si2",w.Train(i)->si2)
        SaveInt(df,1,"si3",w.Train(i)->si3)
        SaveBlockEnd(df,0,"train")
        Print #df,
      EndIf
    Next i


    Print #df,
    Print #df,
    Print #df, "####################################"
    Print #df, "#"
    Print #df, "# placed vector graphics objects"
    Print #df, "#"
    Print #df, "####################################"
    Print #df,

    For i=0 To MaxItems
      If w.Items(i)<>NULL Then
        Print #df, "# Item "+str(i)
        SaveBlockStart(df,0,"placeitem")
        SaveStr(df,1,"name",w.model(w.Items(i)->build)->mName)
        SaveInt(df,1,"pax",w.Items(i)->a.x)
        SaveInt(df,1,"pay",w.Items(i)->a.y)
        SaveInt(df,1,"paz",w.Items(i)->a.z)
        SaveInt(df,1,"pbx",w.Items(i)->b.x)
        SaveInt(df,1,"pby",w.Items(i)->b.y)
        SaveInt(df,1,"pbz",w.Items(i)->b.z)
        SaveInt(df,1,"color",w.Items(i)->col)
        SaveInt(df,1,"scaletype",w.Items(i)->ScaleType)
        SaveBlockEnd(df,0,"placeitem")
        Print #df,
      EndIf
    Next i

    Print #df,
    Print #df,
    Print #df, "####################################"
    Print #df, "#"
    Print #df, "# global settings"
    Print #df, "#"
    Print #df, "####################################"
    Print #df,

    SaveBlockStart(df,0,"globalsetup")
    If w.Train(wv.cam)<>NULL Then
      SaveStr(df,1,"cam",w.Train(wv.cam)->TName)
    EndIf
    SaveInt(df,1,"mapactive",wv.MapActive)
    SaveInt(df,1,"LandMapActive",wv.LandMapActive)
    SaveInt(df,1,"Debug",v.Debug)
    SaveInt(df,1,"GridOn",wv.GridOn)
    SaveInt(df,1,"Scale",v.Scale)
    SaveInt(df,1,"OffX",v.OffX)
    SaveInt(df,1,"OffY",v.OffY)
    If w.Train(g.Ctrl)<>NULL Then
      SaveStr(df,1,"ctrltrain",w.Train(g.Ctrl)->TName)
    EndIf
    SaveInt(df,1,"helpman",helpman)
    SaveInt(df,1,"OhdFps",OhdFps)
    SaveInt(df,1,"Controller",Controller)
    SaveInt(df,1,"framestotal",g.framestotal)
    Print #df, "  # FpsLimit="+str(FpsLimit)
    Print #df, "  # Elapsed Time is about "+str(Int(g.framestotal/FpsLimit/60))+" Minutes"
    SaveInt(df,1,"money",g.money)
    Print #df, "  # Money="+MoneyStr(g.money)
    SaveBlockEnd(df,0,"globalsetup")
    Close (df)
  Else
    Cls
    Print "Error - Can't save file "+DataPath+fn+CExt
    Sleep
    Cls
  EndIf
End Sub


Sub SaveDataTrack(fn As String)
  Dim As Integer er, df
'  Dim As String s
  Dim As Integer i
  Dim As PTrack pt
  
  df=FreeFile
  er=Open(DataPath+fn+CExt For Output As #df)
  If er=0 Then
    Print #df, "####################################"
    Print #df, "#"
    Print #df, "# train simulator track export"
    Print #df, "#"
    Print #df, "####################################"
    Print #df,

    If w.Start(g.EditTrk)<>NULL Then
      Print #df, "# Track "+str(g.EditTrk)+": "+w.Start(g.EditTrk)->tName
      SaveBlockStart(df,0,"track")
      SaveStr(df,1,"name",w.Start(g.EditTrk)->tName)
      SaveInt(df,1,"posx",w.Start(g.EditTrk)->x)
      SaveInt(df,1,"posy",w.Start(g.EditTrk)->y)
      SaveInt(df,1,"posz",w.Start(g.EditTrk)->z)
      SaveInt(df,1,"angle",w.Start(g.EditTrk)->angle)
      SaveStrBlock(df,1,"build",RebuildTrackString(g.EditTrk))
      SaveBlockEnd(df,0,"track")
      Print #df,
    EndIf
    
    Close (df)
  Else
    Cls
    Print "Error - Can't save file "+DataPath+fn+CExt
    Sleep
    Cls
  EndIf
End Sub


'################################################
'## New Vector Model File Handling
'################################################


Sub SaveModelFileNew(fn As String)
  Dim As Integer er, df
  Dim As String s, sh
  Dim As Integer i, j, cnt
  
  df=FreeFile
  cnt=0
  er=Open(DataPath+fn+CExt For Output As #df)
  If er=0 Then
    Print #df, "####################################"
    Print #df, "#"
    Print #df, "# train simulator vector model file"
    Print #df, "#"
    Print #df, "####################################"
    Print #df,
    SaveStr(df,0,"version",FileVersion)
    Print #df,
    
    For i=0 To MaxModels
      If w.Model(i)<>NULL AndAlso w.Model(i)->mBuild<>"" Then
        s=w.Model(i)->mBuild
        Print #df,
        Print #df,"# Model "+str(i)
        SaveBlockStart(df,0,"model")
        SaveStr(df,1,"name",w.Model(i)->mName)
        sh=""
        For j=1 To Len(s)
          sh=sh+hex(Asc(mid(s,j,1)),2)
        Next j
        SaveStrBlock(df,1,"build",sh)
        SaveBlockEnd(df,0,"model")
        Print #df,
      EndIf
    Next i
    Close (df)
  Else
    Cls
    Print "Error - Can't save file "+DataPath+fn+CExt
    Sleep
    Cls
  EndIf
End Sub


'################################################
'## New File Handling - Load
'################################################


Function ReadNext As String
  Dim As String s
  
  Do
    s=IniRead
  Loop Until (left(s,1)="<") _
  OrElse EOF(ini_f)
  Return s
End Function


Function TrimStr(s As String)As String
  Dim As String r
  
  r=trim(s)
  If left(r,1)=chr(34) Then
    r=right(r,Len(r)-1)
  EndIf
  If right(r,1)=chr(34) Then
    r=left(r,Len(r)-1)
  EndIf
  Return r
End Function


Function unpack(s As String)As String
  Dim As String r
  
  r=trim(s)
  If left(r,1)="<" Then
    r=right(r,Len(r)-1)
  EndIf
  If right(r,1)=">" Then
    r=left(r,Len(r)-1)
  EndIf
  Return r
End Function


Sub  Expect(se As String,sf As String)
  If se<>sf Then
    LogFile("")
    LogFile("Error in line "+str(ini_lnum))
    LogFile("  Expected:"+se)
    LogFile("  Found   :"+sf)
    MessageBox("Error: expected "+se+", found "+sf+". Quit Program.")
    End
  EndIf
End Sub


Function ReadStrBlock(be As String) As String
  Dim As String s, r
  
  r=""
  Do
    s=IniRead
    If left(s,1)<>"<" Then
      r=r+s
    EndIf
  Loop Until (left(s,1)="<") _
  OrElse EOF(ini_f)
  Expect(be,s)
  Return r
End Function


Sub LoadValue(vname As String, value As String)
  LogFile("LoadValue "+vname+" := "+value+" - OK.")
  Select Case vname
  Case "version":
    Value=TrimStr(Value)
    If Value<>FileVersion Then
      MessageBox("File Version "+Value+"<>"+FileVersion+". Try to load file.")
      LogFile("")
      LogFile("Warning.")
      LogFile("File Version "+Value+"<>"+FileVersion+". Try to load file.")
    EndIf
  Case Else:
    LogFile("LoadValue Warning")
    LogFile("Skip unknown "+vname+" = "+value)
  End Select
End Sub


Sub SkipBlock(blocktype As String)
  Dim As String s, s1, s2
  
  Do
    s=IniRead
  Loop Until s="</"+blocktype+">"_
  OrElse EOF(ini_f)
  LogFile("SkipBlock "+blocktype+" OK")
End Sub




'##########################################
'# load model
'##########################################


Sub LoadModel
  Dim As String s, s1, s2
  Dim As String MName, MBuild
  Dim As Integer i, mi, er
  Dim As Integer PosX, PosY, PosZ, Angle
  
  er=0
  LogFile("")
  LogFile("LoadTrack, line="+str(ini_lnum))
  Do
    s=ReadNext
    
    'load single value or block
    s=unpack(s)
    i=InStr(s,"=")
    If i Then
      'load value
      s1=left(s,i-1)
      s2=right(s,Len(s)-i)
    Else
      s1=s
      s2=""
    EndIf
    
    Select Case s1
    Case "name":
      MName=TrimStr(s2)
    Case "build":
      MBuild=ReadStrBlock("</build>")
    Case "/model":
      'end of track data set
    Case Else:
      Logfile("LoadModel: unknown element:"+s1+" := "+s2)
      LogFile("  in Line "+str(ini_lnum))
    End Select
    
  Loop Until s="/model" Or EOF(ini_f)
  
  'check if model with same name exist
'  mi=-1                   'model index
'  For i=1 To MaxModels
'    If (w.Model(i)<>NULL) AndAlso _
'    (w.Model(i)->mName = s2) Then
'      mi=i
'    EndIf
'  Next i
  mi=GetModelIndex(MName)
  LogFile("LoadModel-1 "+MName+", mi="+str(mi))
  
  'set mi to model index (new or overwrite)
  If mi=0 Then
    'set mi to next free position
    mi=0
    Do
      mi+=1
    Loop Until w.Model(mi)=NULL
    LogFile("  Create new Model (index="+str(mi)+") "+MName)
    w.Model(mi) = new TModel
  Else
    LogFile("  Overwrite existing Model (index="+str(mi)+") "+MName)
  EndIf
  LogFile("LoadModel-2 "+MName+", mi="+str(mi))
  
  'load data into model
  w.Model(mi)->mName = MName
  w.Model(mi)->mBuild = ""
  For i=1 To Len(MBuild)/2
    w.Model(mi)->mBuild=w.Model(mi)->mBuild+_
    chr(Val("&H"+mid(MBuild,i*2-1,2)))
  Next i
  InfoBox("Load Model "+str(mi))
  LogFile("  LoadModel OK")
End Sub




'##########################################
'# load track
'# or import track as new if
'# (g.es=es_ImportTrackHere)
'##########################################


Sub LoadTrack
  Dim As String s, s1, s2
  Dim As String TName, TBuild
  Dim As Integer i, mi, er
  Dim As Integer PosX, PosY, PosZ, Angle
  
  er=0
  LogFile("")
  LogFile("LoadTrack, line="+str(ini_lnum))
  Do
    s=ReadNext
    
    'load single value or block
    s=unpack(s)
    i=InStr(s,"=")
    If i Then
      'load value
      s1=left(s,i-1)
      s2=right(s,Len(s)-i)
    Else
      s1=s
      s2=""
    EndIf
    
    Select Case s1
    Case "name":
      TName=TrimStr(s2)
    Case "posx":
      PosX=StrVal(s2)
    Case "posy":
      PosY=StrVal(s2)
    Case "posz":
      PosZ=StrVal(s2)
    Case "angle":
      Angle=StrVal(s2)
    Case "build":
      TBuild=ReadStrBlock("</build>")
    Case "/track":
      'end of track data set
    Case Else:
      Logfile("LoadTrack: unknown element:"+s1+" := "+s2)
      LogFile("  in Line "+str(ini_lnum))
    End Select
    
  Loop Until s="/track" Or EOF(ini_f)

  ' check if track is broken
  ' must be closed            ....c
  ' or have defined ends     e....e
  If right(TBuild,1)="c" _
  OrElse (left(TBuild,1)="e" _
  AndAlso right(TBuild,1)="e") Then
  Else
    er+=1
    Message("Error - Track "+TName+" is broken.")
    LogFile("")
    LogFile("LoadDataFile Error in Line "+str(ini_lnum))
    LogFile("  Track "+TName+" is broken.")
    LogFile("  Please check file.")
    LogFile("  Track must be closed      ....c")
    LogFile("  or have defined endings  e....e")
    LogFile("  What I found is          "+left(TBuild,1)+_
            "...."+right(TBuild,1))
    LogFile("")
  EndIf
  ' find next free track start index
  i=1
  Do While w.Start(i)<>NULL
    'check, if track with same name exist. if yes, abort with error
    If g.es<>es_ImportTrackHere _
    AndAlso w.Start(i)->TName=TName Then
      er+=1
      Message("Error while loading - Track with same name exist: "+TName)
      Exit Do
    EndIf
    i+=1
  Loop
  InfoBox("Load Track "+str(i))
  If er=0 Then
    If g.es=es_ImportTrackHere Then
      PosX=p2wx(v.WinX/2)
      PosY=p2wy(v.WinY/2)
      mi=0
      Do
        mi+=1
      Loop Until(GetTrackIndex("Track"+str(mi)))=0
      TName="Track"+str(mi)
    EndIf
    w.Start(i)=BuildTrack(TName,TBuild,PosX,PosY,PosZ,Angle)
    LogFile("Load Track ["+TName+"] done.")
  EndIf
End Sub




'##########################################
'# load turnout
'##########################################


Sub LoadTurnout
  Dim As String s, s1, s2
  Dim As String TName1, TName2
  Dim As Integer i, TSeg1, TSeg2, TState
  
  LogFile("")
  LogFile("LoadTurnout, line="+str(ini_lnum))
  Do
    s=ReadNext
    
    'load single value or block
    s=unpack(s)
    i=InStr(s,"=")
    If i Then
      'load value
      s1=left(s,i-1)
      s2=right(s,Len(s)-i)
    Else
      s1=s
      s2=""
    EndIf
        
    Select Case s1
    Case "name1":
      TName1=TrimStr(s2)
    Case "name2":
      TName2=TrimStr(s2)
    Case "tracksegment1":
      TSeg1=StrVal(s2)
    Case "tracksegment2":
      TSeg2=StrVal(s2)
    Case "turnstate":
      TState=StrVal(s2)
    Case "/turnout":
      'end of track data set
    Case Else:
      Logfile("LoadTurnout: unknown element:"+s1+" := "+s2)
      LogFile("  in Line "+str(ini_lnum))
    End Select
    
  Loop Until s="/turnout" Or EOF(ini_f)
  
  If (NumOfTrack(TName1)=0) OrElse (NumOfTrack(TName2)=0) Then
      Message("Load Turnout Error: can't find track "+TName1+", "+TName2)
  Else
    i=InstallTurnout(w.Start(NumOfTrack(TName1)), TSeg1-1, _
      w.Start(NumOfTrack(TName2)), TSeg2-1)
    If TState=2 Then
      SwitchTurnout(w.Turnouts(i))
    EndIf
  EndIf
  InfoBox("Load Turnout "+str(i))
  LogFile("  Track1:"+TName1+", "+str(TSeg1))
  LogFile("  Track2:"+TName2+", "+str(TSeg2))
  LogFile("  LoadTurnout done.")
  
End Sub




'##########################################
'# load train
'##########################################


Sub LoadTrain
  Dim As String s, s1, s2
  Dim As String TName, TPic, CarPic, MyTrack
  Dim As Integer i, ti, ci
  Dim As Integer NumCars, TSeg, TPos, Sp
  Dim As Integer Ctrl, uOdo, Trip, Odo
  Dim As Integer Damage, Credit, MxSp, MxCars
  Dim As Integer State, si1, si2, si3
  
  LogFile("")
  LogFile("LoadTrain, line="+str(ini_lnum))
  Do
    s=ReadNext
    
    'load single value or block
    s=unpack(s)
    i=InStr(s,"=")
    If i Then
      'load value
      s1=left(s,i-1)
      s2=right(s,Len(s)-i)
    Else
      s1=s
      s2=""
    EndIf
        
    Select Case s1
    Case "name":
      TName=TrimStr(s2)
    Case "trainpic":
      TPic=TrimStr(s2)
    Case "carpic":
      CarPic=TrimStr(s2)
    Case "trackname":
      MyTrack=TrimStr(s2)

    Case "numcars":
      NumCars=StrVal(s2)
    Case "tracksegment":
      TSeg=StrVal(s2)
    Case "position":
      TPos=StrVal(s2)

    Case "speed":
      Sp=StrVal(s2)*SpeedScale
    Case "control":
      Ctrl=StrVal(s2)
    Case "uodometer":
      uOdo=StrVal(s2)
    Case "tripodo":
      Trip=StrVal(s2)
    Case "odometer":
      Odo=StrVal(s2)
    Case "damage":
      Damage=StrVal(s2)
    Case "credit":
      Credit=StrVal(s2)
    Case "maxspeed":
      MxSp=StrVal(s2)
    Case "maxcars":
      MxCars=StrVal(s2)
    Case "state":
      State=StrVal(s2)
    Case "si1":
      si1=StrVal(s2)
    Case "si2":
      si2=StrVal(s2)
    Case "si3":
      si3=StrVal(s2)

    Case "/train":
      'end of track data set
    Case Else:
      Logfile("LoadTrain: unknown element:"+s1+" := "+s2)
      LogFile("  in Line "+str(ini_lnum))
    End Select
    
  Loop Until s="/train" Or EOF(ini_f)
  
  If GetTrainIndex(TName)=0 Then
  
    'check for errors
    If GetModelIndex(TPic)=0 Then
      Message("  Load Train Error: can't find model "+TPic)
    ElseIf GetModelIndex(CarPic)=0 Then
      Message("  Load Train Error: can't find model "+CarPic)
    ElseIf NumOfTrack(MyTrack)=0 Then
      Message("  Load Train Error: can't find track "+MyTrack)
    Else
    
      'set ti to train model index (train picture)
      ti=ModelIndex(TPic)
      
      'set ci to train model index (train picture)
      ci=ModelIndex(CarPic)
      
      i=NewTrain(NumOfTrack(MyTrack), Sp, ti, ci, NumCars)
      
      'Place Train to saved Track Segment and Position
      'Set AutoPilot Controls
      If (i>0) AndAlso (i<MaxTrains) Then          
        Do While w.Train(i)->tr->TNum <> TSeg
          w.Train(i)->tr=w.Train(i)->tr->pn
          If w.Train(i)->tr = w.Train(i)->tr->MyTrack->last Then
            Exit Do
          EndIf
        Loop
        w.Train(i)->ps        = TPos
        w.Train(i)->control   = Ctrl
        w.Train(i)->AutoSpeed =   0
        w.Train(i)->uOdometer = uOdo
        w.Train(i)->TripOdo   = Trip
        w.Train(i)->Odometer  = Odo
        w.Train(i)->Damage    = Damage
        w.Train(i)->Credit    = Credit
        w.Train(i)->MaxSpeed  = MxSp
        w.Train(i)->MaxCars   = MxCars
        w.Train(i)->TName     = TName
        w.Train(i)->State     = State
        w.Train(i)->si1       = si1
        w.Train(i)->si2       = si2
        w.Train(i)->si3       = si3
      EndIf
      
      InfoBox("Load Train "+str(i))
      LogFile("  Load Train ["+TName+"] done.")
    EndIf
  Else
    MessageBox("Load Train Error: Train"+TName+" exist.")
    LogFile("  Load Train Error: Train"+TName+" exist.")
  EndIf
  
End Sub




'##########################################
'# load item
'##########################################


Sub LoadItem
  Dim As String s, s1, s2
  Dim As String iName
  Dim As Integer i
  Dim As Integer pax,pay,paz
  Dim As Integer pbx,pby,pbz
  Dim As Integer iCol,iScale
  
  LogFile("")
  LogFile("LoadItem, line="+str(ini_lnum))
  Do
    s=ReadNext
    
    'load single value or block
    s=unpack(s)
    i=InStr(s,"=")
    If i Then
      'load value
      s1=left(s,i-1)
      s2=right(s,Len(s)-i)
    Else
      s1=s
      s2=""
    EndIf
        
    Select Case s1
    Case "name":
      iName=TrimStr(s2)
    Case "pax":
      pax=StrVal(s2)
    Case "pay":
      pay=StrVal(s2)
    Case "paz":
      paz=StrVal(s2)
    Case "pbx":
      pbx=StrVal(s2)
    Case "pby":
      pby=StrVal(s2)
    Case "pbz":
      pbz=StrVal(s2)
    Case "color":
      iCol=StrVal(s2)
    Case "scaletype":
      iScale=StrVal(s2)
    Case "/placeitem":
      'end of track data set
    Case Else:
      Logfile("LoadItem: unknown element:"+s1+" := "+s2)
      LogFile("  in Line "+str(ini_lnum))
    End Select
    
  Loop Until s="/placeitem" Or EOF(ini_f)
  
  'Place Item in World
  'set i to next free index position
  i=1
  Do While (w.Items(i)<>0)
    i+=1
  Loop
  If i<MaxItems _
  AndAlso NumOfModel(iName)<>0 Then
    CreateItem(i, pax, pay, pbx, pby, NumOfModel(iName), iCol, iScale)
  EndIf
  InfoBox("Load Item "+str(i))
  LogFile("  Load and placed Item ["+iName+"] done.")
End Sub




'##########################################
'# load global setup
'##########################################


Sub LoadGlobalSetup
  Dim As String s, s1, s2
  Dim As Integer i
  
  LogFile("")
  LogFile("Load Global Setup, line="+str(ini_lnum))
  ScreenWIni=0
  Do
    s=ReadNext
    
    'load single value or block
    s=unpack(s)
    i=InStr(s,"=")
    If i Then
      'load value
      s1=left(s,i-1)
      s2=right(s,Len(s)-i)
    Else
      s1=s
      s2=""
    EndIf
        
    Select Case s1
    Case "cam":
      wv.Cam=GetTrainIndex(TrimStr(s2))
    Case "mapactive":
      wv.MapActive=StrVal(s2)
    Case "landmapactive":
      wv.LandMapActive=StrVal(s2)
    Case "gridon":
      wv.GridOn=StrVal(s2)
    Case "debug":
      v.Debug=StrVal(s2)
    Case "scale":
      v.Scale=StrVal(s2)
    Case "offx":
      v.OffX=StrVal(s2)
    Case "offy":
      v.OffY=StrVal(s2)
    Case "ctrltrain":
      g.Ctrl=GetTrainIndex(TrimStr(s2))
    Case "railway":
      Railway=StrVal(s2)
    Case "helpman":
      helpman=StrVal(s2)
    Case "ohdfps":
      OhdFps=StrVal(s2)
    Case "controller":
      Controller=StrVal(s2)
    Case "framestotal":
      g.framestotal=StrVal(s2)
    Case "money":
      g.money=StrVal(s2)
      
    Case "bitmaptime":
      MapPerformance=StrVal(s2)
    Case "zoommin":
      ZoomMinLevel=StrVal(s2)
    Case "zoommax":
      ZoomMaxLevel=StrVal(s2)
    Case "groundcolor":
      GroundColor=StrVal(s2)
    Case "cameraslide":
      wv.CamSteps=StrVal(s2)

    Case "fpslimit":
      FpsLimit=StrVal(s2)
      SpeedScale=360/FpsLimit
    Case "fpscheck":
      FpsCheck=StrVal(s2)
'    Case "brakesteps":
'      brakesteps=StrVal(s2)
    Case "screenw":
      ScreenWIni=StrVal(s2)
    Case "screenh":
      If win480<>NULL Then
        imagedestroy win480
        imagedestroy win160
      EndIf
      ScreenInit(ScreenWIni,StrVal(s2))
      ViewInit
    Case "generictracks":
      GenericTracks=StrVal(s2)
    Case "menufade":
      Menu.Alpha=StrVal(s2)
    Case "endlessdrag":
      EndlessDrag=StrVal(s2)
    Case "mouseacclevel":
      MouseAccLevel=StrVal(s2)
    Case "speedlimit":
      SpeedLimit=StrVal(s2)
    Case "showtrainstops":
      ShowTrainStops=StrVal(s2)
    Case "showtraindeliver":
      ShowTrainDeliver=StrVal(s2)
    Case "showmoney":
      ShowMoney=StrVal(s2)
      
    Case "/globalsetup":
      'end of track data set
    Case Else:
      Logfile("Load Global Setup: unknown element:"+s1+" := "+s2)
      LogFile("  in Line "+str(ini_lnum))
    End Select
    
  Loop Until s="/globalsetup" Or EOF(ini_f)
  InfoBox("Load Global Setup")
  LogFile("  Load Global Setup done.")
End Sub







'##########################################
'# load and place bitmap
'##########################################


Sub LoadBitmap
  Dim As String s, s1, s2
  Dim As Integer i
  Dim As String MapName, FileName
  Dim As Integer PosX,PosY,Scale
  Dim As Integer ZoomMin,ZoomMax
  
  LogFile("")
  LogFile("Load Bitmap, line="+str(ini_lnum))
  Do
    s=ReadNext
    
    'load single value or block
    s=unpack(s)
    i=InStr(s,"=")
    If i Then
      'load value
      s1=left(s,i-1)
      s2=right(s,Len(s)-i)
    Else
      s1=s
      s2=""
    EndIf
    
    Select Case s1
    
    Case "map":
      MapName=TrimStr(s2)
    Case "file":
      FileName=TrimStr(s2)
      
    Case "posx":
      PosX=StrVal(s2)
    Case "posy":
      PosY=StrVal(s2)
    Case "scale":
      Scale=StrVal(s2)
    Case "zoommin":
      ZoomMin=StrVal(s2)
    Case "zoommax":
      ZoomMax=StrVal(s2)
      
    Case "/placemap":
      'end of track data set
    Case Else:
      Logfile("Load Global Setup: unknown element:"+s1+" := "+s2)
      LogFile("  in Line "+str(ini_lnum))
    End Select
    
  Loop Until s="/placemap" Or EOF(ini_f)
  
  'check if bitmap is already loaded
  For i=1 To MaxBmp
    If w.MapData(i)->filename=FileName Then Exit For
  Next i
  If i>=MaxBmp Then
    LogFile("  LoadBitmap - LoadBmpNew "+FileName)
    If LoadBmpNew(FileName)=0 Then
      i=PlaceMap(MapName,FileName,PosX,PosY,Scale,ZoomMin,ZoomMax)
    EndIf
  Else
    LogFile("  LoadBitmap - BMP Exist "+FileName+", index="+str(i))
    i=PlaceMap(MapName,FileName,PosX,PosY,Scale,ZoomMin,ZoomMax)
  EndIf
  
  
  InfoBox("Load Bitmap "+FileName)






'      ElseIf lcase(s)="colorbmp" Then
'        'create bitmap
'        Print "processing line "+str(ini_lnum)+": "+s
'        p1=IniReadNum 'index
'        s1=IniRead    'filename
'        p2=IniReadNum 'size x
'        p3=IniReadNum 'size y
'        p4=IniReadNum 'color
'        p5=IniReadNum 'color
'        p6=IniReadNum 'color
'        p7=IniReadNum 'color
'        Print "Exec ColorBmp("+str(p1)+","+s1+","+str(p2)+","+str(p3)+","+str(p4)+","+str(p5)+","+str(p6)+","+str(p7)+")"
'        CreateBmp(p1,s1,p2,p3,p4,p5,p6,p7)
'  
'
'      ElseIf lcase(s)="newmap" Then
'        'create map
'        Print "processing line "+str(ini_lnum)+": "+s
'        p1=IniReadNum 'index
'        s1=IniRead    'filename
'        p2=IniReadNum 'bmp index
'        p3=IniReadNum 'pos x
'        p4=IniReadNum 'pos y
'        p5=IniReadNum 'scale
'        p6=IniReadNum 'zoom min
'        p7=IniReadNum 'zoom max
'        Print "Exec NewMap("+str(p1)+","+s1+","+str(p2)+","+str(p3)+","+str(p4)+","+str(p5)+","+str(p6)+","+str(p7)+")"
'        NewMap(p1,s1,p2,p3,p4,p5,p6,p7)

  
End Sub




'##########################################
'# execute command
'##########################################


Sub ExecCommand(s As String)
  Dim cmd As String
  
  cmd=s
  LogFile("Execute Command ["+cmd+"]")

End Sub




'##########################################
'# load file
'##########################################


Sub LoadFile(n As String)
  Dim As Integer er, df
  Dim As String s, s1, s2
  Dim As String MName, CarName, MBuild
  Dim As Integer i, j, n1, n2, n3, n4, n5, n6, n7, n8
  Dim As Integer LineNum
  
  ini_f=FreeFile
  ini_lnum=0
  er=0
  
  LogFile("")
  LogFile("LoadFile ("+n+CExt+")")

  er=Open(DataPath+n+CExt For Input As #ini_f)
  If er=0 Then
    Do
    s=ReadNext
    If 0=EOF(ini_f) Then
      If left(s,1)<>"<" _
      OrElse right(s,1)<>">" _
      OrElse Len(s)<3 _
      Then
        LogFile("")
        LogFile("LoadFile Error.")
        LogFile("  File: "+n)
        LogFile("  Line: "+str(LineNum))
      EndIf
      
      '############################################
      '## html/xml inspired file format
      '############################################
      '
      'numeric value:
      '  <name=n>
      '
      'string value:
      '  <name="string">
      '
      'data block:
      '  <name>
      '   Block
      '  </name>
      '
      'executable command:
      '  <!command>
      '  <!command parameter1,para2,...>
      '
      '############################################
      
      's=lcase(unpack(s))
      s=unpack(s)
      
      If left(s,1)="!" Then
        'execute command
        s=trim(right(s,Len(s)-1))
        ExecCommand(s)
        
      Else
      
        'load single value or block
        i=InStr(s,"=")
        If i Then
          'load value
          LoadValue(left(s,i-1), right(s,Len(s)-i))
        Else
          'load block
          Select Case lcase(s)
          Case "model":
            LoadModel
          Case "track":
            LoadTrack
          Case "turnout":
            LoadTurnout
          Case "train":
            LoadTrain
          Case "globalsetup":
            LoadGlobalSetup
          Case "placeitem":
            LoadItem
          Case "placemap":
            LoadBitmap
          Case Else:
            SkipBlock(s)
          End Select
        EndIf
      EndIf
    EndIf
    Loop Until EOF(ini_f) OrElse er    
    Close (ini_f)
    LogFile("  LoadFile done.")
  Else
    Cls
    Print "Error - Can't open file "+DataPath+n
    Sleep
    Cls
  EndIf
  g.EditTrkPtrA=0
End Sub




'################################################
'## subroutines that load or save data
'################################################


Sub ts_te_ExportTrack
  If g.trksel<>0 _
  AndAlso "y"=YesOrNoBox("Export Track?") Then
    'edit track (export selected track)
    SaveDataTrack(InputBox("Export Track Name", CExportTrack))
  EndIf
End Sub


Sub ts_te_ImportTrackHere
  If "y"=YesOrNoBox("Import Track?") Then
    'edit track (import saved track)
    g.es=es_ImportTrackHere
    LoadFile(InputBox("Import Track Name", CExportTrack))
    g.es=es_Off
  EndIf
End Sub






'################################################
'## Main (Init)
'################################################

DataPath=CDataPath   'ini-file, bitmaps ...

'create new log file
NewLogFile


ScreenInit(640,480)

MapPerformance=CMapPerformance


'######################################################
'### read ronfiguration (trainini.txt)
'######################################################


Print
Print "Processing ini-file"
Print

LoadFile(CIniFileNew)
Cls


'################################################
'## Menu init
'################################################


MenuInit(0,0, 158,158-31*3, 4,4, 7)
MenuSwitch(MenuName0)
'tsmode=ts_run


''################################################
''## Views init
''################################################
'

ViewInit

'ViewInit
'
'win480=imagecreate(MainViewW,MainViewH)
'win160=imagecreate(SideViewW,SideViewH)
'
'wV.PosX=0+1
'wV.PosY=0+1
'wV.CamSteps=CCamSteps
'
'wView1.PosX=0+1
'wView1.PosY=0+1
'View1.WinX=MainViewW
'View1.WinY=MainViewH
'View1.Scale=1088
'wView1.CamSteps=CCamSteps
'
'wView1.VisBorderX=-(View1.WinX*(VisBorder))/200
'wView1.VisBorderY=-(View1.WinY*(VisBorder))/200
'
'wView1.cam=0
'wView1.MapActive=0
'View1.Debug=0
'wView1.Gridon=0
'
'wView2.PosX=MainViewW+3
'wView2.PosY=0+1
'View2.WinX=SideViewW
'View2.WinY=SideViewH
'View2.Scale=15000
'wView2.CamSteps=CCamSteps
'
'
'wView2.VisBorderX=-(View2.WinX*(VisBorder))/200
'wView2.VisBorderY=-(View2.WinY*(VisBorder))/200
'
'wView2.cam=0
'wView2.MapActive=0
'View2.Debug=0
'wView2.Gridon=0
'View2.OffX=View2.WinX/2-1001050*m/View2.Scale
'View2.OffY=View2.WinY/2-1000200*m/View2.Scale
'
'View3=View2
'wView3.PosX=MainViewW+3
'wView3.PosY=SideViewH+3
'View3.Scale=800
'wView3.cam=1

ScanCam=0

Color &Heeeeee,&H204020
Cls


''######################################################
''### Load Menu Icons
''######################################################

LoadMenuIcons


ofx=1000*1000*m
ofy=1000*1000*m

Print "<<< 1 >>>"

#ifdef mapon


'Build map

'replace "Allocate" by "New" and "DeAllocate" by "Delete" (hint from fxm / FreeBASIC forum)
'w.map=CAllocate(sizeof(TMapR))
w.map=New TMapR


map1=w.map
For i=0 To WorldX*MapRes-1
  For j=0 To WorldY*MapRes-1
    map1->x1=(ofx-WorldX/2*1000*m)+ i*1000/MapRes*m
    map1->y1=(ofy-WorldY/2*1000*m)+j*1000/MapRes*m
    map1->x2=(ofx-WorldX/2*1000*m)+(i*1000/MapRes+1000/MapRes)*m
    map1->y2=(ofy-WorldY/2*1000*m)+(j*1000/MapRes+1000/MapRes)*m
    map1->Color=(30+Int(Rnd()*10))*&H10000 _
               +(60+Int(Rnd()*50))*&H100 _
               +(30+Int(Rnd()*20))

    'replace "Allocate" by "New" and "DeAllocate" by "Delete" (hint from fxm / FreeBASIC forum)
    'map1->pnext=CAllocate(sizeof(TMapR))
    map1->pnext=New TMapR

    map1=map1->pnext
  Next
Next
#endif



Print "<<< 2 >>>"

BuildDefaultModels


Print "<<< 3 >>>"

  
'Build tracks


i=1
w.Start(i)=BuildTrack("Westlands", _
  "e f l*16 f l*16 f s(stop,stop) ff" _
  +" l*16 f l*16 f*6 e c", _
  ofx+252*m, ofy+93*m, 0, 256)

i+=1
w.Start(i)=BuildTrack("Small Town", _
  "e f l3l3l3l3l3l3l3l3 l3l3l3l3l3l" _
  +"3l3l3 l3l3l3l3l3l3l3l3 l3l3l3l3l" _
  +"3l3l3l3 f s(stop,stop) ff l3l3l3" _
  +"l3l3l3l3l3 l3l3l3l3l3l3l3l3 l3l3" _
  +"l3l3l3l3l3l3 l3l3l3l3l3l3l3l3 ff" _
  +"ffff e c", _
  ofx+252*m, ofy+101*m, 0, 256)

i+=1
w.Start(i)=BuildTrack("Cross Country", _
  "e fff rrrrrrrr rrrrrrrr rrrrrrrr" _
  +"r ff llllllll l ff s(stop,stop)" _
  +"fff rrrrrrrr rrrrrrrr fff rrrrr" _
  +"rrr rrrrrrrr rrrrrrrr rr lllllll" _
  +"l ll fff s(stop,stop) ff f3 rrrr" _
  +"rr r3 rrrrrrrr r e c", _
  ofx+569*m, ofy+289*m, 0, 384)

i+=1
w.Start(i)=BuildTrack("East End", _
  "e fffff llllllll llllllll llllll" _
  +"ll llllllll ffffffff rrrrrrrr rr" _
  +"rrrrrr f s(stop,stop) ff rrrrrrr" _
  +"r rrrrrrrr ffffffff f rrrrrrrr r" _
  +"rrrrrrr ff rrrrrrrr rrrrrrrr fff" _
  +"fff llllllll lllvlvlvlvlvlv fvfv" _
  +"fvfvff llllllll llllllll e c", _
  ofx+1311*m, ofy+308*m, 0, 128)

i+=1
w.Start(i)=BuildTrack("Big Western", _
  "e f rrrrrrrr rrrrrrrr f s(stop,s" _
  +"top) fff rrrrrrrr rrrrrrrr fffff" _
  +"fff ffffffff ff rrrrrrr f2 rrrrr" _
  +"r r3 rr f2 f3 ff s(stop,stop) f " _
  +"rrrrrrrr rrrrrrrr rrrrrrrr rrrrr" _
  +"rrr r3r3r3 l3l3l3l3l3l3l3l3 l3l3" _
  +"l3l3l3l3l3l3 l3l3l3l3l3l3l3l3 l3" _
  +"l3l3l3l3l3l3l3 l3l3l3l3l3l3 r3r3" _
  +"r3r3r3r3r3r3 r3r3 rrrrrrrr e c", _
  ofx+107*m, ofy+527*m, 0, 384)

i+=1
w.Start(i)=BuildTrack("South Side", _
  "e fff s(stop,stop) f f2 lllllll" _
  +"l l5 lllll l5 l fff llllllll lll" _
  +"lllll llllll ffffff rrrrrr fffff" _
  +"fff f rrrrrrrr rrrrrrrr rr ffff " _
  +"llllllll llllllll ll ffffffff ff" _
  +"ffffff ff llllllll llllllll ffff" _
  +"fff f3 f l3 llllllll lllllll fff" _
  +"ffff s(stop,stop) ff llllllll ll" _
  +"llllll lllllll f rrrrrrrr rrrrrr" _
  +"rr rr fvfvfvfv rrrrr ffff s(stop" _
  +",stop) ffff rrrrrrrr rrrrrrrr rr" _
  +"rrrrrr rrrrrrrr fffffff llllllll" _
  +" llllllvlvlv lvlvlvlvlvlv fv lv " _
  +"fv f2v fvfvfv lvlvlvlvlvlvlvlv l" _
  +"v fvfv e c", _
  ofx+957*m, ofy+451*m, 0, 256)

i+=1
w.Start(i)=BuildTrack("Coastline", _
  "e ffffff(slow,)ff ffffff s(stop," _
  +"stop) fff(speed:120,)fffff fffff" _
  +"fff ffffffff ffffffff ffffffff f" _
  +"fffffff ff rrrrrrrr rrrrrrrr fff" _
  +"fffff ffffffff ffffffff ffffffff" _
  +" rrrrrrrr rrrrrrrr ffffffff ffff" _
  +"ffff ffff(slow,)ffff ffffffff ff" _
  +"ffffff ffffffff ffffff s(stop,st" _
  +"op) ffffffff ff rrrrrrrr rrrrrrr" _
  +"r f(fast,)ff(,slow)fffff fffffff" _
  +"f fffffff(slow,)f ffffffff rrrrr" _
  +"rrr rrrrrrr e c", _
  ofx+200*m, ofy+50*m, 0, 0)

i+=1
w.Start(i)=BuildTrack("Stop 1", _
  "e f*30 s(stop,stop) f*10 f e", _
  ofx+300*m, ofy+60*m, 0, 0)

i+=1
w.Start(i)=BuildTrack("Stop 2", _
  "e f*26 s(stop,stop) f*10 f(crash,) e", _
  ofx+400*m, ofy+70*m, 0, 0)


TurnoutByName("Westlands",76,"Small Town",74)
TurnoutByName("Westlands",55,"Cross Country",3)

TurnoutByName("Westlands",38,"Big Western",21)
TurnoutByName("Cross Country",63,"East End",4)

TurnoutByName("East End",108,"South Side",169)
TurnoutByName("South Side",2,"Cross Country",102)

TurnoutByName("Big Western",43,"South Side",24)
TurnoutByName("Big Western",76,"Coastline",186)

TurnoutByName("Stop 1",1,"Coastline",5)
TurnoutByName("Stop 2",1,"Stop 1",5)


''manually build track
'i+=1
'w.Start(i)=NewTrack("Test "+Str$(i), ofx+200*m, ofy+80*m, 0, 0)
'AddTrack(w.Start(i),"e")
'AddTrack(w.Start(i),"f")
'AddTrack(w.Start(i),"f")
'AddTrack(w.Start(i),"f")
'AddTrack(w.Start(i),"f")
'AddTrack(w.Start(i),"f")
'AddTrack(w.Start(i),"f")
'AddTrack(w.Start(i),"f")
'AddTrack(w.Start(i),"f")
'AddTrack(w.Start(i),"e")
'ActivateTrack(w.Start(i))


'InstallTurnout(w.Start(1),1,w.Start(2),1)
'InstallTurnout(w.Start(1),42,w.Start(2),74)
'
'InstallTurnout(w.Start(1),33,w.Start(3),57)
'InstallTurnout(w.Start(3),21,w.Start(4),51)
'
'InstallTurnout(w.Start(3),39,w.Start(5),44)
'InstallTurnout(w.Start(3),47,w.Start(5),48)
'
'InstallTurnout(w.Start(4),25,w.Start(6),37)
'InstallTurnout(w.Start(5),23,w.Start(6),117)
'
'InstallTurnout(w.Start(5),132,w.Start(8),173)
'InstallTurnout(w.Start(5),135,w.Start(8),180)
'
'InstallTurnout(w.Start(6),82,w.Start(7),7)
'InstallTurnout(w.Start(6),75,w.Start(7),42)
'
'InstallTurnout(w.Start(8),5,w.Start(9),1)
'InstallTurnout(w.Start(9),5,w.Start(10),1)


Print "<<< 4 >>>"


v=View1

'center view to track 1
Const WatchTrain=1
ScreenCenter((w.Start(WatchTrain)->dimension.minx+ _
              w.Start(WatchTrain)->dimension.maxx)/2, _
             (w.Start(WatchTrain)->dimension.miny+ _
              w.Start(WatchTrain)->dimension.maxy)/2, v)





'create up to 8 trains
Randomize Timer
For i=1 To 7
  If w.Start(i)<>NULL Then
    'Track Index, Speed, Picture, Length
    NewTrain(i, (20+Rnd()*(SlowSpeed-20))*SpeedScale, _
      ModelIndex("Red Train")+((i-1) Mod 4), _
      ModelIndex("Brown Car")+((i-1) Mod 4), i)
    'activate train assist diver
    w.Train(i)->control=auto Or restart 'none, auto
  EndIf
Next i
'w.Train(8)->control=none 'none, auto

''Train control flags
'Const none=&H0000
'Const auto=&H0001
'Const brake=&H0002
'Const restart=&H0004
'Const crash=&H8000





' Build extra tracks and trains
If GenericTracks>0 Then
  j=0
  For i=11 To GenericTracks+10
    If i<=MaxTracks Then
      
      InfoBox("Generic Track "+str(j))
      
      w.Start(i)=BuildTrack("Generic-"+str(j), _
        "ef*3 f5 ff s ff r*8 f*5 r5*16 f2 ff f1 r5*16 f*5 r5*8 " _
        +"f6 fv*13 f f5 l5*8 f*2 l5*16 fff l5*16 f2 f*2 l5*8 ff ec", _
        ofx-7500*m+1000*m*(j Mod 20), ofy+1400*m+390*m*(j / 20), 0, -256/4)

    EndIf
    'Track Index, Speed, Picture, Length
    NewTrain(i, (20+Rnd()*(FastSpeed-20))*5, _
      ModelIndex("Red Train")+(j Mod 4), _
      ModelIndex("Brown Car")+(j Mod 4), 4)
    j+=1
  Next i
EndIf




Print "<<< 5 >>>"



'################################################
'## place items
'################################################


'House
i=0
i+=1:CreateItem(i,ofx+1207*m,ofy+500*m,ofx+1228*m,ofy+480*m, ModelIndex("House"),&Hc00000,ScaleBuilding)
i+=1:CreateItem(i,ofx+246*m,ofy+183*m,ofx+266*m,ofy+203*m, ModelIndex("House"),&Hc00000,ScaleBuilding)
i+=1:CreateItem(i,ofx+396*m,ofy+187*m,ofx+416*m,ofy+207*m, ModelIndex("House"),&Hc00000,ScaleBuilding)

'Station
i+=1:CreateItem(i,ofx+253*m,ofy+338*m,ofx+395*m,ofy+339*m, ModelIndex("Rail Station"),&Hc00000,ScaleBuilding)
i+=1:CreateItem(i,ofx+978*m,ofy+191*m,ofx+1108*m,ofy+191*m, ModelIndex("Rail Station"),&Hc00000,ScaleBuilding)

i+=1:CreateItem(i,ofx+1723*m,ofy+131*m,ofx+1847*m,ofy+131*m, ModelIndex("Rail Station"),&Hc00000,ScaleBuilding)
i+=1:CreateItem(i,ofx+1583*m,ofy+555*m,ofx+1712*m,ofy+555*m, ModelIndex("Rail Station"),&Hc00000,ScaleBuilding)

i+=1:CreateItem(i,ofx+1040*m,ofy+1034*m,ofx+1170*m,ofy+1034*m, ModelIndex("Rail Station"),&Hc00000,ScaleBuilding)
i+=1:CreateItem(i,ofx+551*m,ofy+20*m,ofx+659*m,ofy+20*m, ModelIndex("Rail Station"),&Hc00000,ScaleBuilding)

i+=1:CreateItem(i,ofx+233*m,ofy+1061*m,ofx+364*m,ofy+1061*m, ModelIndex("Rail Station"),&Hc00000,ScaleBuilding)
i+=1:CreateItem(i,ofx+435*m,ofy+1138*m,ofx+567*m,ofy+1138*m, ModelIndex("Rail Station"),&Hc00000,ScaleBuilding)

i+=1:CreateItem(i,ofx+759*m,ofy+483*m,ofx+883*m,ofy+483*m, ModelIndex("Rail Station"),&Hc00000,ScaleBuilding)


'tunnel
i+=1:CreateItem(i,ofx+1246*m,ofy+726*m,ofx+1252*m,ofy+704*m, ModelIndex("Tunnel"),0,ScaleBuilding)
i+=1:CreateItem(i,ofx+967*m,ofy+453*m,ofx+987*m,ofy+455*m, ModelIndex("Tunnel"),0,ScaleBuilding)

i+=1:CreateItem(i,ofx+1316*m,ofy+1064*m,ofx+1336*m,ofy+1055*m, ModelIndex("Tunnel"),0,ScaleBuilding)
i+=1:CreateItem(i,ofx+1420*m,ofy+1009*m,ofx+1402*m,ofy+1019*m, ModelIndex("Tunnel"),0,ScaleBuilding)

i+=1:CreateItem(i,ofx+1469*m,ofy+176*m,ofx+1504*m,ofy+176*m, ModelIndex("Tunnel"),0,ScaleBuilding)
i+=1:CreateItem(i,ofx+1655*m,ofy+196*m,ofx+1624*m,ofy+182*m, ModelIndex("Tunnel"),0,ScaleBuilding)


'forest
i+=1:CreateItem(i,ofx+700*m,ofy+150*m,ofx+700*m,ofy+350*m, ModelIndex("Forest"),0,ScaleBuilding)
i+=1:CreateItem(i,ofx+1447*m,ofy+316*m,ofx+1447*m,ofy+467*m, ModelIndex("Forest"),0,ScaleBuilding)

i+=1:CreateItem(i,ofx+530*m,ofy+824*m,ofx+365*m,ofy+996*m, ModelIndex("Forest"),0,ScaleBuilding)
i+=1:CreateItem(i,ofx+376*m,ofy+475*m,ofx+507*m,ofy+678*m, ModelIndex("Forest"),0,ScaleBuilding)

i+=1:CreateItem(i,ofx+1880*m,ofy+281*m,ofx+1880*m,ofy+481*m, ModelIndex("Forest"),0,ScaleBuilding)
i+=1:CreateItem(i,ofx+1551*m,ofy+834*m,ofx+1937*m,ofy+824*m, ModelIndex("Forest"),0,ScaleBuilding)




'set user controls to train 1 as default
g.ctrl=0
g.now=Timer
g.Frame=0
g.Fps=55

g.framestotal=0
g.money=0

Print "<<< 6 >>>"

Const SplashBG=&H333333
Color &HFFFFFF,SplashBG
Cls


'show splash screen
'abort intro with any keypress
var splash=bmp_load(CDataPath+CSplash)
Dim As Integer splashw, splashh
Line win480,(0,0) -Step(V.WinX,V.WinY),SplashBG,BF
If 0=ImageInfo (splash, splashw, splashh, , , , ) Then
  For i=0 To 255
    Line win480,((480-splashw)\2,(480-splashh)\2) -Step(splashw,splashh),SplashBG,BF
    Put win480,((480-splashw)\2,(480-splashh)\2), splash, alpha, i
    Put ((ScreenW-480)\2,(255-i)+(ScreenH-480)\2), win480, PSet
    Sleep 10
    ks=inkey
    If ks<>"" Then Exit For
  Next i
  
  If ks="" Then
    Draw String ((ScreenW-8*27)\2,ScreenH-16*4),"Starting Train Simulator..."
    Sleep 10000
    ks=inkey
    If ks="" Then
      For i=0 To 255
        Line win480,((480-splashw)\2,(480-splashh)\2) -Step(splashw,splashh),SplashBG,BF
        Put win480,((480-splashw)\2,(480-splashh)\2), splash, alpha, 255-i
        Put ((ScreenW-480)\2,(i*2)+(ScreenH-480)\2), win480, PSet
        Sleep 5
        ks=inkey
        If ks<>"" Then Exit For
      Next i
    EndIf
  EndIf
  'clear keyboard buffer
  Do: Loop Until inkey=""
EndIf


Color &HFFFFFF,GroundColor
Cls


'################################################
'## Main (Loop)
'################################################

Do
  
  
  '################################################
  '## Main (Train simulation)
  '################################################
  
  'calculate brake force, depending on FpsLimit
  'A Train driving at slow speed should stop 
  'within a station (125m)
  
  BrakeSteps=1400/(FpsLimit*FpsLimit)
  

  ' move train
  
  If (tsmode=ts_run) _
  OrElse (tsmode=ts_control) _
  Then
    world_sim
  EndIf
  
  
  ScanCam+=1
  If ScanCam>=CScanCam Then
    ScanCam=0
  EndIf

  
  '################################################
  '## Main (Show frame or skip, if CPU is too slow)
  '################################################
  
  
  g.PrintFrame=0
  If (g.SkipFrame=0) Then g.PrintFrame=1
  If (g.SkipFrame=1) Then g.PrintFrame=1
  If (g.SkipFrame>1) Then
    If (g.Frame Mod g.SkipFrame)=0 Then g.PrintFrame=1
  EndIf
  
  
  '################################################
  '## Main (Draw Graphics) - end
  '################################################
  
  If g.PrintFrame Then
    
    'highlight window under mouse cursor
    If MouseWindow=1 Then
      Line(0,0)-(MainViewX+2,MainViewY+2),&Hffffff,B
    Else
      Line(0,0)-(MainViewX+2,MainViewY+2),&Ha0a0a0,B
    EndIf

    If MouseWindow=2 Then
      Line(MainViewW+2,0)-(ScreenX,SideViewY+2),&Hffffff,B
    Else
      Line(MainViewW+2,0)-(ScreenX,SideViewY+2),&Ha0a0a0,B
    EndIf

    If MouseWindow=3 Then
      Line(MainViewW+2,SideViewH+2)-(ScreenX,(SideViewH+2)*2-1),&Hffffff,B
    Else
      Line(MainViewW+2,SideViewH+2)-(ScreenX,(SideViewH+2)*2-1),&Ha0a0a0,B
    EndIf

    If MouseWindow=4 Then
      Line(MainViewW+2,(SideViewH+2)*2)-(ScreenX,ScreenY),&Hffffff,B
    Else
      Line(MainViewW+2,(SideViewH+2)*2)-(ScreenX,ScreenY),&Ha0a0a0,B
    EndIf

    'Display this frame
    
    'Main window
    world_render(win480, -1)
    
    'put window win480 later... after LoopEdit
    'Put(v.PosX,v.PosY),win480,PSet

    'Save current status in View1
    'Do that after "world_render" because auto-camera control
    'will change views Offsets
    View1=v
    wView1=wv
    
    
    '################################################
    '## Right top window
    '################################################
    
    'Right top window
    'Set View2 as active window
    v=View2
    wv=wView2
    If InTime(4) Then
      world_render(win160, 4)
    Else
      Line win160,(0,0)-Step(v.WinX,v.WinY),&H305030,BF
    EndIf
    
    
    'Menu draw
    DrawMenu(g.mousex,g.mousey,win160)
    
    
'    'show hand
'    'mouse cursor (indicating drag)
'    If MouseCursor=0 AndAlso (MouseWindow=2) Then
'      Put win160, (g.MouseX-5, g.MouseY), MenuIcon(0,1), trans
'    EndIf

    'show drag symbol
    'mouse cursor (indicating drag)
    If MouseCursor=0 AndAlso (MouseWindow=2) Then
      Put win160, (g.MouseX-12, g.MouseY-12), MenuIcon(83,2), trans
    EndIf
    
    
    Put(wv.PosX,wv.PosY),win160,PSet
    
    
    
    '################################################
    '## Right mid window
    '################################################
    
    
    'Right mid window
    'Set View3 as active window
    v=View3
    wv=wView3
    If InTime(4) Then
      world_render(win160, 4)
    Else
      Line win160,(0,0)-Step(v.WinX,v.WinY),&H305030,BF
    EndIf
    Put(wv.PosX,wv.PosY),win160,PSet
    
    
    
    '################################################
    '## Right bottom window
    '################################################

    'Right bottom window
    'Displays a fix zoomed View1 center
    'Set View1 as active window
    v=View1
    wv=wView1
    'i,j= current center position
    i=SCX:j=SCY
    'Rescale window to 160*160 Pixel
    v.WinX=View2.WinX
    v.WinY=View2.WinY
    wv.VisBorderX=wView2.VisBorderX
    wv.VisBorderY=wView2.VisBorderY
    'Set new scale factor
    'v.Scale=v.Scale*0.5
    v.Scale=500
    'Center screen
    ScreenCenter(i,j,v)
    'Set window position to lower right
    wv.PosX=(MainViewW+2)+1
    wv.PosY=(SideViewH+2)*2+1

    'No debug display
    v.Debug=0

    'Render the view
    If InTime(4) Then
      world_render(win160, 4)
    Else
      Line win160,(0,0)-Step(v.WinX,v.WinY),&H305030,BF
    EndIf
    
    'Draw Controller
    ts_DrawController(v, win160)
    
    Put(wv.PosX,wv.PosY),win160,PSet
    
    
    'Set View1 as active window
    v=View1
    wv=wView1
        
  EndIf
  
  
  '################################################
  '## Main (Mouse control)
  '################################################
  
  
  g.Mousexs=g.Mousex
  g.Mouseys=g.Mousey
  g.Mousewhs=g.Mousewh
  g.Mousebts=g.Mousebt

  If g.Mousebt=0 Then
    g.Mousehold=0
    g.KlickStart=0
  EndIf
  If g.Mousebt<>g.Mousebts Then g.Mousehold=0
  If (g.Mousebt<>0) And (g.Mousebt=g.Mousebts) Then g.Mousehold+=1
  
  GetMouse g.MouseX, g.MouseY, g.MouseWh, g.MouseBt
  
  If g.Mousex<0 Then
    g.Mousex=v.WinX/2
    g.Mousey=v.WinY/2
    g.Mousewh=g.Mousewhs
    g.Mousebt=0
  EndIf
  
  'check for window area under mouse cursor
  If g.Mousex>=1 AndAlso g.Mousex<v.WinX _
  AndAlso g.Mousey>=1 AndAlso g.Mousey<v.WinY Then
    If MouseWindow<>1 Then
      MouseWindow=1
      g.Mousexs=g.Mousex'+MainViewW
      g.Mouseys=g.Mousey
      g.Mousewhs=g.Mousewh
      g.Mousebts=0
    EndIf
  ElseIf g.Mousex>(MainViewW+3) AndAlso g.Mousex<ScreenX _
  AndAlso g.Mousey>1 AndAlso g.Mousey<SideViewH+1 Then
    If MouseWindow<>2 Then
      MouseWindow=2
      g.Mousexs=g.Mousex-MainViewW
      g.Mouseys=g.Mousey
      g.Mousewhs=g.Mousewh
      g.Mousebts=0
    EndIf
  ElseIf g.Mousex>MainViewW+3 AndAlso g.Mousex<ScreenX _
  AndAlso g.Mousey>(SideViewH+3) AndAlso g.Mousey<(SideViewH*2+3) Then
    If MouseWindow<>3 Then
      MouseWindow=3
      g.Mousexs=g.Mousex-MainViewW
      g.Mouseys=g.Mousey
      g.Mousewhs=g.Mousewh
      g.Mousebts=0
    EndIf
  ElseIf g.Mousex>MainViewW+3 AndAlso g.Mousex<ScreenX _
  AndAlso g.Mousey>(SideViewH*2+5) AndAlso g.Mousey<ScreenY Then
    If MouseWindow<>4 Then
      MouseWindow=4
      g.Mousexs=g.Mousex-MainViewW
      g.Mouseys=g.Mousey
      g.Mousewhs=g.Mousewh
      g.Mousebts=0
    EndIf
  Else
    MouseWindow=0
  EndIf
  
  'To avoid drag-confusion, remember the view, where the click started
  If (g.Mousebt<>0) And (g.KlickStart=0) Then g.KlickStart=MouseWindow

  
  
'  'check for window area under mouse cursor
'  If g.Mousex>=1 AndAlso g.Mousex<v.WinX _
'  AndAlso g.Mousey>=1 AndAlso g.Mousey<v.WinY Then
'    MouseWindow=1
'  ElseIf g.Mousex>(MainViewW+3) AndAlso g.Mousex<ScreenX _
'  AndAlso g.Mousey>1 AndAlso g.Mousey<SideViewH+1 Then
'    MouseWindow=2
'  ElseIf g.Mousex>MainViewW+3 AndAlso g.Mousex<ScreenX _
'  AndAlso g.Mousey>(SideViewH+3) AndAlso g.Mousey<(SideViewH*2+3) Then
'    MouseWindow=3
'  ElseIf g.Mousex>MainViewW+3 AndAlso g.Mousex<ScreenX _
'  AndAlso g.Mousey>(SideViewH*2+5) AndAlso g.Mousey<ScreenY Then
'    MouseWindow=4
'  Else
'    MouseWindow=0
'  EndIf
  
  
  'menu control by mouse
  MenuCall
  
  If MouseWindow>1 Then
    g.Mousex=g.Mousex-MainViewW-3
  EndIf
  
  
  
  'Select control by mouseclick
  If (MouseWindow=1) AndAlso (g.Mousebt=0) _
  AndAlso (g.Mousebts=1) AndAlso (g.Mousehold<=(g.Fps/click+g.SkipFrame)) Then
    
    'first try to switch something
    'switch turnout
    i=0
    j=0
    Do
      i+=1
      If w.Turnouts(i)<>0 Then
        If Abs(xcoor(w.Turnouts(i)->SwitchCoor.x)-g.Mousex) < (5+2*m/v.Scale) _
        And Abs(ycoor(w.Turnouts(i)->SwitchCoor.y)-g.Mousey) < (5+2*m/v.Scale) Then
          j=i
        EndIf
      EndIf
    Loop Until (i>=MaxTurnouts) ' fxm inspired patch - see http://www.freebasic.net/forum/viewtopic.php?p=160305#160305

    If j<>0 Then
      SwitchTurnout(w.Turnouts(j))
    EndIf
    
    'if switch was successful, then j<>0
    'if not, try to select something
    
    If j=0 Then
      If g.trksel=0 Then
        'Just do, if track editor not active
        'select train
        wv.cam=0
        g.ctrl=0
        g.trksel=0
        g.ItemSel=0
      EndIf
    
      
      Do
        j+=1
        
        'select track
        
        If tsmode=ts_edittrack Then
          
          If g.es=es_PlaceTrack Then
            'edit state: place new track
            ts_te_NewTrackMP
            g.es=es_off
          Else
            'try to select a track
            For i=1 To maxtracks
              If w.Start(i)<>0 Then
                If Abs(xcoor(w.Start(i)->x)-g.Mousex) < (5+4*m/v.Scale) _
                And Abs(ycoor(w.Start(i)->y)-g.Mousey) < (5+4*m/v.Scale) Then
                  g.trksel=i
                  g.EditTrk=g.trksel
                  g.EditTrkBasePtr=w.Start(g.trksel)
                  g.EditTrkPtr=g.EditTrkBasePtr->last
                EndIf
              EndIf
            Next
          EndIf
        
        
          'select subtrack while editing a track
          For i=1 To MaxTracks
            If w.Start(i)<>NULL Then
            'If (g.EditTrkPtr<>0) And (g.EditTrkBasePtr<>0) Then
              Dim As PTrack SearchTrack
              SearchTrack=w.Start(i)->start
              'SearchTrack=g.EditTrkBasePtr->start
              Do While (SearchTrack<>w.Start(i)->last)
                If Abs(xcoor(SearchTrack->x)-g.Mousex) < (5+2*m/v.Scale) _
                And Abs(ycoor(SearchTrack->y)-g.Mousey) < (5+2*m/v.Scale) Then
                  If SearchTrack<>0 Then
                    g.EditTrkPtr=SearchTrack
                    g.trksel=i
                    g.EditTrk=i
                    g.EditTrkBasePtr=w.Start(i)
                  EndIf
                EndIf
                SearchTrack=SearchTrack->pn
              Loop
            EndIf
          Next i
        EndIf
  
        If g.trksel<>0 Then Exit Do
        
        If g.trksel=0 Then
          If g.es<>es_PlaceItem Then
            'Just do, if track editor not active
            'select train
            For i=1 To maxtrains
              If w.Train(i)<>0 Then
                If Abs(xcoor(w.Train(i)->x)-g.Mousex) < (j+4*m/v.Scale) _
                And Abs(ycoor(w.Train(i)->y)-g.Mousey) < (j+4*m/v.Scale) Then
                  g.ctrl=i
                  If (tsmode=ts_run) Then
                    MenuSwitch(MenuName1)
                  EndIf
                EndIf
              EndIf
            Next
            
            If g.ctrl<>0 Then Exit Do
          EndIf
          
          'select item (if in place mode)
          
          If tsmode=ts_build Then
            For i=1 To MaxItems
              If w.Items(i)<>0 Then 
                  If Abs(xcoor(w.Items(i)->a.x)-g.Mousex) < (10+4*m/v.Scale) _
                  And Abs(ycoor(w.Items(i)->a.y)-g.Mousey) < (10+4*m/v.Scale) Then
                    g.ItemSel=i
                  EndIf
              EndIf
            Next
          EndIf
          
          If g.ItemSel<>0 Then Exit Do
        EndIf        
      Loop Until (j>50)
    EndIf
     
  EndIf


'  If (MouseWindow=1) AndAlso (Menu.MouseOver=0) _

  'Drag map by mouse when holding mousebutton
  If (MouseWindow=1) _
  AndAlso (g.KlickStart=MouseWindow) _
  AndAlso (g.Mousehold>(g.Fps/click+g.SkipFrame)) Then
    If g.Mousebt=1 Then
      If g.trksel<>0 Then
        'If distance between mouse and track is too big.
        'then unselect track
        If Abs(xcoor(w.Start(g.trksel)->x)-g.Mousex)<50 _
        and Abs(ycoor(w.Start(g.trksel)->y)-g.Mousey)<50 Then
          w.Start(g.trksel)->x=p2wx(g.Mousex)
          w.Start(g.trksel)->y=p2wy(g.Mousey)
          ActivateTrack(w.Start(g.trksel))
        Else
          g.trksel=0
        EndIf
      Else
        If g.ItemSel<>0 Then

          'remember if drag point a or b
          If g.Drag=0 Then
            'Move item point A
            If Abs(xcoor(w.Items(g.ItemSel)->a.x)-g.Mousex)<20 _
            And Abs(ycoor(w.Items(g.ItemSel)->a.y)-g.Mousey)<20 Then
              g.Drag=1
              'Move item point B
            ElseIf Abs(xcoor(w.Items(g.ItemSel)->b.x)-g.Mousex)<20 _
              And Abs(ycoor(w.Items(g.ItemSel)->b.y)-g.Mousey)<20 Then
              g.Drag=2
            EndIf
          EndIf
          
          'Move item point A
          If g.Drag=1 Then
            i=w.Items(g.ItemSel)->b.x-w.Items(g.ItemSel)->a.x
            j=w.Items(g.ItemSel)->b.y-w.Items(g.ItemSel)->a.y
            w.Items(g.ItemSel)->a.x=p2wx(g.Mousex)
            w.Items(g.ItemSel)->a.y=p2wy(g.Mousey)
            w.Items(g.ItemSel)->b.x=w.Items(g.ItemSel)->a.x+i
            w.Items(g.ItemSel)->b.y=w.Items(g.ItemSel)->a.y+j
            'Move item point B
          ElseIf g.Drag=2 Then
              w.Items(g.ItemSel)->b.x=p2wx(g.Mousex)
              w.Items(g.ItemSel)->b.y=p2wy(g.Mousey)
          EndIf

        Else
        'drag map
          wv.cam=0
          'allow endless drag
          If EndlessDrag Then
            
            'accelerated drag function
            If Abs(g.Mousex-g.Mousexs)>MouseAcclevel _
            OrElse Abs(g.Mousey-g.Mouseys)>MouseAcclevel Then
              v.Offx=v.Offx+(g.Mousex-g.Mousexs)*EndlessDrag
              v.Offy=v.Offy+(g.Mousey-g.Mouseys)*EndlessDrag
            Else
              v.Offx=v.Offx+(g.Mousex-g.Mousexs)
              v.Offy=v.Offy+(g.Mousey-g.Mouseys)
            EndIf
            
'            If g.MouseX<v.WinX/5 _
'            OrElse g.MouseY<v.WinY/5 _
'            OrElse g.MouseX>v.WinX/5*4 _
'            OrElse g.MouseY>v.WinY/5*4 _
            
            'hold mouse pointer at center of screen when drag the map
            If g.MouseX<>v.WinX/2 _
            OrElse g.MouseY<>v.WinY/2 _
            Then
              g.MouseX=v.WinX/2
              g.MouseY=v.WinY/2
              g.MouseXS=g.MouseX
              g.MouseYS=g.MouseY
              SetMouse g.MouseX,g.MouseY
            EndIf
            
          Else
            v.Offx=v.Offx+g.Mousex-g.Mousexs
            v.Offy=v.Offy+g.Mousey-g.Mouseys
          EndIf
        EndIf
      EndIf
    Else
      g.Drag=0 'drag inactive
    EndIf
  EndIf


  'Drag map in window 2 by mouse when holding mousebutton
  If (MouseWindow=2) _
  AndAlso (g.KlickStart=MouseWindow) _
  AndAlso (Menu.MouseOver=0) _
  AndAlso (g.Mousehold>(g.Fps/click+g.SkipFrame)) Then
    If g.Mousebt=1 Then
      'allow endless drag
      If EndlessDrag Then
      
        'accelerated drag function
        If Abs(g.Mousex-g.Mousexs)>MouseAcclevel _
        OrElse Abs(g.Mousey-g.Mouseys)>MouseAcclevel Then
          view2.Offx=view2.Offx+(g.Mousex-g.Mousexs)*EndlessDrag
          view2.Offy=view2.Offy+(g.Mousey-g.Mouseys)*EndlessDrag
        Else
          view2.Offx=view2.Offx+(g.Mousex-g.Mousexs)
          view2.Offy=view2.Offy+(g.Mousey-g.Mouseys)
        EndIf
        
'        If g.MouseX<view2.WinX/5 _
'        OrElse g.MouseY<view2.WinY/5 _
'        OrElse g.MouseX>view2.WinX/5*4 _
'        OrElse g.MouseY>view2.WinY/5*4 _
        
        'hold mouse pointer at center of screen when drag the map
        If g.MouseX<>view2.WinX/2 _
        OrElse g.MouseY<>view2.WinY/2 _
        Then
          g.MouseX=view2.WinX/2
          g.MouseY=view2.WinY/2
          g.MouseXS=g.MouseX
          g.MouseYS=g.MouseY
          SetMouse MainViewW+g.MouseX+3,g.MouseY
        EndIf
        
      Else
        view2.Offx=view2.Offx+g.Mousex+3-g.Mousexs
        view2.Offy=view2.Offy+g.Mousey-g.Mouseys      EndIf
    Else
      g.Drag=0 'drag inactive
    EndIf
  EndIf
  
  
'################################################
'## Main (Keyboard control - 1)
'################################################
  
  
  ks=InKey$


'################################################
'## Main - Menu action
'## after 'inkeys' mouse action
'## overwrite command string ks
'################################################


  MenuByMouse
  
  
  'Select control by mouseclick
  If (MouseWindow=1) AndAlso (g.Mousebt=0) _
  AndAlso (g.Mousebts=1) AndAlso (g.Mousehold<=(g.Fps/click+g.SkipFrame)) Then
    
    'menu test - place item by mouseclick
    
    If (tsmode=ts_build) AndAlso (g.es=es_PlaceItem) Then
      ks="New Item"
      g.es=es_off
    EndIf

    'menu test - previous button
    If (Menu.Cmd="next") AndAlso (Menu.CmdState=1) Then
      ks=Menu.Cmd
    EndIf

    'menu test - next button
    If (Menu.Cmd="prev") AndAlso (Menu.CmdState=1) Then
      ks=Menu.Cmd
    EndIf
  EndIf
  
  
  
'################################################
'## Main (Keyboard control - 2)
'################################################


  If ks=Chr(255)+Chr(15) Then ks=ks+InKey$  'Detect Shift TAB
  
  If ks=k_help Then         'F1 Help
    ts_manual
  EndIf
  
  
  If ks=k_helpdisp Then     'Help Manual on/off
    ts_helpman
  EndIf
  
  
  If ks=k_ohd Then          'OHD on/off
    ts_ohd
  EndIf
  
  
  If ks=k_Controller Then   'Controller on/off
    ts_Controller
  EndIf
  
  
  '################################################
  '## Track editor
  '################################################
  
  
  '## Track editor (1):
  '## Functions that need a selected track
  
  'edit track

  If ks=MenuName3 Then
    ts_te_start
  EndIf
  
  
  'edit track (open/close track)
  If (ks="Open Track") Then
    If g.trksel=0 Then
      Message("Select track first")
    Else
      OpenCloseTrack(w.Start(g.trksel))
    EndIf
  EndIf
  
  
  'edit track (open track)
  If (ks=K_edittrackOpen) Then
    If g.trksel=0 Then
      Message("Select track first")
    Else
      OpenTrack(w.Start(g.trksel))
    EndIf
  EndIf
  
  'edit track (close track)
  If (ks=K_edittrackClose) Then
    If g.trksel=0 Then
      Message("Select track first")
    Else
      CloseTrack(w.Start(g.trksel))
    EndIf
  EndIf
  
  
  '## Track editor (2):
  '## Functions that need a valid v.EditTrkPtr
  
  
  If (g.EditTrkPtr<>0) Then
    
    'edit track, install/uninstall turnout
    If (ks=K_edittrackInstallTurnout) OrElse (ks="Build Turnout") Then
      ts_te_InstallTurnout
    EndIf
    
    'edit track (select previous)
    If (ks=k_edittrackPrev) OrElse (ks="Track Cursor -") Then
      ts_te_prev
    EndIf
    
    'edit track (select next)
    If (ks=k_edittrackNext) OrElse (ks="Track Cursor +") Then
      ts_te_Next
    EndIf
    
    'edit track (set track station)
    If ks=K_edittrackStation Then
      ts_te_SetStation
    EndIf
    
'    'edit track (set track forward)
'    If ks=K_edittrackForward Then
'      ts_te_SetForward
'    EndIf
'    
    'edit track (set track left)
    If ks=K_edittrackLeft Then
      ts_TrackTurnLeft
'      ts_te_SetLeft
    EndIf
    
    'edit track (set track right)
    If ks=K_edittrackRight Then
      ts_TrackTurnRight
'      ts_te_SetRight
    EndIf
    
'    'edit track (set track left)
'    If ks=K_edittrackSharpLeft Then
'      ts_te_SetSharpLeft
'    EndIf
'    
'    'edit track (set track right)
'    If ks=K_edittrackSharpRight Then
'      ts_te_SetSharpRight
'    EndIf
    
    'edit track (set track visible)
    If (ks=K_edittrackVisible) OrElse (ks="Visible Track") Then
      ts_te_SetVisible
    EndIf
    
    'edit track (set track end segment)
    If ks=K_edittrackEndtrack Then
      ts_te_SetEnd
    EndIf
    
    'edit track (insert new track)
    If (ks=K_edittrackInsert) OrElse (ks="Rail Insert") Then
      ts_te_insert
    EndIf
    
    'edit track (delete track)
    If (ks=K_edittrackDeleteBS) OrElse (ks="Rail Remove") Then
      ts_te_delete
    EndIf
    
  EndIf


  'edit track (dset length)
  If (tsmode=ts_edittrack) _
  AndAlso (InStr("1234567890",ks)>0) Then
    ts_te_setlength
  EndIf
  
  
  '## Track editor (3):
  '## Other Functions
  
  
  'edit track signal f/r
  If ks=K_EditTrackSignal Then
    ts_te_signal
  EndIf
  
  
  '################################################
  '## Track editor end
  '################################################
  
  
  'switch turnout from selected train
    
  'switch turnout in forward direction
  If (ks=K_SwitchTurnout) OrElse (ks="Ctrl Turn F") Then
    ts_SwitchTunoutFwd
  EndIf
  
  
  'switch turnout in reverse direction
  If (ks=K_SwitchTurnoutReverse) OrElse (ks="Ctrl Turn R") Then
    ts_SwitchTurnoutRev
  EndIf
  
  
  If ((ks="Delete") OrElse (ks=K_Delete))_
  AndAlso (tsmode=ts_build) _
   Then
    If g.ctrl<>0 Then
      ts_DeleteTrain
    ElseIf g.ItemSel<>0 Then
      ts_DeleteItem
    EndIf
  EndIf
  
  
  If (ks="Train Name") Then
    ts_TrainName
  EndIf
  
  
  ' add new item
  If (ks="New Item") Then
    ts_NewItem
  EndIf
  
  
  'Control speed of selected train
  If (ks=K_AccRevMore) And (g.ctrl>0) Then
    w.Train(g.ctrl)->sp -=SpeedScale
    If SpeedLimit AndAlso (w.Train(g.ctrl)->sp < -w.Train(g.ctrl)->MaxSpeed*SpeedScale) Then
      w.Train(g.ctrl)->sp = -w.Train(g.ctrl)->MaxSpeed*SpeedScale
    EndIf
    w.Train(g.ctrl)->state=ts_drive
    w.Train(g.ctrl)->AutoSpeed=0
  EndIf
  
  If (ks=K_AccFwdMore) And (g.ctrl>0) Then
    w.Train(g.ctrl)->sp +=SpeedScale
    If SpeedLimit AndAlso (w.Train(g.ctrl)->sp > w.Train(g.ctrl)->MaxSpeed*SpeedScale) Then
      w.Train(g.ctrl)->sp = w.Train(g.ctrl)->MaxSpeed*SpeedScale
    EndIf
    w.Train(g.ctrl)->state=ts_drive
    w.Train(g.ctrl)->AutoSpeed=0
  EndIf
  
  
'  Const Speedlevels=14
'  Dim As Integer speedlevel(Speedlevels)=>{ _
'    0, 5, 10, 15, 20, 30, 40, 50, _
'    60, 70, 80, 90, 100, 110, 120}
'    
'  If ((ks="Ctrl Speed +") OrElse (ks=K_AccMore))_
'  AndAlso (tsmode=ts_control) _
'  AndAlso w.Train(g.ctrl)<>NULL _
'  Then
'    w.Train(g.ctrl)->state=drive
'    i=Abs(w.Train(g.ctrl)->sp)/SpeedScale
'    For j=1 To Speedlevels
'      If i<speedlevel(j) Then Exit For
'    Next
'    If (w.Train(g.ctrl)->sp>=0) Then
'      w.Train(g.ctrl)->AutoSpeed=speedlevel(j)
'    Else
'      w.Train(g.ctrl)->AutoSpeed=-speedlevel(j)
'    EndIf
'  EndIf
'  
'  
'  If ((ks="Ctrl Speed -") OrElse (ks=K_AccLess)) _
'  AndAlso (tsmode=ts_control) _
'  AndAlso w.Train(g.ctrl)<>NULL _
'  Then
'    w.Train(g.ctrl)->state=drive
'    i=Abs(w.Train(g.ctrl)->sp)/SpeedScale
'    For j=Speedlevels To 0 Step -1
'      If i>speedlevel(j) Then Exit For
'    Next
'    i=speedlevel(j)
'    'set autospeed
'    If (w.Train(g.ctrl)->sp >= 0) Then
'      w.Train(g.ctrl)->AutoSpeed=i
'    Else
'      w.Train(g.ctrl)->AutoSpeed=-i
'    EndIf
'    'if speed set to 0, then brake
'    If i=0 Then
'      w.Train(g.ctrl)->control=brake
'    EndIf
'  EndIf
  
  
'  Const Speedlevels=28
'  Dim As Integer speedlevel(Speedlevels)=>{ _
'    -120, -110, -100, -90, -80, -70, -60, _
'    -50, -40, -30, -20, -15, -10, -5, _
'    0, 5, 10, 15, 20, 30, 40, 50, _
'    60, 70, 80, 90, 100, 110, 120}
'    
'  If ((ks="Ctrl Speed +") OrElse (ks=K_AccMore))_
'  AndAlso (tsmode=ts_control) _
'  AndAlso w.Train(g.ctrl)<>NULL _
'  Then
'    w.Train(g.ctrl)->state=ts_drive
'    i=(w.Train(g.ctrl)->sp)\SpeedScale
'    For j=0 To Speedlevels
'      If i<speedlevel(j) Then Exit For
'    Next
'    'set autospeed
'    If j<=Speedlevels Then
'      w.Train(g.ctrl)->AutoSpeed=speedlevel(j)
'      'if speed set to 0, then brake
'      If speedlevel(j)=0 Then
'        w.Train(g.ctrl)->control=brake
'      EndIf
'    EndIf
'  EndIf
'  
'  
'  If ((ks="Ctrl Speed -") OrElse (ks=K_AccLess)) _
'  AndAlso (tsmode=ts_control) _
'  AndAlso w.Train(g.ctrl)<>NULL _
'  Then
'    w.Train(g.ctrl)->state=ts_drive
'    i=(w.Train(g.ctrl)->sp)\SpeedScale
'    For j=Speedlevels To 0 Step -1
'      If i>speedlevel(j) Then Exit For
'    Next
'    'set autospeed
'    If j>=0 Then
'      w.Train(g.ctrl)->AutoSpeed=speedlevel(j)
'      'if speed set to 0, then brake
'      If speedlevel(j)=0 Then
'        w.Train(g.ctrl)->control=brake
'      EndIf
'    EndIf
'  EndIf
  
  
  If ((ks="Ctrl Speed +") OrElse (ks=K_AccMore))_
  AndAlso (tsmode=ts_control) _
  AndAlso w.Train(g.ctrl)<>NULL _
  Then
    w.Train(g.ctrl)->state=ts_drive
    If w.Train(g.ctrl)->AutoSpeed<>0 Then
      w.Train(g.ctrl)->AutoSpeed+=1
    Else
      If w.Train(g.ctrl)->control=brake Then
        w.Train(g.ctrl)->AutoSpeed+=1
      Else
        w.Train(g.ctrl)->AutoSpeed=w.Train(g.ctrl)->sp\SpeedScale+1
      EndIf
    EndIf
    If SpeedLimit _
    AndAlso (w.Train(g.ctrl)->AutoSpeed > w.Train(g.ctrl)->MaxSpeed) Then
      w.Train(g.ctrl)->AutoSpeed = w.Train(g.ctrl)->MaxSpeed
    EndIf
    If Abs(w.Train(g.ctrl)->AutoSpeed)<1 Then
      w.Train(g.ctrl)->control=brake
    EndIf
  EndIf
  
  
  If ((ks="Ctrl Speed -") OrElse (ks=K_AccLess)) _
  AndAlso (tsmode=ts_control) _
  AndAlso w.Train(g.ctrl)<>NULL _
  Then
    w.Train(g.ctrl)->state=ts_drive
    If w.Train(g.ctrl)->AutoSpeed<>0 Then
      w.Train(g.ctrl)->AutoSpeed-=1
    Else
      If w.Train(g.ctrl)->control=brake Then
        w.Train(g.ctrl)->AutoSpeed-=1
      Else
        w.Train(g.ctrl)->AutoSpeed=w.Train(g.ctrl)->sp\SpeedScale-1
      EndIf
    EndIf
    If SpeedLimit _
    AndAlso (w.Train(g.ctrl)->AutoSpeed < -w.Train(g.ctrl)->MaxSpeed) Then
      w.Train(g.ctrl)->AutoSpeed = -w.Train(g.ctrl)->MaxSpeed
    EndIf
    If Abs(w.Train(g.ctrl)->AutoSpeed)<1 Then
      w.Train(g.ctrl)->control=brake
    EndIf
  EndIf
  
  
  If (ks="Train Slow") AndAlso (tsmode=ts_control) _
  AndAlso w.Train(g.ctrl)<>NULL _
  Then
    w.Train(g.ctrl)->state=ts_drive
    If (w.Train(g.ctrl)->sp >= 0) Then
      w.Train(g.ctrl)->AutoSpeed=SlowSpeed
    Else
      w.Train(g.ctrl)->AutoSpeed=-SlowSpeed
    EndIf
  EndIf
  
  
  If (ks="Train Fast") AndAlso (tsmode=ts_control) _
  AndAlso w.Train(g.ctrl)<>NULL _
  Then
    w.Train(g.ctrl)->state=ts_drive
    If (w.Train(g.ctrl)->sp >= 0) Then
      w.Train(g.ctrl)->AutoSpeed=FastSpeed
    Else
      w.Train(g.ctrl)->AutoSpeed=-FastSpeed
    EndIf
  EndIf
  
  
'  If (ks="Ctrl Forward") AndAlso (tsmode=ts_control) _
'  AndAlso w.Train(g.ctrl)<>NULL _
'  Then
'    w.Train(g.ctrl)->state=drive
'    If Abs(w.Train(g.ctrl)->sp)<=(10*SpeedScale) Then
'      w.Train(g.ctrl)->AutoSpeed=5
'    EndIf
'  EndIf
'  
'  
'  If ((ks="Ctrl Backward") OrElse (ks=K_AccReverse))_
'  AndAlso (tsmode=ts_control) _
'  AndAlso w.Train(g.ctrl)<>NULL _
'  Then
'    w.Train(g.ctrl)->state=drive
'    If Abs(w.Train(g.ctrl)->sp)<=(10*SpeedScale) Then
'      w.Train(g.ctrl)->AutoSpeed=-5
'    EndIf
'  EndIf
  
  
  If (ks=K_Plus) AndAlso (tsmode=ts_build) Then
    ts_TrainCarAdd
  EndIf
  
  
  If (ks=K_Minus) AndAlso (tsmode=ts_build) Then
    ts_TrainCarSub
  EndIf
  
  
  If ks=K_Plus Then
    ts_ItemChangeNext
  EndIf
  
  
  If ks=K_Minus Then
    ts_ItemChangePrev
  EndIf
  
  
  If ks="Model +" Then
    If g.ItemSel<>0 Then
      ts_ItemChangeNext
    ElseIf g.ctrl<>0 Then
      ts_TrainPicNext
    EndIf
  EndIf
  
  
  If ks="Model -" Then
    If g.ItemSel<>0 Then
      ts_ItemChangePrev
    ElseIf g.ctrl<>0 Then
      ts_TrainPicPrev
    EndIf
  EndIf
  
  
  'Menu train control
  If (ks="Car Model +") Then
    ts_CarPicNext
  EndIf
  
  'Menu train control
  If (ks="Car Model -") Then
    ts_CarPicPrev
  EndIf

  
  
  
  
  
  If (tsmode=ts_edittrack) Then
  
    If (ks="Track Name") Then
      ts_te_name
    EndIf
    
    
    If (ks="Turn Left") Then
      ts_TrackTurnLeft
    EndIf
    
    
    If (ks="Turn Right") Then
      ts_TrackTurnRight
    EndIf
    
    
    If (ks="Signal Fwd") Then
      ts_TrackSigFwd
    EndIf
    
    
    If (ks="Signal Rev") Then
      ts_TrackSigRev
    EndIf
    
    
    If (ks="Place Track") Then
      If g.es<>es_PlaceTrack Then
        Message("Click on the Map to place a Track")
        ts_TrackPlaceNew
      Else
        g.es=es_Off
      EndIf
    EndIf
    
    
    If (ks="Select Track") Then
      ts_te_SelectTrack
    EndIf
    
    
  '  If (tsmode=ts_edittrack) AndAlso (ks="Select Track +") Then
  '    ts_te_SelectNextTrack
  '  EndIf
  '  
  '  
  '  If (tsmode=ts_edittrack) AndAlso (ks="Select Track -") Then
  '    ts_te_SelectPrevTrack
  '  EndIf
  '  
  '  
    If ((ks=K_edittrackDelete) OrElse (ks="Remove Track")) Then
      ts_DeleteTrack
    EndIf
    
    
    If (ks="Track Shorter") Then
      ts_te_setshorter
    EndIf
    
    
    If (ks="Track Longer") Then
      ts_te_setlonger
    EndIf
    
    
    If (ks="Rotate Left") Then
      ts_RotateTrackLeft
    EndIf
    
    
    If (ks="Rotate Right") Then
      ts_RotateTrackRight
    EndIf
  EndIf
  
  
  If (tsmode=ts_build) AndAlso (ks="New Item/Train") Then
    If g.es<>es_PlaceItem Then
      If g.trksel<>0 Then
        'place new train
        If "y"=YesOrNoBox("Place a new Train?") Then
          'Add train to track
          NewTrain(g.trksel, 10*SpeedScale, _
          ModelIndex("Red Train")+g.trksel Mod  4, _
          ModelIndex("Brown Car")+g.trksel Mod  4, 2)
        EndIf
      Else
        'place item
        Message("Click to place item (Select track to place train)")
        g.es=es_PlaceItem
      EndIf
    Else
      g.es=es_Off
    EndIf
  EndIf
  
  
  'Switch menu on/off
  If ks=K_MenuVisible Then
    Menu.Fade=255
    Menu.Alpha=-255*(Menu.Alpha<255)
  EndIf

  'Switch grid on/off (performance)
  If ks=K_grid Then wv.gridon=(wv.gridon=0)

  'Switch map on/off (performance)
  If ks=K_map Then wv.mapactive=(wv.mapactive=0)

  'Switch landmap on/off (performance)
  If ks=K_landmap Then wv.landmapactive=(wv.landmapactive=0)

  'Switch debug on/off
  If ks=K_debug Then v.Debug=(v.Debug=0)

  
  'Zoom in
  'Zoom to center of screen
  If Right$(ks,2)=k_zoomin Then    'PG up
    If v.Scale>ZoomMinLevel Then
      i=SCX
      j=SCY
      v.Scale=v.Scale*9/10
      ScreenCenter(i,j,v)
    EndIf
  EndIf
  
  'Zoom out
  'Zoom to center of screen
  If Right$(ks,2)=k_zoomout Then  'PG down
    If v.Scale<ZoomMaxLevel Then
      i=SCX
      j=SCY
      v.Scale=v.Scale*10/9
      ScreenCenter(i,j,v)
    EndIf
  EndIf
  
  'Do only if mouse pointer is in window 1
  If (MouseWindow=1) Then
    'Zoom in
    'Zoom to mouse pointer
    If g.Mousewh-g.Mousewhs>0 Then 'Mouse wheel up
      If v.Scale>ZoomMinLevel Then
        i=p2wx(g.MouseX)
        j=p2wy(g.MouseY)
        v.Scale=v.Scale*9/10
        v.Offx=g.MouseX-i/v.Scale
        v.Offy=g.MouseY-j/v.Scale
      EndIf
    EndIf
    
    'Zoom out
    'Zoom to mouse pointer
    If g.Mousewh-g.Mousewhs<0 Then  'Mouse wheel down
      If v.Scale<ZoomMaxLevel Then
        i=p2wx(g.MouseX)
        j=p2wy(g.MouseY)
        v.Scale=v.Scale*10/9
        v.Offx=g.MouseX-i/v.Scale
        v.Offy=g.MouseY-j/v.Scale
      EndIf
    EndIf
  EndIf
  
  
  'Do only if mouse pointer is in window 2
  If (MouseWindow=2) _
  AndAlso Menu.MouseOver=0 _
  Then
    'Zoom in
    'Zoom to mouse pointer
    If g.Mousewh-g.Mousewhs>0 Then 'Mouse wheel up
      If view2.Scale>ZoomMinLevel Then
        i=p2wxw2(g.MouseX)
        j=p2wyw2(g.MouseY)
        view2.Scale=view2.Scale*9/10
        view2.Offx=g.MouseX-i/view2.Scale
        view2.Offy=g.MouseY-j/view2.Scale
      EndIf
    EndIf
    
    'Zoom out
    'Zoom to mouse pointer
    If g.Mousewh-g.Mousewhs<0 Then  'Mouse wheel down
      If view2.Scale<ZoomMaxLevel Then
        i=p2wxw2(g.MouseX)
        j=p2wyw2(g.MouseY)
        view2.Scale=view2.Scale*10/9
        view2.Offx=g.MouseX-i/view2.Scale
        view2.Offy=g.MouseY-j/view2.Scale
      EndIf
    EndIf
  EndIf
  
  
'  'set project folder
'  If ks="Project Folder" Then
'    'isolate folder name
'    '     ./data/
'    ' ->  data
'    DataPath=left(DataPath,Len(DataPath)-1)
'    DataPath=right(DataPath,Len(DataPath)-2)
'    'input new folder name
'    DataPath=InputBox("Set Project Folder Name",DataPath)
'    'rebuild DataPath
'    '     folder
'    ' ->  ./folder/
'    DataPath="./"+DataPath+"/"
'    'if folder do not exist, create empty folder
'    MkDir DataPath
'    LogFile("New project folder is set to "+DataPath)
'  EndIf
'
'
'  'save ini file
'  If ks="Save Ini" _
'  AndAlso "y"=YesOrNoBox("Save Ini File?") Then
'    SaveIniFileNew(InputBox("Save Ini File",CIniFileNew))
'  EndIf
'
'
'  'save model file
'  If ks="Save Model" _
'  AndAlso "y"=YesOrNoBox("Save File?") Then
'    SaveModelFileNew(InputBox("Save Model File",CModelFileNew))
'  EndIf
'
'
'  'save data file
'  If ks="Save Data" _
'  AndAlso "y"=YesOrNoBox("Save File?") Then
'    SaveDataFileNew(InputBox("Save Data File",CDataFileNew))
'  EndIf
'
'
'  'load data file
'  If ks="Load/Merge Data" _
'  AndAlso "y"=YesOrNoBox("Appand Tracks to existing Map?") Then
'    LoadFile(InputBox("Load Data File",CDataFileNew))
'  EndIf
'  
'  
'  'load model file
'  If ks="Load/Merge Model" _
'  AndAlso "y"=YesOrNoBox("Appand Tracks to existing Map?") Then
'    LoadFile(InputBox("Load Model File",CModelFileNew))
'  EndIf
'  
'  
'  'load new data file
'  If ks="Load New" _
'  AndAlso "y"=YesOrNoBox("Load new world?") Then
'    ts_DeleteWorld
'    LoadFile(CModelFileNew)
'    LoadFile(CDataFileNew)
'    MenuSwitch(MenuName0)
'  EndIf
  
  
  'delete the world
  If ks="New World" _
  AndAlso "y"=YesOrNoBox("Generate a new world?") Then
    ts_DeleteWorld
  EndIf
  
  
  If (ks="Export Track") Then
    ts_te_ExportTrack
  EndIf
  
  
  If (ks="Import Track") Then
    ts_te_ImportTrackHere
  EndIf
  
  
  
  'load files from folder
  If ks="Load" _
  AndAlso "y"=YesOrNoBox("Load new world?") Then
    'isolate folder name
    '     ./data/
    ' ->  data
    DataPath=left(DataPath,Len(DataPath)-1)
    DataPath=right(DataPath,Len(DataPath)-2)
    'input new folder name
    DataPath=InputBox("Enter Name",DataPath)
    'rebuild DataPath
    '     folder
    ' ->  ./folder/
    DataPath="./"+DataPath+"/"
    'if folder do not exist, create empty folder
    MkDir DataPath
    LogFile("Load - Name is set to "+DataPath)
    'load new data file
    ts_DeleteWorld
    LoadFile(CIniFileNew)
    LoadFile(CModelFileNew)
    LoadFile(CDataFileNew)
    MenuSwitch(MenuName0)
  EndIf
  
  
  
  'save files to folder
  If ks="Save" _
  AndAlso "y"=YesOrNoBox("Save?") Then
    'isolate folder name
    '     ./data/
    ' ->  data
    DataPath=left(DataPath,Len(DataPath)-1)
    DataPath=right(DataPath,Len(DataPath)-2)
    'input new folder name
    DataPath=InputBox("Enter Name",DataPath)
    'rebuild DataPath
    '     folder
    ' ->  ./folder/
    DataPath="./"+DataPath+"/"
    'if folder do not exist, create empty folder
    MkDir DataPath
    LogFile("Save - Name is set to "+DataPath)
    'save files
'    SaveIniFileNew(InputBox("Save Ini File",CIniFileNew))
'    SaveModelFileNew(InputBox("Save Model File",CModelFileNew))
'    SaveDataFileNew(InputBox("Save Data File",CDataFileNew))
    FileGeneration(CIniFileNew,3)
    SaveIniFileNew(CIniFileNew)
    FileGeneration(CModelFileNew,3)
    SaveModelFileNew(CModelFileNew)
    FileGeneration(CDataFileNew,3)
    SaveDataFileNew(CDataFileNew)
  EndIf


  
  
  
  'Select camera
  If InStr(K_SelectCamera,ks) AndAlso (tsmode<>ts_edittrack)Then
    i=InStr(K_SelectCamera,ks)
    If w.Train(i)<>0 Then
      
      'unselect all
'      g.Ctrl=0
'      v.Cam=0
      g.EditTrk=0
      g.TrkSel=0
      g.ItemSel=0
      g.EditTrkBasePtr=0
      g.EditTrkPtr=0
      g.EditTrkPtrA=0

      
      If CScanCamActive=0 AndAlso wv.cam<>0 Then
        wView3.cam=wv.cam   'set view 3 to last viewed train
      EndIf
      
      'camera animation setup
      wv.OldCamX=p2wx(v.WinX/2)
      wv.OldCamY=p2wy(v.WinY/2)
      
      wv.CamSlide=wv.CamSteps
      wv.OldCamScale=v.Scale
      
      
      wv.cam=i
      g.ctrl=wv.cam
      
      'If (Left$(ks,3)<>K_edittrackFlag) Then
      If (tsmode<>ts_edittrack) Then
      
        g.trksel=0    'unselect track, if track editor not active
      EndIf
      MenuSwitch(MenuName1)

    EndIf
  EndIf
  
  'Select control by TAB
  If ks=K_CtrlNext Then  'TAB
    Do
      g.ctrl=g.ctrl+1
      If g.ctrl>maxtrains Then g.ctrl=1
    Loop Until w.Train(g.ctrl)<>0
  EndIf
  If ks=K_CtrlPrev Then 'Shift+TAB
    Do
      g.ctrl-=1
      If g.ctrl=0 Then g.ctrl=maxtrains
    Loop Until w.Train(g.ctrl)<>0
  EndIf
  
  
  'Select control and camera to previous/next train
  If ks="Ctrl Select +" Then
    Do
      g.ctrl=g.ctrl+1
      If g.ctrl>maxtrains Then g.ctrl=1
    Loop Until w.Train(g.ctrl)<>0
    'camera animation setup
    wv.OldCamX=p2wx(v.WinX/2)
    wv.OldCamY=p2wy(v.WinY/2)
    wv.CamSlide=wv.CamSteps
    wv.OldCamScale=v.Scale
    wv.cam=g.ctrl
  EndIf
  
  
  If ks="Ctrl Select -" Then
    Do
      g.ctrl-=1
      If g.ctrl<=0 Then g.ctrl=maxtrains
    Loop Until w.Train(g.ctrl)<>0
    'camera animation setup
    wv.OldCamX=p2wx(v.WinX/2)
    wv.OldCamY=p2wy(v.WinY/2)
    wv.CamSlide=wv.CamSteps
    wv.OldCamScale=v.Scale
    wv.cam=g.ctrl
  EndIf

  
  'watch train
  'camera follows controlled train
  If (ks=K_WatchTrain) OrElse (ks="Watch Train") Then
    If (g.ctrl>0) Then
      If CScanCamActive=0 AndAlso wv.cam<>0 Then
        wView3.cam=wv.cam   'set view 3 to last viewed train
      EndIf
  
      'camera animation setup
      wv.OldCamX=p2wx(v.WinX/2)
      wv.OldCamY=p2wy(v.WinY/2)
      wv.CamSlide=wv.CamSteps
      wv.OldCamScale=v.Scale
      
      If wv.cam<>g.ctrl Then
        wv.cam=g.ctrl  'watch train
      Else
        wv.cam=0       'unwatch train
      EndIf
    Else
      Message("Control not set to Train")
    EndIf
  EndIf
  
  'scan camera - watch train
  If CScanCamActive=1 andalso ScanCam=0 Then
    Do
      wView3.cam+=1
      If wView3.cam>maxtrains Then wView3.cam=1
    Loop Until (w.Train(wView3.cam)<>0) _
    OrElse (wView3.cam=1)        'avoid endless loop, when no trains exist
  EndIf
  
  
  'Center camera to track
  If ((ks=K_CenterTrack) OrElse (ks="Center Track")) AndAlso (g.ctrl>0) Then
    'Center to train
    ScreenCenter(((w.Train(g.ctrl)->tr->mytrack->dimension.minx _
        +w.Train(g.ctrl)->tr->mytrack->dimension.maxx)/2), _
        ((w.Train(g.ctrl)->tr->mytrack->dimension.miny _
        +w.Train(g.ctrl)->tr->mytrack->dimension.maxy)/2),v)
    wv.cam=0
  EndIf
  
  'Train auto pilot switch (stop at next station)
  If ((ks=K_TrainAutopilot) OrElse (ks="Autopilot"))_
  AndAlso (g.ctrl>0) Then
    w.Train(g.ctrl)->control=w.Train(g.ctrl)->control Xor auto
  EndIf
  
  'Train auto pilot switch (stop at next station)
  If ks="Autostart" AndAlso (g.ctrl>0) Then
    w.Train(g.ctrl)->control=w.Train(g.ctrl)->control Xor restart
  EndIf
  
  'Brake (stop train)
  If ((ks=K_Stop) OrElse (ks="Stop Train")) AndAlso (g.ctrl>0) Then
    'auto pilot off
    w.Train(g.ctrl)->control=w.Train(g.ctrl)->control And (-1 Xor auto)
    'brake on
    w.Train(g.ctrl)->control=w.Train(g.ctrl)->control Xor brake
    'auto speed off
    w.Train(g.ctrl)->AutoSpeed=0
  EndIf
  
  
  'Move camera
  If Right$(ks,2)=K_CamUp Then: v.Offy=v.Offy+v.winx/30: wv.cam=0: endif 'up
  If Right$(ks,2)=K_CamDn Then: v.Offy=v.Offy-v.winx/30: wv.cam=0: endif 'down
  If Right$(ks,2)=K_CamLt Then: v.Offx=v.Offx+v.winy/30: wv.cam=0: endif 'left
  If Right$(ks,2)=K_CamRt Then: v.Offx=v.Offx-v.winy/30: wv.cam=0: endif 'right
  
  
  'Screen Setup
  If (ks=K_F5) OrElse (ks="F5 Messages") Then
    ShowMessages
  EndIf
  
  
  'Screen Setup
  If (ks=K_F8) OrElse (ks="F8 Setup") Then
    Setup
  EndIf
  

  
  '################################################
  '## debug display
  '################################################
  
'  i=3
'  GfxPrint6 "Debug",180,i*10,&Hffffff,win480: i+=1
'  Select Case tsmode
'  Case ts_stop:
'    s="ts_stop"
'  Case ts_run:
'    s="ts_run"
'  Case ts_build:
'    s="ts_build"
'  Case ts_edittrack:
'    s="ts_edittrack"
'  Case ts_control:
'    s="ts_control"
'  Case ts_files:
'    s="ts_files"
'  Case Else:
'    s="ts_ ???"
'  End Select
'  GfxPrint6 " tsmode     ="+str(tsmode)+", "+s,180,i*10,&Hffffff,win480: i+=1
'  GfxPrint6 " ks         ="+ks,180,i*10,&Hffffff,win480: i+=1
'  GfxPrint6 " menu.mName ="+menu.mName,180,i*10,&Hffffff,win480: i+=1
'  GfxPrint6 " menu.cmd   ="+menu.cmd,180,i*10,&Hffffff,win480: i+=1
  
  
'  If ks<>"" Then
'    If left(ks,1)=chr(255) Then
'      GfxPrint6 "Fn-Key: "+str(Asc(mid(ks,2,1))),0,10,&Hffffff,win480
'    Else
'      GfxPrint6 "Key: "+str(Asc(mid(ks,1,1))),0,10,&Hffffff,win480
'    EndIf
'  EndIf
'  
'  s=""
'  If MultiKey(&h38) Then s=s+"(SC_ALT) "
'  If MultiKey(&h3E) Then s=s+"(SC_F4) "
'  GfxPrint6 s,100,60,&Hffffff,win480

  
  
'  'show hand
'  'mouse cursor (indicating drag)
'  If MouseCursor=0 AndAlso (MouseWindow=1) Then
'    Put win480, (g.MouseX-5, g.MouseY), MenuIcon(0,1), trans
'  EndIf
  
  
  'show drag symbol
  'mouse cursor (indicating drag)
  If MouseCursor=0 AndAlso (MouseWindow=1) Then
    Put win480, (g.MouseX-12, g.MouseY-12), MenuIcon(83,2), trans
  EndIf
  
  
  'Reserve Time values<1 are critical and cause flicker on screen
  'Set FrameRate to lower values or reduce usage of background bitmaps
  If g.ReserveTime<1 Then
    Line win480, (v.WinX/2-14,0) - Step(26,16),&H0000ff,BF
    GfxPrint "CPU",v.WinX/2-12,0,&Hffff00,win480
  EndIf
    

  
  If g.PrintFrame Then
    'Main window
    Put(wv.PosX,wv.PosY),win480,PSet
  EndIf
  
  
  
  
  '################################################
  '## FPS count and adjust
  '################################################
  

'  g.Frame+=1
'
'  'FPS counter, reset every 2 seconds
'  If (Timer-g.now)>2 Then
'  
'    g.Fps=g.Fps0
'    g.Frame=0
'    g.now=Timer
'
''    If g.FpsLow Then g.SkipFrame+=1
''    g.FpsLow=0
'  EndIf
'  g.Fps0=g.Frame/(Timer-g.now)
  
  g.Fps= ((g.Fps*5) + 1/(Timer-g.now))/6
  g.now=Timer
  
  
'  'average time of last ten frames
'  If (Timer-g.LastTime)<2 Then
'    g.ThisTime=Timer-g.LastTime
'    g.AvgTime = (g.AvgTime*30+g.ThisTime)/31
'    If g.SkipFrame<>0 AndAlso g.AvgTime>g.AvgMax Then
'      g.AvgMax=(g.AvgMax*10+g.AvgTime)/11
'    EndIf
'  EndIf
'  g.LastTime=Timer
  
  'limit simulated fps
'  Const fpslimit=30.0
  Sleep(1)
  i=0
  j=1000/fpslimit
  Do While (i<j) AndAlso (Timer-g.LastTime)<(1.0/(fpslimit+1))'InTime(1)
    Sleep(1)
    i+=1
  Loop
  g.ReserveTime=(g.ReserveTime*9+i)/10
  
  g.ThisTime=Timer-g.LastTime
  g.LastTime=Timer


'  If g.Fps<30 Then g.FpsLow=1
'
'  If (g.Fps>60) And (g.SkipFrame>1) Then
'    g.SkipFrame-=1
'    g.Fps=45
'  EndIf
'  If (g.Fps>65) And (g.SkipFrame>0) Then
'    g.SkipFrame=0
'    g.Fps=45
'  EndIf
'
'  
'  If (g.SkipFrame=0) Then Sleep 10  '20
'  If (g.SkipFrame=1) Then Sleep 5  '10
'  If (g.SkipFrame=2) Then Sleep 2   '1
'  If (g.SkipFrame>2) Then Sleep 1   '1




'  '################################################
'  '## FPS count and adjust
'  '################################################
'  
'
'  g.Frame+=1
'
'  'FPS counter, reset every 2 seconds
'  If (Timer-g.now)>2 Then
'  
'    g.Fps=g.Fps0
'    g.Frame=0
'    g.now=Timer
'
'    If g.FpsLow Then g.SkipFrame+=1
'    g.FpsLow=0
'  EndIf
'  g.Fps0=g.Frame/(Timer-g.now)
'
'
'  'average time of last ten frames
'  If (Timer-g.LastTime)<2 Then
'    g.ThisTime=Timer-g.LastTime
'    g.AvgTime = (g.AvgTime*30+g.ThisTime)/31
'    If g.SkipFrame<>0 AndAlso g.AvgTime>g.AvgMax Then
'      g.AvgMax=(g.AvgMax*10+g.AvgTime)/11
'    EndIf
'  EndIf
'  g.LastTime=Timer
'
'
'  If g.Fps<30 Then g.FpsLow=1
'
'  If (g.Fps>60) And (g.SkipFrame>1) Then
'    g.SkipFrame-=1
'    g.Fps=45
'  EndIf
'  If (g.Fps>65) And (g.SkipFrame>0) Then
'    g.SkipFrame=0
'    g.Fps=45
'  EndIf
'
'  
'  If (g.SkipFrame=0) Then Sleep 10  '20
'  If (g.SkipFrame=1) Then Sleep 5  '10
'  If (g.SkipFrame=2) Then Sleep 2   '1
'  If (g.SkipFrame>2) Then Sleep 1   '1


  'Close window by Close button
  If Right$(ks,2)=K_Quit2 Then ks=K_Quit
  
  'Close window by ALT+F4
  If MultiKey(&h38) AndAlso MultiKey(&h3E) Then ks=K_Quit

  'SCREENSYNC
  
Loop Until (Right$(ks,1)=K_Quit) AndAlso("y"=YesOrNoBox("Exit Program?"))

LogFile("K_Quit")

imagedestroy win480
imagedestroy win160

End

'BESETTINGS (don't change!):
'BECURSOR=3E1
'BETOGGLE=11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
'BETARGET=1