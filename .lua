local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Jen Hub | Steal V11",
   LoadingTitle = "Loading Stable Engine...",
   LoadingSubtitle = "Made By: Jen",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "JenHubConfigs", 
      FileName = "StealConfig_V11"
   },
   KeySystem = false,
   Theme = "Bloom" 
})

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

-- Variables
local LocalPlayer = Players.LocalPlayer
local tpWalkEnabled = false
local autoEscape = false
local instantInteract = true
local glideSpeed = 600
local savedPosition = nil
local movementMode = "Normal"
local autoBypass = true
local currentGroundY = 0
local heightOffset = 50 

-- State Tracking
local isReturning = false

-- ==========================================
-- ANTI-CHEAT BYPASS & ANIMATION FIX
-- ==========================================
local function ApplyBypass()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local animate = char:FindFirstChild("Animate")
    
    if hum then
        local newHum = hum:Clone()
        newHum.Parent = char
        hum:Destroy()
        
        workspace.CurrentCamera.CameraSubject = newHum
        
        -- Fix Jumping Ability
        newHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        newHum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        newHum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
        newHum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        
        -- Fix Animations (The "Freeze" fix)
        if animate then
            animate.Disabled = true
            task.wait(0.1)
            animate.Disabled = false
        end
        
        Rayfield:Notify({Title = "Bypass Applied", Content = "Speed active & Animations fixed.", Duration = 2})
    end
end

-- ==========================================
-- CORE FUNCTIONS
-- ==========================================
local function SavePosition()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        savedPosition = hrp.CFrame
        currentGroundY = hrp.Position.Y
        Rayfield:Notify({Title = "Base Saved", Content = "Safe Zone set!", Duration = 3})
    end
end

local function StartAutoReturn(sourceName)
    local name = sourceName and sourceName:lower() or ""
    if autoEscape and savedPosition and not isReturning then
        if name:find("egg") or name:find("steal") then
            isReturning = true
        end
    end
end

-- Character Detection
LocalPlayer.CharacterAdded:Connect(function(char)
    if autoBypass then task.wait(0.8) ApplyBypass() end
    char.ChildAdded:Connect(function(child)
        if child.Name:lower():find("egg") then StartAutoReturn("egg") end
    end)
end)

-- Interaction
ProximityPromptService.PromptShown:Connect(function(p)
    if instantInteract then p.HoldDuration = 0 p.MaxActivationDistance = 30 end
end)
ProximityPromptService.PromptTriggered:Connect(function(p)
    local text = (p.ActionText .. p.ObjectText):lower()
    StartAutoReturn(text)
end)

-- ==========================================
-- UI SETUP
-- ==========================================
local MainTab = Window:CreateTab("Steal", 4483362458)
local ActionTab = Window:CreateTab("Actions", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

MainTab:CreateSection("Steal Controls")
MainTab:CreateToggle({Name = "Instant Interact", CurrentValue = true, Flag = "F_Inst", Callback = function(V) instantInteract = V end})
MainTab:CreateButton({Name = "Save Base Position", Callback = function() SavePosition() end})
MainTab:CreateToggle({Name = "Auto Escape (TP on Steal)", CurrentValue = false, Flag = "F_AutoTP", Callback = function(V) autoEscape = V end})

MainTab:CreateSection("Movement Modes")
MainTab:CreateDropdown({
   Name = "Movement Mode",
   Options = {"Normal", "Top (Over Guards)", "Middle Fast ZigZag"},
   CurrentOption = {"Normal"},
   Flag = "F_Mode",
   Callback = function(Option) movementMode = Option[1] end,
})

MainTab:CreateSlider({Name = "Top Height", Range = {0, 500}, Increment = 5, CurrentValue = 50, Flag = "F_Height", Callback = function(V) heightOffset = V end})
MainTab:CreateSlider({Name = "Glide Speed", Range = {0, 1300}, Increment = 10, CurrentValue = 600, Flag = "F_Speed", Callback = function(V) glideSpeed = V end})
MainTab:CreateToggle({Name = "Enable Movement", CurrentValue = false, Flag = "F_Move", Callback = function(V) tpWalkEnabled = V end})

ActionTab:CreateButton({Name = "Manual Bypass", Callback = function() ApplyBypass() end})
ActionTab:CreateButton({Name = "Fix Height/Jump", Callback = function() 
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        currentGroundY = LocalPlayer.Character.HumanoidRootPart.Position.Y
    end
end})

-- ==========================================
-- STABLE MOVEMENT ENGINE (Jump & Animation Fix)
-- ==========================================
RunService.Heartbeat:Connect(function(delta)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local moveVector = Vector3.new(0,0,0)
    local active = false

    -- 1. Determine Direction
    if isReturning and savedPosition then
        local diff = (savedPosition.Position - hrp.Position)
        local dist = diff.Magnitude
        if dist < 3 then
            hrp.CFrame = savedPosition
            isReturning = false
            return
        end
        moveVector = diff.Unit
        active = true
    elseif tpWalkEnabled and hum.MoveDirection.Magnitude > 0 then
        moveVector = hum.MoveDirection
        active = true
    end

    -- 2. Process Movement
    if active then
        -- Force Running State for Animations
        hum:ChangeState(Enum.HumanoidStateType.Running)
        
        local step = moveVector * (glideSpeed * delta)
        local targetX, targetZ = hrp.Position.X + step.X, hrp.Position.Z + step.Z
        
        local distToSafe = 1000
        if savedPosition then
            distToSafe = (Vector3.new(targetX, 0, targetZ) - Vector3.new(savedPosition.Position.X, 0, savedPosition.Position.Z)).Magnitude
        end

        -- HEIGHT & JUMP LOGIC
        local finalY = hrp.Position.Y -- Default to current Y to allow jumping physics
        
        if movementMode == "Top (Over Guards)" then
            local landFade = (isReturning and distToSafe < 15) and (distToSafe / 15) or 1
            finalY = currentGroundY + (heightOffset * landFade)
        elseif not hum.Jump then
            -- If not jumping and in Normal/ZigZag, smoothly snap to ground height to prevent drifting
            finalY = math.lerp(hrp.Position.Y, currentGroundY, 0.1)
        end

        local finalPos = Vector3.new(targetX, finalY, targetZ)

        -- STABLE ZIGZAG
        if movementMode == "Middle Fast ZigZag" then
            local sideVector = Vector3.new(-moveVector.Z, 0, moveVector.X)
            if sideVector.Magnitude > 0.1 and distToSafe > 5 then
                local intensity = (isReturning and distToSafe < 15) and (distToSafe / 15 * 8) or 8
                finalPos = finalPos + (sideVector.Unit * math.sin(tick() * 14) * intensity)
            end
        end

        -- 3. Apply CFrame
        if isReturning and savedPosition then
            hrp.CFrame = CFrame.new(finalPos, Vector3.new(savedPosition.Position.X, finalPos.Y, savedPosition.Position.Z))
        else
            hrp.CFrame = CFrame.new(finalPos) * hrp.CFrame.Rotation
        end
    end
end)

-- Mobile Support
if UserInputService.TouchEnabled then
    ContextActionService:BindAction("SaveBaseMob", function(n, s) if s == Enum.UserInputState.Begin then SavePosition() end end, true)
    ContextActionService:SetPosition("SaveBaseMob", UDim2.new(0.5, 70, 0, -140))
    ContextActionService:SetTitle("SaveBaseMob", "Save Pos")
end

Rayfield:LoadConfiguration()
if LocalPlayer.Character then task.wait(1) ApplyBypass() end        })
    end
end

local function StopMovement()
    if currentTween then 
        currentTween:Cancel() 
        Rayfield:Notify({Title = "Stopped", Content = "Movement cancelled.", Duration = 1})
    end
end

-- Fast Proximity Prompt
game:GetService("ProximityPromptService").PromptShown:Connect(function(prompt)
    prompt.HoldDuration = 0
end)

-- Main Tab
local MainTab = Window:CreateTab("Main", 4483362458)

local GlideSection = MainTab:CreateSection("Movement Controls")

local TPWalkToggle = MainTab:CreateToggle({
   Name = "Enable TP Walk (Glide)",
   CurrentValue = false,
   Flag = "TPWalkToggle",
   Callback = function(Value)
      tpWalkEnabled = Value
   end,
})

MainTab:CreateSlider({
   Name = "Glide Speed (Studs/s)",
   Range = {0, 1000},
   Increment = 10,
   Suffix = "Studs/s",
   CurrentValue = 50,
   Flag = "GlideSlider",
   Callback = function(Value)
      glideSpeed = Value
   end,
})

MainTab:CreateSlider({
   Name = "Trap Avoid Height (Up)",
   Range = {5, 100},
   Increment = 5,
   Suffix = "Studs",
   CurrentValue = 25,
   Flag = "UpHeight",
   Callback = function(Value)
      upGlideDistance = Value
   end,
})

MainTab:CreateSection("Keybinds (PC)")

MainTab:CreateKeybind({
   Name = "Toggle TP Walk",
   CurrentKeybind = "Q",
   HoldToInteract = false,
   Flag = "Key1", 
   Callback = function()
      tpWalkEnabled = not tpWalkEnabled
      TPWalkToggle:Set(tpWalkEnabled)
   end,
})

MainTab:CreateKeybind({
   Name = "Glide UP (Avoid Trap)",
   CurrentKeybind = "E",
   HoldToInteract = false,
   Flag = "KeyUp",
   Callback = function()
      GlideUp()
   end,
})

MainTab:CreateKeybind({
   Name = "Save Position Key",
   CurrentKeybind = "Z",
   HoldToInteract = false,
   Flag = "Key2",
   Callback = function()
      SavePosition()
   end,
})

MainTab:CreateKeybind({
   Name = "Glide to Saved Key",
   CurrentKeybind = "X",
   HoldToInteract = false,
   Flag = "Key3",
   Callback = function()
      if savedPosition then
          GlideToPosition(savedPosition)
      end
   end,
})

MainTab:CreateKeybind({
   Name = "Emergency Stop Key",
   CurrentKeybind = "C",
   HoldToInteract = false,
   Flag = "Key4",
   Callback = function()
      StopMovement()
   end,
})

-- Actions Tab
local ActionTab = Window:CreateTab("Actions", 4483362458)

ActionTab:CreateButton({
   Name = "Bypass Anti-cheat (Humanoid Swap)",
   Callback = function()
      local char = LocalPlayer.Character
      if char then
          local hum = char:FindFirstChildOfClass("Humanoid")
          if hum then
              local newHum = hum:Clone()
              hum:Destroy()
              newHum.Parent = char
          end
      end
   end,
})

ActionTab:CreateButton({
   Name = "Glide to Stand",
   Callback = function()
      local targetPos = CFrame.new(544.57, 92.07, -364.86)
      GlideToPosition(targetPos)
   end,
})

ActionTab:CreateButton({
   Name = "Respawn Character",
   Callback = function()
      local char = LocalPlayer.Character
      if char and char:FindFirstChildOfClass("Humanoid") then
          char:FindFirstChildOfClass("Humanoid").Health = 0
      end
   end,
})

-- Logic: Heartbeat for TP Walk
RunService.Heartbeat:Connect(function(delta)
    if tpWalkEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        if hum and hrp and hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * glideSpeed * delta)
        end
    end
end)

Rayfield:LoadConfiguration()
