'
'file vge.bas
'
'vge (vector graphics engine)
'
'Copyright by oog, www.proog.de 2011


'################################################
'## Definitions and constants
'################################################


'DrawItem constants for CoorScale
Const ScaleVehicle=10
Const ScaleBuilding=4

'convert world to pixel
'(need v as tview variable)
#define xcoor(x) (v.Offx+((x)/v.Scale))
#define ycoor(y) (v.Offy+((y)/v.Scale))

'convert pixel to world
'(need v as tview variable)
#define p2wx(x) (((x)-v.Offx)*v.Scale)
#define p2wy(y) (((y)-v.Offy)*v.Scale)


'################################################
'## Types
'################################################

Type p3
  x As Integer
  y As Integer
  z As Integer
End Type


Type TView                          'View
 As Integer WinX,WinY               'Window size
 As Integer Offx,Offy,Scale         'World view position and scale
 As Integer Debug                   'debug view
End Type


'################################################
'## Functions / Subs (Graphics)
'################################################


Function VisRectItem(x1 As Integer, y1 As Integer, _
  x2 As Integer, y2 As Integer, _
  v As TView) As Integer
  'check distance (x^2+y^2 < Distance^2)
  Dim As Integer d
  If (((xcoor(x1)-v.WinX/2)^2 _
      +(ycoor(y1)-v.WinY/2)^2)) _
      <(v.WinX*v.WinX+v.WinY*v.WinY) Then
    Return 1
  Else
    If (((xcoor(x2)-v.WinX/2)^2 _
        +(ycoor(y2)-v.WinY/2)^2)) _
        <(v.WinX*v.WinX+v.WinY*v.WinY) Then
      Return 1
    Else
      Return 0
    EndIf
  EndIf
End Function


Sub ScreenCenter(x As Integer, y As Integer, v As TView)
  v.Offx=v.winx/2-x/v.Scale
  v.Offy=v.winy/2-y/v.Scale
End Sub


Sub TriDraw(a1 As p3, b1 As p3, c1 As p3, col As Integer, dwin As Any ptr)
  Dim As p3 a, b, c, t
  Dim As Integer y, dy, xa, xb, L1, D1, L2, D2
  
  a=a1: b=b1: c=c1
  If a.y>b.y Then: t=b: b=a: a=t: EndIf
  If a.y>c.y Then: t=c: c=a: a=t: EndIf
  If b.y>c.y Then: t=c: c=b: b=t: EndIf
  
  dy=c.y-a.y
  For y=0 To dy
    If y=(b.y-a.y) Then
      xa=b.x
    Else
      If y<(b.y-a.y) Then
        L1=y
        D1=b.y-a.y
        xa=(b.x*L1+a.x*(D1-L1))/D1
      Else
        L1=y-b.y+a.y
        D1=c.y-b.y
        xa=(c.x*L1+b.x*(D1-L1))/D1
      EndIf
    EndIf
    L2=y
    D2=c.y-a.y
    If d2=0 Then
      xb=c.x
    Else
      xb=(c.x*L2+a.x*(D2-L2))/D2
    EndIf
    Line dwin,(xa,y+a.y)-(xb,y+a.y),col
  Next
End Sub


'################################################
'## Graphics - Build
'################################################

Function VDE_CheckParamRange(zoom As Integer, zmin As Integer, zmax As Integer) As Integer
  Dim As Integer r
  r=(zmin<=zoom) AndAlso (zoom<=zmax)
  If r=0 Then
    Print "VDE_CheckParamRange out of range ("+str(zmin)+".."+str(zmax)+"): "+str(zoom)+" = 0x"+hex(zoom)
    Sleep
  EndIf
  Return r
End Function


Function VDE_Check8s(value As Integer) As Integer
  Dim As Integer r
  r=(-128<=value) AndAlso (value<=127)
  If r=0 Then
    Print "VDE_CheckParamRange out of range (-128...127): "+str(value)
    Sleep
  EndIf
  Return r
End Function


Function VDE_Check8u(value As Integer) As Integer
  Dim As Integer r
  r=(0<=value) AndAlso (value<=255)
  If r=0 Then
    Print "VDE_CheckParamRange out of range (0...255): "+str(value)
    Sleep
  EndIf
  Return r
End Function


Function VectRem(Remark As String) As String
  Return ""
End Function


Function VectVehicle As String
  Return "v"
End Function


Function VectZoomIn(zoom As Integer) As String
  If VDE_Check8u(zoom) Then
    Return "Z"+Chr(zoom)
  Else
    End
  EndIf
End Function


Function VectZoomOut(zoom As Integer) As String
  If VDE_Check8u(zoom) Then
    Return "z"+Chr(zoom)
  Else
    End
  EndIf
End Function


Function VectZoomRange(zoomout As Integer, zoomin As Integer) As String
  If VDE_Check8u(zoomout) _
  AndAlso VDE_Check8u(zoomin) Then
    Return "R"+Chr(zoomout)+Chr(zoomin)
  Else
    End
  EndIf
End Function


Function VectEndZoom As String
  Return "E"
End Function


Function VectExit As String
  Return "X"
End Function


Function VectColor(col As Integer) As String
  Dim s As String
  If VDE_CheckParamRange(col, 0, &Hffffff) Then
    s="O"+Chr(col Shr 16 And &Hff) _
      +Chr(col Shr 8 And &Hff) _
      +Chr(col And &Hff)
    Return s
  Else
    End
  EndIf
End Function


Function VectLine(x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer) As String
  Dim s As String
  'Line
  If VDE_Check8s(x1) _
  AndAlso VDE_Check8s(y1) _
  AndAlso VDE_Check8s(x2) _
  AndAlso VDE_Check8s(y2) Then
    s="L"+Chr(x1+128)+Chr(y1+128)+Chr(x2+128)+Chr(y2+128)
    Return s
  Else
    End
  EndIf
End Function


Function VectTri(x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer, x3 As Integer, y3 As Integer) As String
  Dim s As String
  'Unfilled Triangle
  If VDE_Check8s(x1) _
  AndAlso VDE_Check8s(y1) _
  AndAlso VDE_Check8s(x2) _
  AndAlso VDE_Check8s(y2) _
  AndAlso VDE_Check8s(x3) _
  AndAlso VDE_Check8s(y3) Then
    s="U"+Chr(x1+128)+Chr(y1+128) _
     +Chr(x2+128)+Chr(y2+128) _
     +Chr(x3+128)+Chr(y3+128)
    Return s
  Else
    End
  EndIf
End Function


Function VectFTri(x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer, x3 As Integer, y3 As Integer) As String
  Dim s As String
  'Filled Triangle
  If VDE_Check8s(x1) _
  AndAlso VDE_Check8s(y1) _
  AndAlso VDE_Check8s(x2) _
  AndAlso VDE_Check8s(y2) _
  AndAlso VDE_Check8s(x3) _
  AndAlso VDE_Check8s(y3) Then
    s="T"+Chr(x1+128)+Chr(y1+128) _
     +Chr(x2+128)+Chr(y2+128) _
     +Chr(x3+128)+Chr(y3+128)
    Return s
  Else
    End
  EndIf
End Function


Function VectBox(x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer) As String
  Dim s As String
  'Box
  If VDE_Check8s(x1) _
  AndAlso VDE_Check8s(y1) _
  AndAlso VDE_Check8s(x2) _
  AndAlso VDE_Check8s(y2) Then
    s="L"+Chr(x1+128)+Chr(y1+128)+Chr(x1+128)+Chr(y2+128) _
     +"L"+Chr(x1+128)+Chr(y2+128)+Chr(x2+128)+Chr(y2+128) _
     +"L"+Chr(x2+128)+Chr(y2+128)+Chr(x2+128)+Chr(y1+128) _
     +"L"+Chr(x2+128)+Chr(y1+128)+Chr(x1+128)+Chr(y1+128)
    Return s
  Else
    End
  EndIf
End Function


Function VectFBox(x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer) As String
  Dim s As String
  'Filled Box
  If VDE_Check8s(x1) _
  AndAlso VDE_Check8s(y1) _
  AndAlso VDE_Check8s(x2) _
  AndAlso VDE_Check8s(y2) Then
    s="T"+Chr(x1+128)+Chr(y1+128) _
     +Chr(x2+128)+Chr(y1+128) _
     +Chr(x1+128)+Chr(y2+128) _
     +"T"+Chr(x1+128)+Chr(y2+128) _
     +Chr(x2+128)+Chr(y1+128) _
     +Chr(x2+128)+Chr(y2+128)
    Return s
  Else
    End
  EndIf
End Function


Function VectCircle(x As Integer, y As Integer, r As Integer) As String
  If VDE_Check8s(x) _
  AndAlso VDE_Check8s(y) _
  AndAlso VDE_Check8u(r) Then
    Return "C"+Chr(x+128)+Chr(y+128)+Chr(r) 's
  Else
    End
  EndIf
End Function


Function VectFCircle(x As Integer, y As Integer, r As Integer) As String
  If VDE_Check8s(x) _
  AndAlso VDE_Check8s(y) _
  AndAlso VDE_Check8u(r) Then
    Return "D"+Chr(x+128)+Chr(y+128)+Chr(r) 's
  Else
    End
  EndIf
End Function


'################################################
'## Graphics - draw
'################################################

'Token
' "v"                     Vehicle coordinate scale
' "Z" n                   Zoom in
' "z" n                   Zoom out
' "R" m,n                 Zoom range out,in
' "E"                     End Zoom
' "X"                     Exit
' "O" r,g,b               Color
' "C" x,y,r               Circle
' "D" x,y,r               Disc = filled Circle
' "L" x1,y1,x2,y2         Line
' "T" x1,y1,x2,y2,x3,y3   Triangle
' "U" x1,y1,x2,y2,x3,y3   Unfilled Triangle


Function SkipDrawZoom(mBuild As String, i As Integer) As Integer
  While (mBuild[i]<>Asc("E")) _
  AndAlso(i<Len(mBuild))
    Select Case mBuild[i]
    Case Asc("X")
      i+=1
    Case Asc("C")
      i+=4
    Case Asc("D")
      i+=4
    Case Asc("O")
      i+=4
    Case Asc("L")
      i+=5
    Case Asc("T")
      i+=7
    Case Asc("U")
      i+=7
    Case Else
      'error - skip command string
      Print "Error - SkipDrawZoom - Build String Syntax i="+str(i)
      Sleep
      i=Len(mBuild)
    End Select
  Wend
  Return i
End Function


Sub DrawModel(ax As Integer, ay As Integer, bx As Integer, by As Integer, _
  mBuild As String, v As TView, col As Integer=1, _
  NoDebug As Integer=0, dwin As Any Ptr=0)
  'NoDebug: Don't draw reference points for models in debug view
  
  Dim As longInt tx0,ty0,tx1,ty1,tx2,ty2
  Dim As Integer rx0,ry0,rx1,ry1,rx2,ry2,distance
  Dim As Integer i, co, ucol, CoorScale=ScaleBuilding
  Dim As longint d
  Dim As p3 a, b, c
  Dim m As Integer = 1000 '1000mm = 1m
  Const ZoomScale=0.8
  
  If VisRectItem(ax, ay, bx, by, v) Then
    tx0=ax
    ty0=ay
    tx1=(bx-ax)
    ty1=(by-ay)
    tx2=(by-ay)
    ty2=-(bx-ax)
    distance=Sqr(tx1*tx1+ty1*ty1)
    i=0
    If 1<v.Scale*m*2/distance Then
      Do While i<Len(mBuild)
        'Commands with shortest parameter list first!
        
        Select Case mBuild[i]
        Case Asc("v")
          'Vehicle coordinate scale
          CoorScale=ScaleVehicle
        
        Case Asc("Z")
          'ZoomIn
          i+=1: rx0=mBuild[i]
          If rx0<ZoomScale*v.Scale*m/distance Then
            i=SkipDrawZoom(mBuild, i+1)
          EndIf
        
        Case Asc("z")
          'ZoomOut
          i+=1: rx0=mBuild[i]
          If rx0>=ZoomScale*v.Scale*m/distance Then
            i=SkipDrawZoom(mBuild, i+1)
          EndIf
        
        Case Asc("R")
          'ZoomRange out,in
          i+=1: rx0=mBuild[i]
          i+=1: rx1=mBuild[i]
          If rx0>=ZoomScale*v.Scale*m/distance _
          OrElse rx1<ZoomScale*v.Scale*m/distance Then
            i=SkipDrawZoom(mBuild, i+1)
          EndIf
        
        Case Asc("X")
          'Exit
          i=Len(mBuild)
        
        Case Asc("O")
          'Color
          i+=1: ucol=mBuild[i]*&H10000
          i+=1: ucol+=mBuild[i]*&H100
          i+=1: ucol+=mBuild[i]
          If ucol=1 Then
            co=col
          Else
            co=ucol
          EndIf
        
        Case Asc("C")
          'Circle
          i+=1: rx0=(mBuild[i]-128)*coorscale
          i+=1: ry0=(mBuild[i]-128)*coorscale+500
          i+=1: rx1=mBuild[i]*coorscale*m/v.Scale
          Circle dwin,(xcoor(tx0 +(rx0*tx2+ry0*tx1)/m), _
                 ycoor(ty0 +(rx0*ty2+ry0*ty1)/m)), _
                 rx1/m*distance/m,co
        
        Case Asc("D")
        'Disc = filled circle
          i+=1: rx0=(mBuild[i]-128)*coorscale
          i+=1: ry0=(mBuild[i]-128)*coorscale+500
          i+=1: rx1=mBuild[i]*coorscale*m/v.Scale
          Circle dwin,(xcoor(tx0 +(rx0*tx2+ry0*tx1)/m), _
                 ycoor(ty0 +(rx0*ty2+ry0*ty1)/m)), _
                 rx1/m*distance/m,co,,,,F
        
        Case Asc("L")
          'Line
          i+=1: rx0=(mBuild[i]-128)*coorscale
          i+=1: ry0=(mBuild[i]-128)*coorscale+500
          i+=1: rx1=(mBuild[i]-128)*coorscale
          i+=1: ry1=(mBuild[i]-128)*coorscale+500
          Line dwin,(xcoor(tx0 +(rx0*tx2+ry0*tx1)/m), _
               ycoor(ty0 +(rx0*ty2+ry0*ty1)/m)) _
             -(xcoor(tx0 +(rx1*tx2+ry1*tx1)/m), _
               ycoor(ty0 +(rx1*ty2+ry1*ty1)/m)),co
        
        Case Asc("T")
          'Filled Triangle
          i+=1: rx0=(mBuild[i]-128)*coorscale
          i+=1: ry0=(mBuild[i]-128)*coorscale+500
          i+=1: rx1=(mBuild[i]-128)*coorscale
          i+=1: ry1=(mBuild[i]-128)*coorscale+500
          i+=1: rx2=(mBuild[i]-128)*coorscale
          i+=1: ry2=(mBuild[i]-128)*coorscale+500
          a.x=xcoor(tx0 +(rx0*tx2+ry0*tx1)/m)
          a.y=ycoor(ty0 +(rx0*ty2+ry0*ty1)/m)
          b.x=xcoor(tx0 +(rx1*tx2+ry1*tx1)/m)
          b.y=ycoor(ty0 +(rx1*ty2+ry1*ty1)/m)
          c.x=xcoor(tx0 +(rx2*tx2+ry2*tx1)/m)
          c.y=ycoor(ty0 +(rx2*ty2+ry2*ty1)/m)
          TriDraw(a,b,c,co,dwin)
        
        Case Asc("U")
          'Unfilled Triangle
          i+=1: rx0=(mBuild[i]-128)*coorscale
          i+=1: ry0=(mBuild[i]-128)*coorscale+500
          i+=1: rx1=(mBuild[i]-128)*coorscale
          i+=1: ry1=(mBuild[i]-128)*coorscale+500
          i+=1: rx2=(mBuild[i]-128)*coorscale
          i+=1: ry2=(mBuild[i]-128)*coorscale+500
          a.x=xcoor(tx0 +(rx0*tx2+ry0*tx1)/m)
          a.y=ycoor(ty0 +(rx0*ty2+ry0*ty1)/m)
          b.x=xcoor(tx0 +(rx1*tx2+ry1*tx1)/m)
          b.y=ycoor(ty0 +(rx1*ty2+ry1*ty1)/m)
          c.x=xcoor(tx0 +(rx2*tx2+ry2*tx1)/m)
          c.y=ycoor(ty0 +(rx2*ty2+ry2*ty1)/m)
          Line dwin, (a.x,a.y)-(b.x,b.y),co
          Line dwin, (b.x,b.y)-(c.x,c.y),co
          Line dwin, (a.x,a.y)-(c.x,c.y),co
        
        Case Asc("E")
          'is a valid command - do nothing
  
        Case Else
          'error - skip command string
          Print "Error - DrawModel - Build String Syntax i="+str(i)
          Sleep
          i=Len(mBuild)
          
        End Select
        
        i+=1
      Loop
    EndIf
    'debug: show reference point and normal vectors
    If v.Debug AndAlso (NoDebug=0) Then
      Circle dwin,(xcoor(ax),ycoor(ay)),3,&Hffff00,,,,f     'PointA
      Circle dwin,(xcoor(bx),ycoor(by)),3,&H8080ff          'PointB
      Circle dwin,(xcoor(ax+tx2),ycoor(ay+ty2)),3,&H00ffff  '90° Point
    EndIf
  EndIf
End Sub

