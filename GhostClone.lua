local RS = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TS = game:GetService("TweenService")
local GhostClone = {}


local SkipType = {
	Humanoid = true,
	Shirt = true,
	Pants = true,


}

local isEnabled = false
local isActive = false
local CloneModelFolder
local Conn = nil
local CloneAmount = 0
--------FUNCTIONS 

--Enabled
--Runtime
--MakeClone
--TweenClone
--GiveHighlight
--EndCloning

---------

-- Add a mode as the first/second parameter like cloneonce, cloneamount, keep cloning etc

--Starts the cloning and calls the Runtime which will run every heartbeat.
-- Sets isEnabled to true to tell the runservice to keep playing until it is asked to be set to false
-- CustomTable will contain: will the player will have a colour highlight, will it have an outline highlight, will it have the players Cosmetics or not

--modes will be made here
function GhostClone.Enabled(char:CharacterMesh, Amount:boolean | number, CustomTable:SharedTable, IterationPerSec:number, duration:number)
	if isActive then return end
	isActive = true -- idk why i use this but ya
	isEnabled = true 

	GhostClone.Runtime(char, Amount, CustomTable, IterationPerSec, duration)

end


-- Runtime checker and intiallise of the cloning
function GhostClone.Runtime(char:CharacterMesh, Amount:boolean | number, CustomTable:SharedTable, IterationPerSec:number, duration:number)

	if isEnabled == true then 

		if not CloneModelFolder then -- keep things organised
			CloneModelFolder = Instance.new("Folder",game.Workspace)
			CloneModelFolder.Name = "CloneFolder"
		end

		local TweenInfo = TweenInfo.new(duration,Enum.EasingStyle.Sine,Enum.EasingDirection.Out,0,false,0) -- its here cus of duration
		local TimePassed = IterationPerSec - 1 -- so it starts one second later and after everything runs at set  iteration


		Conn = RS.Heartbeat:Connect(function(dt) -- for every single heartbeat we will create a clone then tween it here
			if TimePassed > IterationPerSec then -- To control how many clones appear per second: dt keeps things accurate and consistent

				if typeof(Amount) == "number" then -- if set amount of clones then this will play else Conn will play until asked to stop
					if CloneAmount > Amount then

						GhostClone.EndCloning()
						print("Amount Reached!!!!!")
						return
					else
						print(CloneAmount)
						CloneAmount += 1
					end
				end


				local Clone = GhostClone.MakeClone(char,CustomTable)

				if CustomTable.Highlight == true then -- if allow highlight then we get highlight and/or outline
					GhostClone.GiveHighlight(Clone,CustomTable)
				end

				for _, part in pairs(Clone:GetChildren())   do -- find what  can be tweened in the clone

					local myType = part.ClassName
					if SkipType[myType] then continue end -- skiptype is a table of assests in the char that have been cloned that do not need to be tweened(they are not visible)

					GhostClone.TweenClone(part,myType,TweenInfo) -- tween transparency

					task.delay(duration,function() -- delete when clone is done tweening
						Clone:Destroy()
					end)
				end
				TimePassed = 0 
			else
				TimePassed += dt
			end
		end)
	end
end

-- The place where the custom clone is made every heartbeat
-- Customise it in the future 
function GhostClone.MakeClone(char:CharacterMesh, Table)
	-- filter how to loop through the character and clone assests based on the custometable
	local clonechar = Instance.new("Model",CloneModelFolder or game.Workspace)

	local function SetUpProperties(myPart) -- prevent code repetition
		myPart.Anchored = true
		myPart.CanCollide = false
		myPart.CanTouch = false
		myPart.CanQuery = false
		myPart.CollisionGroup = "Ghost"
		myPart.Transparency = 0.2
	end

	for i, Part:Part in pairs(char:GetChildren()) do

		if not Table.Allowed[Part.ClassName] and  Part.Name ~= "HumanoidRootPart"	then continue end	-- Can use IsA but that will include meshes and other things because if we say Isa:("BasePart") then anything that INHERITS from basepart will pass

		local Clonepart = Part:Clone()
		if Clonepart.ClassName == "Part" and Part.Name ~= "HumanoidRootPart" then 	--Clonepart:ClearAllChildren() useful to destroy all children in a part

			for _, child in pairs(Clonepart:GetChildren()) do 		-- This is just for the head
				if child.Name ~= "Mesh"  then 
					child:Destroy()
				end
			end				
			SetUpProperties(Clonepart)
			Clonepart.Parent = clonechar

		elseif Clonepart.ClassName == "Accessory" then
			-- TO NOTE: PERFORMANCE IS BETTER BY JUST KEEPING THE ASSESTS THAT ARE NOT VISIBLE THEN JUST DELETING THEM 
			for _, child in pairs(Clonepart.Handle:GetChildren()) do
				if  child.Name == "AccessoryWeld" then -- becuase AccessoryWeld causes the character to get stuck
					child:Destroy()
				end
			end
			
			local Handle = Clonepart.Handle
			SetUpProperties(Handle)
			Clonepart.Parent = clonechar

		elseif Clonepart.ClassName == "Humanoid"or Clonepart.ClassName == "Shirt" or Clonepart.ClassName == "Pants"then -- need humanoid because of texture look
			Clonepart.Parent = clonechar
		end
		-- future check other properties if they are true and if yes then apply
	end
	return clonechar
end

-- in the future for more customisation move all the values into one table were each type will be a function that will
-- return both the tweentarget and the targetproperties. But Also I could customise the transparncy better instead of hardcoding

-- For example I make a function at the start that will give theses tranparency values into a table in this module from the customtable
-- that was already sent over by the client.
function GhostClone.TweenClone(part,Type,TweenInfo)
	local TweenTarget
	local TweenProperties

	if Type == "Part" or Type == "MeshPart" then
		TweenTarget = part
		TweenProperties = {Transparency = 1} 

	elseif part:IsA("Highlight") then 
		TweenTarget = part
		TweenProperties = {FillTransparency = 1, OutlineTransparency = 1} 

	elseif part:IsA("Accessory") and part:FindFirstChild("Handle") then
		TweenTarget = part.Handle
		TweenProperties = {Transparency = 1}
	end	

	if TweenTarget and TweenProperties then 

		local Tween = TS:Create(TweenTarget,
			TweenInfo,
			TweenProperties)

		Tween:Play()

		Tween.Completed:Once(function()
			if part:IsA("Highlight") then
				part.Enabled = false
			end
			part:Destroy()
		end)  	
	end
end

-- works
function GhostClone.GiveHighlight(clonechar,myTable)
	local CreatedHighlight = false -- easily check if a highlight was created so if we only want outline we can create a highglight wihtout looping through the character
	local Highlight

	if clonechar.Parent.Name == "CloneFolder" then
		if myTable.Highlight == true then 
			CreatedHighlight = true
			Highlight = Instance.new("Highlight",clonechar)
			Highlight.FillColor = myTable.HighlightColour or Color3.fromRGB(255, 255, 255)
		else 
			Highlight.OutlineTransparency = 1
		end

		if myTable.Outline == true then
			if CreatedHighlight == false then 
				CreatedHighlight = true
				Highlight = Instance.new("Highlight",clonechar)
			end
			Highlight.OutlineColor = myTable.OutlineColour or Color3.fromRGB(255, 255, 255)
		end

	else
		return "Skipped"
	end	
end


--Stop cloning
function GhostClone.EndCloning()
	if isEnabled == true  and isActive then
		isEnabled = false or nil
		isActive = false
		Conn:Disconnect()
		Conn = nil
		task.spawn(function()
			print(CloneModelFolder:GetChildren())
			while #CloneModelFolder:GetChildren() > 0 do
				task.wait(0.1)
			end
			Debris:AddItem(CloneModelFolder,1)
			CloneModelFolder = nil
		end)


	end
end


return GhostClone
