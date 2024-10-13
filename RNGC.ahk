#Requires AutoHotkey v2.0
#Persistent
#SingleInstance Force

global running := false
SetTitleMatchMode(2)  ; Match Roblox by partial title

; Game states and bot actions
global gameState := "Idle"
global botAction := "None"
global actionTimer := 0

; Define landmarks
global landmarks := []

global screenWidth := A_ScreenWidth
global screenHeight := A_ScreenHeight
global selectedLandmarkIndex := -1

; Define hotkeys for starting and stopping the script
global killSwitchHotkey := "F12"
global startHotkey := "F10"

; Initialize the GUI
gui := GuiCreate("+AlwaysOnTop +Resize +MinimizeBox +MaximizeBox", "AHK Roblox Automation")
gui.SetFont("s10", "Segoe UI")
gui.Add("Text", , "Define up to 5 Pixel Colors per Landmark (click to get colors)")
editLandmarkX := gui.Add("Edit", "x200 y40 w100", "0.5")
editLandmarkY := gui.Add("Edit", "x310 y40 w100", "0.5")
btnAddLandmark := gui.Add("Button", "x420 y40 w100 h30", "Add Landmark")
btnAddLandmark.OnEvent("Click", AddLandmark)
btnPickColor := gui.Add("Button", "x20 y80 w150 h30", "Pick Color")
btnPickColor.OnEvent("Click", PickColor)
btnStartScript := gui.Add("Button", "x20 y120 w150 h30", "Start Script")
btnStartScript.OnEvent("Click", StartScript)
btnKillScript := gui.Add("Button", "x20 y160 w150 h30", "Stop Script")
btnKillScript.OnEvent("Click", KillScript)
lv := gui.Add("ListView", "r5 w400 h150", ["Landmark #", "X", "Y", "Color 1", "Color 2", "Color 3", "Color 4", "Color 5"])
lv.OnEvent("ItemSelect", OnLandmarkSelect)
statusText := gui.Add("Text", "x20 y220 w400 h30", "Status: Ready")

; Game State and Bot Action Display
gui.Add("GroupBox", "x20 y260 w300 h60", "Game State & Bot Action")
gameStateText := gui.Add("Text", "x30 y290", "Game State: " gameState)
botActionText := gui.Add("Text", "x30 y310", "Bot Action: " botAction)

; Black subwindow for displaying game state and bot actions
gui.Add("GroupBox", "x340 y260 w300 h60", "Subwindow")
subwindowText := gui.Add("Text", "x350 y290 w280 h40 cWhite BackgroundBlack", "Game State: " gameState "`nBot Action: " botAction)

gui.Show("AutoSize", "AHK Roblox Automation")

; Hotkeys for starting and stopping
Hotkey(killSwitchHotkey, Func("KillScript"))
Hotkey(startHotkey, Func("StartScript"))

; Add a new landmark
AddLandmark() {
    global lv, landmarks, editLandmarkX, editLandmarkY, statusText
    ; Get the coordinates from the Edit controls
    landmarkX := editLandmarkX.Value
    landmarkY := editLandmarkY.Value
    landmark := {x: landmarkX, y: landmarkY, colors: []}

    ; Initialize the landmark with 5 placeholder colors
    Loop 5 {
        landmark.colors.Push("Pick Color")
    }
    
    ; Add the landmark to the ListView and global list
    lv.AddRow(landmarks.Length + 1, landmark.x, landmark.y, landmark.colors*)
    landmarks.Push(landmark)
    statusText.Text := "Landmark added!"
}

; Pick a color and assign it to the selected landmark
PickColor() {
    global landmarks, selectedLandmarkIndex, lv, statusText
    if (selectedLandmarkIndex == -1) {
        MsgBox("Please select a landmark from the list first.")
        return
    }

    MsgBox("Use the mouse to pick a pixel color on the game screen.")
    xPos, yPos := MouseGetPos()
    color := PixelGetColor(xPos, yPos, "RGB")
    
    ; Assign the color to the first available slot in the selected landmark
    for index, value in landmarks[selectedLandmarkIndex].colors {
        if (value == "Pick Color") {
            landmarks[selectedLandmarkIndex].colors[index] := color
            ; Update the ListView row
            row := lv.GetRow(selectedLandmarkIndex + 1)
            row[3 + index] := color  ; Update the appropriate color column
            break
        }
    }
    
    statusText.Text := "Picked color: " color " at X: " xPos " Y: " yPos
}

; Handle selecting a landmark in the ListView
OnLandmarkSelect() {
    global lv, selectedLandmarkIndex, statusText
    selectedLandmarkIndex := lv.GetNext() - 1  ; Get the selected landmark index
    statusText.Text := "Selected landmark #" (selectedLandmarkIndex + 1)
}

; Start the script's main loop
StartScript() {
    global running, gameState, botAction, actionTimer, statusText, btnStartScript
    running := true
    actionTimer := 0
    gameState := "Idle"
    botAction := "Starting bot"
    UpdateGui()
    btnStartScript.Enabled := false
    SetTimer(MainLoop, 1000)  ; Check every second
    statusText.Text := "Script started! Press " killSwitchHotkey " to stop."
}

; Stop the script safely
KillScript() {
    global running, statusText, btnStartScript
    running := false
    SetTimer(MainLoop, 0)  ; Turn off timer
    btnStartScript.Enabled := true
    statusText.Text := "Script stopped."
}

; Update the GUI display
UpdateGui() {
    global gameState, botAction, gameStateText, botActionText, subwindowText
    gameStateText.Text := "Game State: " gameState
    botActionText.Text := "Bot Action: " botAction
    subwindowText.Text := "Game State: " gameState "`nBot Action: " botAction
}

; Main loop that checks game states, bot actions, and performs tasks
MainLoop() {
    global running, actionTimer, gameState, botAction
    
    if (!running)
        return
    
    ; Rotate through game states and actions
    if (actionTimer >= 0 && actionTimer < 5) {
        gameState := "Idle"
        botAction := "Waiting..."
    } 
    else if (actionTimer >= 5 && actionTimer < 20) {
        gameState := "Spin Clicking"
        botAction := "Spinning camera and clicking"
        SpinCameraAndClick()
    } 
    else if (actionTimer >= 20 && actionTimer < 35) {
        gameState := "Moving"
        botAction := "Moving around"
        MoveCharacter()
    } 
    else if (actionTimer >= 35 && actionTimer < 45) {
        gameState := "Repositioning"
        botAction := "Identifying landmarks and repositioning"
        positionConfirmed := CheckLandmarks()
        if (!positionConfirmed) {
            botAction := "Repositioning character"
            ; Add code to reposition character
        }
    } 
    else {
        actionTimer := 0  ; Reset timer for new cycle
    }
    
    actionTimer++
    UpdateGui()
}

; Spin camera using right-click and click on objects
SpinCameraAndClick() {
    global screenWidth, screenHeight
    
    MouseClickDrag("Right", screenWidth * 0.5, screenHeight * 0.5, screenWidth * 0.75, screenHeight * 0.5, 50)
    Sleep(2000)  ; Spin for 2 seconds
    ClickOnObjects()  ; Click objects after spinning
}

; Function to search for objects (e.g., coins) and click on them
ClickOnObjects() {
    global screenWidth, screenHeight
    ; Example of a color that represents a coin (replace with actual color)
    colorToFind := 0xFFD700

    try {
        clickX, clickY := PixelSearch(0, 0, screenWidth, screenHeight, colorToFind, 5, "RGB Fast")
        Click(clickX, clickY)
        Sleep(200)  ; Small delay after click
    } catch {
        ; Pixel not found
    }
}

; Function to move the character around
MoveCharacter() {
    Send("{W down}")
    Sleep(1500)  ; Move forward for 1.5 seconds
    Send("{W up}")
}

; Function to check if player is near a landmark by comparing colors
CheckLandmarks() {
    global landmarks, screenWidth, screenHeight
    positionConfirmed := true
    ; Loop through landmarks and compare colors
    for i, landmark in landmarks {
        absoluteX := screenWidth * landmark.x
        absoluteY := screenHeight * landmark.y
        success := false
        for color in landmark.colors {
            if (color != "Pick Color") {
                currentColor := PixelGetColor(absoluteX, absoluteY, "RGB")
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
    return positionConfirmed
}

; Compare colors with a tolerance
CompareColors(color1, color2, tolerance := 15) {
    r1 := (color1 >> 16) & 0xFF
    g1 := (color1 >> 8) & 0xFF
    b1 := color1 & 0xFF
    r2 := (color2 >> 16) & 0xFF
    g2 := (color2 >> 8) & 0xFF
    b2 := color2 & 0xFF
    return Abs(r1 - r2) <= tolerance && Abs(g1 - g2) <= tolerance && Abs(b1 - b2) <= tolerance
}
