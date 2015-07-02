 
require("auxlib");

Buttons = {
        "A",
        "B",
        "up",
        "down",
        "left",
        "right",
}

BoxRadius = 6

function getSprites()
        local sprites = {}
        for slot=0,4 do
                local enemy = memory.readbyte(0xF+slot)
                if enemy ~= 0 then
                        local ex = memory.readbyte(0x6E + slot)*0x100 + memory.readbyte(0x87+slot)
                        local ey = memory.readbyte(0xCF + slot)+24
                        sprites[#sprites+1] = {["x"]=ex,["y"]=ey}
                end
        end
       
        return sprites
end

function getPositions()
        marioX = memory.readbyte(0x6D) * 0x100 + memory.readbyte(0x86)
        marioY = memory.readbyte(0x03B8)+16

        screenX = memory.readbyte(0x03AD)
        screenY = memory.readbyte(0x03B8)
end

function getInputs()
        getPositions()
        sprites = getSprites()
        dist = {}
        for i = 1,#sprites do
                distx = (marioX) - sprites[i]["x"] 
                disty = (marioY) - sprites[i]["y"] 
                dist[#dist+1] = {distx, disty}
        end       
        return dist
end

function getTile(dx, dy)
        local x = marioX + dx + 8
        local y = marioY + dy - 16
        local page = math.floor(x/256)%2

        local subx = math.floor((x%256)/16)
        local suby = math.floor((y - 32)/16)
        local addr = 0x500 + page*13*16+suby*16+subx
       
        if suby >= 13 or suby < 0 then
                return 0
        end
       
        if memory.readbyte(addr) ~= 0 then
                return 1
        else
                return 0
        end
end

function minimap()
        getPositions()
       
        sprites = getSprites()       
        local inputs = {}
       
        for dy=-BoxRadius*16,BoxRadius*16,16 do
                for dx=-BoxRadius*16,BoxRadius*16,16 do
                        inputs[#inputs+1] = 0
                       
                        tile = getTile(dx, dy)
                        if tile == 1 and marioY+dy < 0x1B0 then
                                inputs[#inputs] = 1
                        end
                       
                        for i = 1,#sprites do
                                distx = math.abs(sprites[i]["x"] - (marioX+dx))
                                disty = math.abs(sprites[i]["y"] - (marioY+dy))
                                if distx <= 8 and disty <= 8 then
                                        inputs[#inputs] = -1
                                end
                        end
                end
        end
       
        return inputs
end

Events = {}
function newEvent()
        local event = {}
        event.ID = #Events+1
        event.InitiationSet={}
        event.ExpectedReward = 0
        event.Termination = 0
end


function clearJoypad()
        controller = {}
        for b = 1,#Buttons do
                controller[Buttons[b]] = false
        end
        joypad.set(1, controller)
end

function RandomMotion()
        controller={}
        n = math.random(1, #Buttons)
        controller[Buttons[n]] = true

        joypad.set(1,controller)
end

xoffset = 50
yoffset = 50
        
while true do
        print(getInputs())
        print(getSprites())
        RandomMotion()
        inputs = minimap()
        num = 0
        local color = 0xFF0000FF
        x = 50
        y = 50
        for i = 1, #inputs do
                x = x+1
                if inputs[i] > 0 then
                        gui.pixel(x, y, "black")
                elseif inputs[i] < 0  then
                        gui.pixel(x, y, "red")
                end
                if x%12 == 0 then
                        y = y+1
                end
        end
        --print(#inputs)
        --print(inputs)
        
        
        emu.frameadvance();
end