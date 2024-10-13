#Requires AutoHotkey v2.0
#SingleInstance Force
global running := false
SetTitleMatchMode(2)  ; Match Roblox by partial title

; Define landmarks (you can add pixel color definitions via the GUI)
landmarks := []

global screenWidth := A_ScreenWidth
global screenHeight := A_ScreenHeight
global selectedLandmarkIndex := -1

; Define hotkeys for starting and stopping the script
global killSwitchHotkey := "F12"
global startHotkey := "F10"

; Initialize the GUI
Gui := GuiCreate()
Gui.Add("Text", "Define up to 5 Pixel Colors per Landmark (click to get colors)")
Gui.Add("Edit", "x200 y40 w100 vLandmarkX", 0.5)
Gui.Add("Edit", "x310 y40 w100 vLandmarkY", 0.5)
Gui.Add("Button", "x420 y40 w100 h30", "Add Landmark").OnEvent("Click", Func("AddLandmark"))
Gui.Add("Button", "x20 y80 w150 h30", "Pick Color").OnEvent("Click", Func("PickColor"))
Gui.Add("Button", "x20 y120 w150 h30", "Start Script").OnEvent("Click", Func("StartScript"))
Gui.Add("Button", "x20 y160 w150 h30", "Stop Script").OnEvent("Click", Func("KillScript"))
lv := Gui.Add("ListView", "r5 w400 h150", "Landmark #|X|Y|Color 1|Color 2|Color 3|Color 4|Color 5")
Gui.Add("Text", "x20 y200 w400 h30 vStatusText", "Status: Ready")

Gui.Show("w600 h300", "AHK Roblox Automation")

; Hotkeys for starting and stopping
Hotkey(killSwitchHotkey, Func("KillScript"))
Hotkey(startHotkey, Func("StartScript"))

; Add a new landmark
AddLandmark() {
    global lv, landmarks
    Gui.Submit()  ; Submit the coordinates
    landmark := {x: Gui["LandmarkX"].Value, y: Gui["LandmarkY"].Value, colors: []}

    ; Initialize the landmark with 5 placeholder colors
    Loop 5 {
        Push(landmark.colors, "Pick Color")
    }
    
    ; Add the landmark to the ListView and global list
    lv.Add(A_Index, landmark.x, landmark.y, landmark.colors*)
    Push(landmarks, landmark)
    Gui["StatusText"].Value := "Landmark added!"
}

; Pick a color and assign it to the selected landmark
PickColor() {
    global landmarks, selectedLandmarkIndex, lv
    if (selectedLandmarkIndex = -1) {
        MsgBox("Please select a landmark from the list first.")
        return
    }

    MsgBox("Use the mouse to pick a pixel color on the game screen.")
    MouseGetPos(&xPos, &yPos)
    PixelGetColor(&color, xPos, yPos, "RGB")
    
    ; Assign the color to the first available slot in the selected landmark
    Loop 5 {
        if (landmarks[selectedLandmarkIndex].colors[A_Index] = "Pick Color") {
            landmarks[selectedLandmarkIndex].colors[A_Index] := color
            lv.Modify(selectedLandmarkIndex+1, "", landmarks[selectedLandmarkIndex].colors*)
            break
        }
    }

    Gui["StatusText"].Value := "Picked color: " color " at X: " xPos " Y: " yPos
}

; Handle selecting a landmark in the ListView
lv.OnEvent("ItemClick", Func("OnLandmarkSelect"))

OnLandmarkSelect() {
    global lv, selectedLandmarkIndex
    selectedLandmarkIndex := lv.GetNext(0) - 1  ; Get the selected landmark index
    Gui["StatusText"].Value := "Selected landmark #" (selectedLandmarkIndex + 1)
}

; Start the script's main loop
StartScript() {
    global running := true
    GuiControlDisable("Start Script")
    SetTimer(Func("MainLoop"), 100)
    Gui["StatusText"].Value := "Script started! Press " killSwitchHotkey " to stop."
}

; Stop the script safely
KillScript() {
    global running := false
    SetTimer(Func("MainLoop"), Off)
    GuiControlEnable("Start Script")
    Gui["StatusText"].Value := "Script stopped."
}

; Main loop that checks landmarks and handles movement
MainLoop() {
    if (!running || !landmarks.Length)
        return
    
    ; Refresh screen resolution
    global screenWidth := A_ScreenWidth
    global screenHeight := A_ScreenHeight

    positionConfirmed := true

    ; Loop through landmarks and compare colors
    for i, landmark in landmarks {
        absoluteX := screenWidth * landmark.x
        absoluteY := screenHeight * landmark.y
        success := false

        ; Check up to 5 colors per landmark for a match
        for color in landmark.colors {
            if (color != "Pick Color") {
                PixelGetColor(&currentColor, absoluteX, absoluteY, "RGB")
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
