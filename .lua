local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Jen Hub", -- Changed title
   LoadingTitle = "Loading Script...",
   LoadingSubtitle = "made by Jen", -- Changed subtitle
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "GlideUtility",
      FileName = "Config"
   },
   KeySystem = false,
   Theme = "Bloom" -- This sets the UI color to Pink
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
local currentTween = nil
local savedPosition = nil

-- Fast Proximity Prompt
game:GetService("ProximityPromptService").PromptShown:Connect(function(prompt)
    prompt.HoldDuration = 0
end)

-- Main Tab
local MainTab = Window:CreateTab("Main", 4483362458)

local GlideSection = MainTab:CreateSection("Movement Controls")

MainTab:CreateToggle({
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

MainTab:CreateLabel("Tip: 600-700 is the smoothest glide")

local PositionSection = MainTab:CreateSection("Position Management")

MainTab:CreateButton({
   Name = "Save Current Position",
   Callback = function()
      local char = LocalPlayer.Character
      local hrp = char and char:FindFirstChild("HumanoidRootPart")
      if hrp then
         savedPosition = hrp.CFrame
         Rayfield:Notify({
            Title = "Position Saved",
            Content = "You can now glide back to this spot.",
            Duration = 3,
            Image = 4483362458,
         })
      end
   end,
})

MainTab:CreateButton({
   Name = "Glide to Saved Position",
   Callback = function()
      local char = LocalPlayer.Character
      local hrp = char and char:FindFirstChild("HumanoidRootPart")
      
      if hrp and savedPosition then
         local distance = (hrp.Position - savedPosition.Position).Magnitude
         local duration = distance / math.max(glideSpeed, 1)

         if currentTween then currentTween:Cancel() end

         currentTween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
             CFrame = savedPosition
         })
         
         currentTween:Play()
         
         Rayfield:Notify({
            Title = "Gliding",
            Content = "Moving to saved location...",
            Duration = 2,
            Image = 4483362458,
         })
      else
         Rayfield:Notify({
            Title = "Error",
            Content = "No position saved or Character not found!",
            Duration = 3,
            Image = 4483362458,
         })
      end
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
      local char = LocalPlayer.Character
      local hrp = char and char:FindFirstChild("HumanoidRootPart")
      local targetPos = CFrame.new(544.57, 92.07, -364.86)
      
      if hrp then
          local distance = (hrp.Position - targetPos.Position).Magnitude
          local duration = distance / math.max(glideSpeed, 1)
          
          if currentTween then currentTween:Cancel() end
          currentTween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
              CFrame = targetPos
          })
          currentTween:Play()
      end
   end,
})

ActionTab:CreateButton({
   Name = "Stop ALL Movement",
   Callback = function()
      if currentTween then currentTween:Cancel() end
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
