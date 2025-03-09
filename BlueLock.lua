-- สคริปต์สำหรับ LocalScript ใน StarterGui
-- สร้างในโฟลเดอร์ StarterGui

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- สร้าง ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FootballIndicatorGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

-- สร้างปุ่มสำหรับเปิด/ปิดเส้นบอก
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleIndicator"
toggleButton.Size = UDim2.new(0, 200, 0, 50)
toggleButton.Position = UDim2.new(0.05, 0, 0.1, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.BorderSizePixel = 0
toggleButton.Font = Enum.Font.GothamSemibold
toggleButton.Text = "แสดงเส้นชี้บอล"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 18
toggleButton.Parent = screenGui

-- สร้างปุ่มสำหรับเปิด/ปิดระบบวาร์ปอัตโนมัติ
local autoTeleportButton = Instance.new("TextButton")
autoTeleportButton.Name = "ToggleAutoTeleport"
autoTeleportButton.Size = UDim2.new(0, 200, 0, 50)
autoTeleportButton.Position = UDim2.new(0.05, 0, 0.18, 0)
autoTeleportButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
autoTeleportButton.BorderSizePixel = 0
autoTeleportButton.Font = Enum.Font.GothamSemibold
autoTeleportButton.Text = "เปิดวาร์ปอัตโนมัติ"
autoTeleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
autoTeleportButton.TextSize = 18
autoTeleportButton.Parent = screenGui

-- สร้างมุมโค้งให้กับปุ่ม
local cornerToggle = Instance.new("UICorner")
cornerToggle.CornerRadius = UDim.new(0, 8)
cornerToggle.Parent = toggleButton

local cornerAutoTeleport = Instance.new("UICorner")
cornerAutoTeleport.CornerRadius = UDim.new(0, 8)
cornerAutoTeleport.Parent = autoTeleportButton

-- สร้างป้ายสถานะการยิง
local shootCooldownLabel = Instance.new("TextLabel")
shootCooldownLabel.Name = "ShootCooldownLabel"
shootCooldownLabel.Size = UDim2.new(0, 200, 0, 30)
shootCooldownLabel.Position = UDim2.new(0.05, 0, 0.26, 0)
shootCooldownLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
shootCooldownLabel.BackgroundTransparency = 0.5
shootCooldownLabel.BorderSizePixel = 0
shootCooldownLabel.Font = Enum.Font.GothamSemibold
shootCooldownLabel.Text = "พร้อมยิง"
shootCooldownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
shootCooldownLabel.TextSize = 16
shootCooldownLabel.Visible = false
shootCooldownLabel.Parent = screenGui

local cornerCooldown = Instance.new("UICorner")
cornerCooldown.CornerRadius = UDim.new(0, 8)
cornerCooldown.Parent = shootCooldownLabel

-- สร้างเอฟเฟกต์เมื่อเมาส์ชี้ที่ปุ่ม
local function createButtonEffect(button, originalColor)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.3), {BackgroundColor3 = originalColor:Lerp(Color3.fromRGB(255, 255, 255), 0.2)}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.3), {BackgroundColor3 = originalColor}):Play()
    end)
    
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = originalColor:Lerp(Color3.fromRGB(0, 0, 0), 0.2)}):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = originalColor}):Play()
    end)
end

createButtonEffect(toggleButton, Color3.fromRGB(0, 120, 215))
createButtonEffect(autoTeleportButton, Color3.fromRGB(220, 50, 50))

-- ตัวแปรสำหรับการตรวจจับสถานะ
local isPlayerHoldingBall = false
local isShootingCooldown = false
local lastTarget = nil

-- ฟังก์ชันเพื่อหา Football MeshPart
local function findFootball()
    local football
    
    -- หาลูกบอลในทุกส่วนของเกม
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("MeshPart") and obj.Name == "Football" then
            football = obj
            break
        end
    end
    
    return football
end

-- ฟังก์ชันเพื่อหาประตู Away
local function findAwayGoal()
    local awayGoal
    
    -- หาประตู Away ในโฟลเดอร์ Goals
    if workspace:FindFirstChild("Goals") then
        if workspace.Goals:FindFirstChild("Away") then
            awayGoal = workspace.Goals.Away
        end
    end
    
    return awayGoal
end

-- ฟังก์ชันตรวจสอบว่าผู้เล่นกำลังถือบอลหรือไม่
local function checkIfHoldingBall()
    local football = findFootball()
    if not football then return false end
    
    -- ถ้าบอลอยู่ใกล้ตัวละครมากๆ ถือว่ากำลังถือบอล
    if character and character:FindFirstChild("HumanoidRootPart") then
        local distance = (football.Position - character.HumanoidRootPart.Position).Magnitude
        return distance < 5 -- ถ้าบอลอยู่ใกล้กว่า 5 studs ถือว่ากำลังถือบอล
    end
    
    return false
end

-- สร้างเส้นชี้ไปที่บอล
local indicatorLine
local connection
local isIndicatorActive = false

-- ฟังก์ชันเปิด/ปิดเส้นชี้
local function toggleIndicator()
    isIndicatorActive = not isIndicatorActive
    
    if isIndicatorActive then
        -- เปลี่ยนข้อความปุ่ม
        toggleButton.Text = "ซ่อนเส้นชี้บอล"
        
        -- สร้างเส้นชี้ถ้ายังไม่มี
        if not indicatorLine then
            indicatorLine = Instance.new("Part")
            indicatorLine.Name = "FootballIndicator"
            indicatorLine.Anchored = true
            indicatorLine.CanCollide = false
            indicatorLine.Material = Enum.Material.Neon
            indicatorLine.Color = Color3.fromRGB(255, 0, 0) -- สีแดง
            indicatorLine.Transparency = 0.3
            indicatorLine.Parent = workspace
        end
        
        -- อัพเดทเส้นทุก frame
        connection = RunService.RenderStepped:Connect(function()
            if character and character:FindFirstChild("HumanoidRootPart") then
                local hrp = character.HumanoidRootPart
                local target
                
                -- ตรวจสอบว่ากำลังถือบอลหรือไม่ เพื่อเลือกเป้าหมาย
                isPlayerHoldingBall = checkIfHoldingBall()
                
                if isPlayerHoldingBall then
                    -- ถ้าถือบอล ให้ชี้ไปที่ประตู
                    target = findAwayGoal()
                    if target then
                        lastTarget = "goal"
                    end
                else
                    -- ถ้าไม่ได้ถือบอล ให้ชี้ไปที่บอล
                    target = findFootball()
                    if target then
                        lastTarget = "ball"
                    end
                end
                
                if target then
                    -- สร้างเส้นจากตัวละครไปที่เป้าหมาย
                    local direction = (target.Position - hrp.Position)
                    local distance = direction.Magnitude
                    
                    -- ปรับขนาดและตำแหน่งของเส้น
                    indicatorLine.Size = Vector3.new(0.2, 0.2, distance)
                    indicatorLine.CFrame = CFrame.lookAt(hrp.Position, target.Position) * CFrame.new(0, 0, -distance/2)
                    indicatorLine.Transparency = 0.3
                    
                    -- ปรับสีตามเป้าหมาย
                    if lastTarget == "goal" then
                        indicatorLine.Color = Color3.fromRGB(255, 215, 0) -- สีทอง สำหรับประตู
                    else
                        indicatorLine.Color = Color3.fromRGB(255, 0, 0) -- สีแดง สำหรับบอล
                    end
                else
                    -- ซ่อนเส้นถ้าไม่พบเป้าหมาย
                    if indicatorLine then
                        indicatorLine.Transparency = 1
                    end
                end
            end
        end)
    else
        -- เปลี่ยนข้อความปุ่ม
        toggleButton.Text = "แสดงเส้นชี้บอล"
        
        -- ยกเลิกการอัพเดทและซ่อนเส้น
        if connection then
            connection:Disconnect()
            connection = nil
        end
        
        if indicatorLine then
            indicatorLine.Transparency = 1
        end
    end
end

-- ตัวแปรสำหรับระบบวาร์ปอัตโนมัติ
local isAutoTeleportActive = false
local autoTeleportConnection
local lastTeleportTime = 0
local teleportCooldown = 1 -- 1 วินาที

-- ฟังก์ชันสร้างเอฟเฟกต์วาร์ป
local function createTeleportEffect(fromPosition, toPosition)
    -- สร้างเอฟเฟกต์ก่อนวาร์ป
    local effect = Instance.new("Part")
    effect.Shape = Enum.PartType.Ball
    effect.Material = Enum.Material.Neon
    effect.Color = Color3.fromRGB(255, 255, 255)
    effect.Size = Vector3.new(1, 1, 1)
    effect.Position = fromPosition
    effect.Anchored = true
    effect.CanCollide = false
    effect.Parent = workspace
    
    -- สร้าง Tween สำหรับเอฟเฟกต์
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    local tween = TweenService:Create(effect, tweenInfo, {
        Size = Vector3.new(3, 3, 3),
        Transparency = 1
    })
    
    tween:Play()
    
    -- ลบเอฟเฟกต์หลังจากเล่นเสร็จ
    tween.Completed:Connect(function()
        effect:Destroy()
    end)
    
    -- สร้างเอฟเฟกต์หลังวาร์ป
    local effectAfter = Instance.new("Part")
    effectAfter.Shape = Enum.PartType.Ball
    effectAfter.Material = Enum.Material.Neon
    effectAfter.Color = Color3.fromRGB(255, 255, 255)
    effectAfter.Size = Vector3.new(3, 3, 3)
    effectAfter.Transparency = 1
    effectAfter.Position = toPosition
    effectAfter.Anchored = true
    effectAfter.CanCollide = false
    effectAfter.Parent = workspace
    
    -- สร้าง Tween สำหรับเอฟเฟกต์หลังวาร์ป
    local tweenInfoAfter = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
    local tweenAfter = TweenService:Create(effectAfter, tweenInfoAfter, {
        Size = Vector3.new(1, 1, 1),
        Transparency = 0
    })
    
    tweenAfter:Play()
    
    tweenAfter.Completed:Connect(function()
        local finalTween = TweenService:Create(effectAfter, TweenInfo.new(0.3), {Transparency = 1})
        finalTween:Play()
        finalTween.Completed:Connect(function()
            effectAfter:Destroy()
        end)
    end)
end

-- ฟังก์ชันวาร์ปไปที่เป้าหมาย
local function teleportToTarget(target)
    if not target or not character or not character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local hrp = character.HumanoidRootPart
    local currentTime = tick()
    
    -- ตรวจสอบ cooldown
    if currentTime - lastTeleportTime < teleportCooldown then
        return false
    end
    
    -- คำนวณตำแหน่งที่จะวาร์ปไป (ห่างจากเป้าหมายเล็กน้อย)
    local offset = Vector3.new(0, 2, 0) -- ยืน 2 studs เหนือเป้าหมาย
    local teleportPosition = target.Position + offset
    
    -- บันทึกตำแหน่งก่อนวาร์ปสำหรับเอฟเฟกต์
    local fromPosition = hrp.Position
    
    -- สร้างเอฟเฟกต์วาร์ป
    createTeleportEffect(fromPosition, teleportPosition)
    
    -- วาร์ปตัวละคร
    hrp.CFrame = CFrame.new(teleportPosition, teleportPosition + target.CFrame.LookVector)
    
    -- อัพเดทเวลาวาร์ปล่าสุด
    lastTeleportTime = currentTime
    
    return true
end

-- ฟังก์ชันเปิด/ปิดระบบวาร์ปอัตโนมัติ
local function toggleAutoTeleport()
    isAutoTeleportActive = not isAutoTeleportActive
    
    if isAutoTeleportActive then
        -- เปลี่ยนข้อความปุ่ม
        autoTeleportButton.Text = "ปิดวาร์ปอัตโนมัติ"
        autoTeleportButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50) -- เปลี่ยนเป็นสีเขียว
        
        -- เริ่มระบบวาร์ปอัตโนมัติ
        autoTeleportConnection = RunService.Heartbeat:Connect(function()
            -- ไม่วาร์ปถ้าอยู่ในช่วง cooldown ยิง
            if isShootingCooldown then
                return
            end
            
            -- ตรวจสอบว่ากำลังถือบอลหรือไม่
            isPlayerHoldingBall = checkIfHoldingBall()
            
            local target
            if isPlayerHoldingBall then
                -- ถ้าถือบอล ให้วาร์ปไปที่ประตู
                target = findAwayGoal()
            else
                -- ถ้าไม่ได้ถือบอล ให้วาร์ปไปที่บอล
                target = findFootball()
            end
            
            if target then
                teleportToTarget(target)
            end
        end)
        
        -- แสดงป้ายสถานะการยิง
        shootCooldownLabel.Visible = true
    else
        -- เปลี่ยนข้อความปุ่ม
        autoTeleportButton.Text = "เปิดวาร์ปอัตโนมัติ"
        autoTeleportButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50) -- เปลี่ยนกลับเป็นสีแดง
        
        -- ยกเลิกระบบวาร์ปอัตโนมัติ
        if autoTeleportConnection then
            autoTeleportConnection:Disconnect()
            autoTeleportConnection = nil
        end
        
        -- ซ่อนป้ายสถานะการยิง
        shootCooldownLabel.Visible = false
    end
end

-- ฟังก์ชันจัดการการยิง
local function handleShooting()
    if isShootingCooldown then
        return
    end
    
    -- ตรวจสอบว่ากำลังถือบอลหรือไม่
    isPlayerHoldingBall = checkIfHoldingBall()
    
    if isPlayerHoldingBall then
        -- เริ่ม cooldown
        isShootingCooldown = true
        shootCooldownLabel.Text = "กำลังยิง... (1 วิ)"
        shootCooldownLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        
        -- ตั้งค่า cooldown 1 วินาที
        local startTime = tick()
        local cooldownConnection
        
        cooldownConnection = RunService.Heartbeat:Connect(function()
            local elapsed = tick() - startTime
            local remaining = math.max(0, 1 - elapsed)
            
            if remaining > 0 then
                shootCooldownLabel.Text = string.format("กำลังยิง... (%.1f วิ)", remaining)
            else
                -- สิ้นสุด cooldown
                isShootingCooldown = false
                shootCooldownLabel.Text = "พร้อมยิง"
                shootCooldownLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                
                if cooldownConnection then
                    cooldownConnection:Disconnect()
                    cooldownConnection = nil
                end
            end
        end)
    end
end

-- เชื่อมต่อปุ่มกับฟังก์ชัน
toggleButton.MouseButton1Click:Connect(toggleIndicator)
autoTeleportButton.MouseButton1Click:Connect(toggleAutoTeleport)

-- จัดการคลิกซ้ายสำหรับการยิง
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton1 then
        handleShooting()
    end
end)

-- อัพเดทอ้างอิงตัวละครเมื่อมีการสร้างใหม่
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- รีเซ็ตสถานะต่างๆ
    isPlayerHoldingBall = false
    isShootingCooldown = false
    lastTarget = nil
    
    -- รีเซ็ตเส้นชี้ถ้ามีการใช้งานอยู่
    if isIndicatorActive and connection then
        connection:Disconnect()
        toggleIndicator() -- ปิดและเปิดใหม่
    end
    
    -- รีเซ็ตระบบวาร์ปอัตโนมัติถ้ามีการใช้งานอยู่
    if isAutoTeleportActive and autoTeleportConnection then
        autoTeleportConnection:Disconnect()
        toggleAutoTeleport() -- ปิดและเปิดใหม่
    end
end)
