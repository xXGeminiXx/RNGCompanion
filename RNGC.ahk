#Requires AutoHotkey v2.0
#SingleInstance Force

; Set up all global variables with initial values
global running := false
global screenWidth := A_ScreenWidth
global screenHeight := A_ScreenHeight
global selectedLandmarkIndex := -1
global landmarks := []
global killSwitchHotkey := "F12"
global startHotkey := "F10"
global guiWindow := ""
global lv := ""

SetTitleMatchMode(2)  ; Match Roblox by partial title

; Initialize the GUI
guiWindow := Gui("Background", "Yellow")  ; Set a soft honey-yellow background for the GUI
guiWindow.Font("s10", "Arial")  ; Set font size and type
guiWindow.Add("Text", "x10 y10 cBlack", "🐝 Define up to 5 Pixel Colors per Landmark (click to get colors)")  ; Add a bee emoji to fit the BeeBrained theme
guiWindow.Add("Edit", "x200 y40 w100 vLandmarkX", 0.5)
guiWindow.Add("Edit", "x310 y40 w100 vLandmarkY", 0.5)

; Define buttons explicitly and assign them global variable names
btnAddLandmark := guiWindow.Add("Button", "x420 y40 w100 h30 cYellow BackgroundBlack", "Add Landmark")
btnPickColor := guiWindow.Add("Button", "x20 y80 w150 h30 cYellow BackgroundBlack", "Pick Color")
btnStartScript := guiWindow.Add("Button", "x20 y120 w150 h30 cYellow BackgroundBlack", "Start Script")
btnStopScript := guiWindow.Add("Button", "x20 y160 w150 h30 cYellow BackgroundBlack", "Stop Script")

; Define status text and ensure it’s positioned properly
guiWindow.Add("Text", "x20 y200 w400 h30 vStatusText cBlack", "🐝 Status: Ready")  ; Add a bee icon to the status text

; Add the ListView with proper spacing below the status
lv := guiWindow.Add("ListView", "x20 y240 w560 h150 BackgroundYellow cBlack", ["Landmark #", "X", "Y", "Color 1", "Color 2", "Color 3", "Color 4", "Color 5"])

; Show the GUI
guiWindow.Show("w600 h450")  ; Increased window height to fit all elements comfortably
guiWindow.Title := "🐝 RNG Companion by BeeBrained"  ; Set window title with bee emoji

; Bind functions to button events (correcting Func() wrapper)
btnAddLandmark.OnEvent("Click", AddLandmark)
btnPickColor.OnEvent("Click", PickColor)
btnStartScript.OnEvent("Click", StartScript)
btnStopScript.OnEvent("Click", KillScript)

; Set up hotkeys
Hotkey("F12", KillScript)
Hotkey("F10", StartScript)

; Add a new landmark
AddLandmark(*) {
    global lv, landmarks, guiWindow
    guiWindow.Submit()  ; Submit the coordinates
    landmark := {x: guiWindow["LandmarkX"].Value, y: guiWindow["LandmarkY"].Value, colors: []}

    ; Initialize the landmark with 5 placeholder colors
    Loop 5 {
        landmark.colors.Push("Pick Color")
    }
    
    ; Add the landmark to the ListView and global list
    lv.Add(A_Index, landmark.x, landmark.y, landmark.colors*)
    landmarks.Push(landmark)
    guiWindow["StatusText"].Value := "Landmark added!"
}

; Pick a color and assign it to the selected landmark
PickColor(*) {
    global landmarks, selectedLandmarkIndex, lv, guiWindow
    if (selectedLandmarkIndex = -1) {
        MsgBox("Please select a landmark from the list first.")
        return
    }

    MsgBox("Use the mouse to pick a pixel color on the game screen.")
    MouseGetPos(&xPos, &yPos)
    color := PixelGetColor(xPos, yPos)
    
    ; Assign the color to the first available slot in the selected landmark
    Loop 5 {
        if (landmarks[selectedLandmarkIndex].colors[A_Index] = "Pick Color") {
            landmarks[selectedLandmarkIndex].colors[A_Index] := color
            lv.Modify(selectedLandmarkIndex+1, "", landmarks[selectedLandmarkIndex].colors*)
            break
        }
    }

    guiWindow["StatusText"].Value := "Picked color: " color " at X: " xPos " Y: " yPos
}

; Handle selecting a landmark in the ListView (on double click)
OnLandmarkSelect(*) {
    global lv, selectedLandmarkIndex, guiWindow
    selectedLandmarkIndex := lv.GetNext(0) - 1  ; Get the selected landmark index
    if (selectedLandmarkIndex >= 0) {
        guiWindow["StatusText"].Value := "Selected landmark #" (selectedLandmarkIndex + 1)
    } else {
        guiWindow["StatusText"].Value := "No landmark selected."
    }
}

; Start the script's main loop
StartScript(*) {
    global running := true, guiWindow
    guiWindow["Start Script"].Disable()  ; Disable start button
    SetTimer(MainLoop, 100)  ; Set up the main loop
    guiWindow["StatusText"].Value := "Script started! Press F12 to stop."
}

; Stop the script safely
KillScript(*) {
    global running := false, guiWindow
    SetTimer(MainLoop, 0)  ; Turn off the loop
    guiWindow["Start Script"].Enable()  ; Enable start button
    guiWindow["StatusText"].Value := "Script stopped."
}

; Main loop that checks landmarks and handles movement
MainLoop(*) {
    global running, screenWidth, screenHeight, landmarks
    if (!running || !landmarks.Length)
        return
    
    ; Refresh screen resolution
    screenWidth := A_ScreenWidth
    screenHeight := A_ScreenHeight

    positionConfirmed := true

    ; Loop through landmarks and compare colors
    for i, landmark in landmarks {
        absoluteX := screenWidth * landmark.x
        absoluteY := screenHeight * landmark.y
        success := false

        ; Check up to 5 colors per landmark for a match
        for color in landmark.colors {
            if (color != "Pick Color") {
                currentColor := PixelGetColor(absoluteX, absoluteY)
                if (CompareColors(currentColor, color, 15)) {
                    success := true
                    break
                }
            }
        }
        if (!success) {
            positionConfirmed := false
            break
        }
    }

    ; Execute actions based on position check
    if (positionConfirmed) {
        MouseClickDrag("Left", screenWidth * 0.5, screenHeight * 0.5, screenWidth * 0.75, screenHeight * 0.5, 50)
        Sleep(2000)  ; Spin the camera for 2 seconds
    } else {
        Send("{W down}")
        Sleep(500)
        Send("{W up}")
    }
}

; Compare colors with a tolerance
CompareColors(color1, color2, tolerance := 15) {
    r1 := (color1 >> 16) & 0xFF, g1 := (color1 >> 8) & 0xFF, b1 := color1 & 0xFF
    r2 := (color2 >> 16) & 0xFF, g2 := (color2 >> 8) & 0xFF, b2 := color2 & 0xFF
    return Abs(r1 - r2) <= tolerance && Abs(g1 - g2) <= tolerance && Abs(b1 - b2) <= tolerance
}
