local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Jen Hub",
   LoadingTitle = "Loading Script...",
   LoadingSubtitle = "made by Jen",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "GlideUtility",
      FileName = "Config"
   },
   KeySystem = false,
   Theme = "Bloom" -- Pink Theme
})

-- Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Variables
local LocalPlayer = Players.LocalPlayer
local tpWalkEnabled = false
local glideSpeed = 50
local upGlideDistance = 25 -- How high you go to avoid traps
local currentTween = nil
local savedPosition = nil

-- Logic Functions
local function SavePosition()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        savedPosition = hrp.CFrame
        Rayfield:Notify({
            Title = "Position Saved",
            Content = "You can now glide back to this spot.",
            Duration = 2,
            Image = 4483362458,
        })
    end
end

local function GlideToPosition(targetCFrame)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if hrp and targetCFrame then
        local distance = (hrp.Position - targetCFrame.Position).Magnitude
        local duration = distance / math.max(glideSpeed, 1)

        if currentTween then currentTween:Cancel() end

        currentTween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            CFrame = targetCFrame
        })
        
        currentTween:Play()
    end
end

local function GlideUp()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        -- Calculates current position + the up distance
        local target = hrp.CFrame * CFrame.new(0, upGlideDistance, 0)
        GlideToPosition(target)
        Rayfield:Notify({
            Title = "Trap Avoidance",
            Content = "Gliding Up!",
            Duration = 1.5,
            Image = 4483362458,
        })
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
