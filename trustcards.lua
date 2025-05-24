--[[
    Copyright © 2025, Bryenne - Sylph server [DragonGuard]
    All rights reserved.
]]

-- Windower Add On Mandatory fields
_addon.name = 'TrustCards'
_addon.author = 'Bryenne'
_addon.version = '0.9.5'
_addon.commands = {'tc'}

-- windower library imports
packets = require('packets')	-- to be able to receive data from the game
res = require('resources')		-- to look up general resource names
images = require('images')		-- to be able to use graphics
texts = require ('texts')		-- to be able to print advanced texts
config = require ('config')		-- to load and save settings
require('strings')
require('lists')
require('tables')

-- [INITIALIZATION] ------------------------------------------------>
	windower_settings = windower.get_windower_settings()
	-- local variables initialization
	chat = windower.add_to_chat
	player = windower.ffxi.get_player()
	-- location of trust portraits
	p_path = windower.addon_path .. 'assets/portraits/'
	-- location of UI elements
	ui_path = windower.addon_path .. 'assets/window/'
	ui_window = L{'window.png','window_gr.png','window_gg.png','window_sb.png'}

	-- settings
	defaults = {}
	defaults.pos = {}
	defaults.pos.x = (((windower_settings.ui_x_res - 256)/2)-400)
	defaults.pos.y = ((windower_settings.ui_y_res - 134)/2)
	defaults.txt_job = {}
	defaults.txt_job.red = 255
	defaults.txt_job.green = 255
	defaults.txt_job.blue = 0
	defaults.txt_subjob = {}
	defaults.txt_subjob.red = 60
	defaults.txt_subjob.green = 197
	defaults.txt_subjob.blue = 150
	defaults.txt_traits = {}
	defaults.txt_traits.red = 145
	defaults.txt_traits.green = 214
	defaults.txt_traits.blue = 222
	defaults.bg = {}
	defaults.bg.image = 1
	defaults.bg.alpha = 255
	defaults.bg.red = 255
	defaults.bg.green = 255
	defaults.bg.blue = 255

	settings = config.load(defaults)
	config.save(settings)

-- handles commands given to the add on by user
windower.register_event('addon command', function(command, ...)
    command = command and command:lower()
    local params = {...}

    if command == 'pos' then
        local x, y = tonumber(params[1]), tonumber(params[2])
        if x and y then
            settings.pos.x = x
			settings.pos.y = y
			settings:save('all')
			chat(005, ':: Trust Cards position set to: X='..x..' and Y='..y..'. ::')
        end
    elseif command == "bg" then
		settings.bg.image = tonumber(params[1])
		settings:save('all')
		chat(005,':: Trust Cards background image set to: background '..settings.bg.image..'. ::')
    elseif command == 'alpha' then
        -- changes the alpha setting of the window 
		local w_alpha = tonumber(params[1])
		settings.bg.alpha = w_alpha
		settings:save('all')
		chat(005, ':: Trust Cards alpha set to: '..w_alpha..'. ::')
    elseif command == 'test' then
        -- changes the alpha setting of the window 
		if not params[1] then
			chat(005, ':: Trust Cards is exiting test mode ::')
			check_UI()
		else
			-- if an image already exists
			check_UI()

			test_name = tostring(params[1])
			if params[2] then
				test_name = test_name .." "..tostring(params[2]) -- in case we are looking up a name with a space in it, we need to check this and combine them to one string
			end
			chat(005, ':: Trust Cards is in test mode :: testing '..test_name)
			test_name = test_name:lower()
			find_trust(test_name)
		end
    else
        chat(005, 'tc help : Shows help message')
        chat(005, 'tc pos <x> <y> : Sets the position of the cards')
        chat(005, 'tc bg [1-4]: changes the background image; 1 = classic FFXI 2 = Red gradient 3 = Green gradient 4 = Heavy Metal Plate')
        chat(005, 'tc alpha [0-255]: sets the transparancy of the window ONLY (255 = solid, 0 = invisible) - does not affect text or portrait')
		chat(005, 'tc test [name]: show the card for the named trust without summoning, for quick check or reading up on traits. Leave blank to exit test mode')
    end
end)

-- [MAIN CODE] ----------------------------------------------------------------------------------->

-- something is happening
windower.register_event('incoming chunk', function(id, data)

		-- if the something is an action event
		if id == 0x028 then
		
			-- retrieve action data from the FFXI packet, "parse_action" immediately creates the fields we need
			local act_data = windower.packets.parse_action(data)
			if act_data.actor_id == player.id then
			
				-- category 8 is casting a spell, which is the only thing we are looking for
				if act_data.category == 8 then
					
					-- if the casting parameter is 28787 it means the casting attempt was not succesful, so we skip it
					if act_data.param ~= 28787 then
					
						-- retrieve the spell ID from the FFXI packet data
						local spell_id = act_data.targets[1].actions[1].param
						
						-- this function checks if the spell_id exists in our custom trusts table (at the bottom of this lua)
						trust_id = get_trust(spell_id)
						
						-- if there was a match, retrieve the information from the trusts table that we need
						if trust_id then
						
							-- check if an image already exists and destroy it
							check_UI()
							
							-- set default variables to empty
							trust_j = "" -- job
							trust_sj = "" -- subjob
							trust_l1 = "" -- comment line 1
							trust_l2 = "" -- comment line 2
							
							-- this looks up the spell name from the Windower resources (spells.lua in /res)
							spell_name = res.spells[spell_id].en
							Get_Info(trust_id)

							-- create content
							create_UI()

						end
					end
				elseif act_data.category == 4 then
					-- when done casting, hide everything with a slight delay (the number after end, is the delay)
					coroutine.schedule(function()
						hide_UI()
						cleanup()
					end, 2)
				end
				trust_id = nil
			end
		end
	end)
	
-- [OBJECT CREATION LOGIC] ----------------------------------------------------------------------->	
	
function create_UI()
		
		-- Create Window -------------------------------------->
		posX = settings.pos.x
		posY = settings.pos.y
		winSize = 300
		
		-- determine approximate size of window based on Trust name
		name_length = string.len(spell_name)
		if name_length > 12 then
			winSize = 400
		elseif name_length > 8 then
			winSize = 350
		else
			winSize = 300
		end
				
		-- adjust window size based on trait strings
		if string.len(trust_l1) > 40 or string.len(trust_l2) > 40 then
			if winSize < 401 then
				winSize = 440
			end
		elseif string.len(trust_l1) > 35 or string.len(trust_l2) > 35 then 
			if winSize < 400 then
				winSize = 400
			end
		elseif string.len(trust_l1) > 25 or string.len(trust_l2) > 25 then
			if winSize < 350 then
				winSize = 350
			end
		end
		--chat(008,string.len(spell_name) .. ', ' .. string.len(trust_l1) .. ', ' .. string.len(trust_l2) .. ', window=' .. winSize)		-- enable this line to check winSize decisions
		
		-- draw Window
		ui_settings = Get_Window()
		ui_img = images.new(img_def)
		
		-- Create Portrait ------------------------------------>
		if string.find(spell_name,"(UC)") then
			-- remove (UC) from trust names so they match portraits
			spell_name = string.sub(spell_name,1,-6)
		end
		
		img_settings = Get_Portrait(spell_name)
		tr_img = images.new(img_def)
		
		-- Create Trust Name and Job text object -------------->
		txt_settings = Get_TxtSettings("Name")
		tr_name = texts.new(spell_name, txt_settings)
		-- create Trust Job text object
		txt_settings = Get_TxtSettings("Job")
		tr_job = texts.new(trust_j, txt_settings)

		-- Draw a '/' divider and the subjob if the trust has a subjob
		if trust_sj ~= "" then
			job_div = ' / '
			txt_settings = Get_TxtSettings("Div")
			tr_div = texts.new(job_div, txt_settings)

			txt_settings = Get_TxtSettings("Subjob")
			tr_subjob = texts.new(trust_sj, txt_settings)
		end
		
		-- Create trait lines --------------------------------->
		if trust_l1 ~= "" then
			txt_settings = Get_TxtSettings("Line1")
			tr_ln1 = texts.new(trust_l1, txt_settings)
			dot_img = Get_Dot(1)
			tr_dot1 = images.new(img_def)
		end
		
		if trust_l2 ~= "" then
			txt_settings = Get_TxtSettings("Line2")
			tr_ln2 = texts.new(trust_l2, txt_settings)
			dot_img = Get_Dot(2)
			tr_dot2 = images.new(img_def)
		end
		show_UI()
end

-- [SHOW/HIDE/DESTROY] --------------------------------------------------------------------------->

function show_UI()
		
		-- After creating, show all items in the correct order >
		ui_img:show() -- window
		tr_img:show() -- portrait
		tr_name:show() -- trust name
		tr_job:show() -- trust job

		-- show subjob and ' / ' divider
		if tr_subjob then
			tr_div:show()
			tr_subjob:show()
		end

		-- trait lines
		if tr_dot1 then
			tr_dot1:show()
		end
		if tr_ln1 then
			tr_ln1:show()
		end
		if tr_dot2 then
			tr_dot2:show()
		end
		if tr_ln2 then
			tr_ln2:show()
		end
end

function hide_UI()
		
		-- Hide elements - even before clean up
		if ui_img then
			ui_img:hide() -- window
			tr_img:hide() -- portrait
			tr_name:hide() -- trust name
			tr_job:hide() -- trust job

			-- hide subjob and ' / ' divider
			if tr_subjob then
				tr_div:hide()
				tr_subjob:hide()
			end

			-- Hide trait lines
			if tr_dot1 then
				tr_dot1:hide()
			end
			if tr_ln1 then
				tr_ln1:hide()
			end
			if tr_dot2 then
				tr_dot2:hide()
			end
			if tr_ln2 then
				tr_ln2:hide()
			end
		end
end

function cleanup()

	-- clean text strings
	trust_j = nil
	trust_sj = nil
	trust_l1 = nil
	trust_l2 = nil
	-- clean variables
	tr_subjob = nil
	tr_ln1 = nil
	tr_ln2 = nil
	-- clean images
	tr_dot1 = nil
	tr_dot2 = nil
end

-- Helper functions ------------------------------------------------------------------------------>

-- get information from the database based on spell_ID (this is for normal functionality)
function get_trust(spell_id)

	-- look through the trusts table below to see if the spell_id matches a trust spell
	for index=1,table.getn(trusts),1 do
	
		-- if the spell_id is found in the trusts table
        if trusts[index].id == spell_id then
            trust_id = index
        end
    end
	
	return trust_id
end


-- get the required information on the trust being summoned or tested
function Get_Info(trust_id)
							
	-- Get Trust's main job (should always be filled)
	trust_j = trusts[trust_id].job

	-- load Trust info in variables and deal with empty fields
	if trusts[trust_id].subjob ~= "" then
		trust_sj = trusts[trust_id].subjob
	else
		trust_sj = ""
	end
	if trusts[trust_id].line1 ~= "" then
		trust_l1 = trusts[trust_id].line1
	else
		trust_l1 = ""
	end
	if trusts[trust_id].line2 ~= "" then
		trust_l2 = trusts[trust_id].line2
	else
		trust_l2 = ""
	end
end


-- get information from the database based on trust name (this is for 'test' functionality only)
function find_trust(name)
	
	local found = false
	
	for index=1,table.getn(trusts),1 do

		local trust_name = string.lower(trusts[index].name) -- make all lower case	
		spell_name = res.spells[trusts[index].id].en
		-- if the spell_id is found in the trusts table
        if trust_name:find('^'..test_name) or string.lower(spell_name):find('^'..test_name) then
			trust_id = index
			chat (004,"Found trust! No="..index..", Id="..trusts[index].id..", Full name="..spell_name)
			if not first_result then 
				-- we only display the first result
				first_result = index
			end
        end
    end
	
	if not first_result then
		chat (004,"No trusts found with a name that starts with "..test_name)
	else
		trust_id = first_result
		spell_name = res.spells[trusts[trust_id].id].en
		Get_Info(trust_id)
		create_UI()
		first_result = nil
		return spell_name
	end
end


-- remove existing image before drawing a new one
function check_UI()
	if ui_img then
		hide_UI()
		cleanup()
	end
end


-- Changes text colors based on background image for readability
function Set_Text_Colors(bg)

	if bg == 2 then								-- for "Gradient Red" background window
		defaults.txt_job.red = 255
		defaults.txt_job.green = 255
		defaults.txt_job.blue = 0

		defaults.txt_subjob.red = 234
		defaults.txt_subjob.green = 198
		defaults.txt_subjob.blue = 112

		defaults.txt_traits.red = 255
		defaults.txt_traits.green = 170
		defaults.txt_traits.blue = 170
	elseif bg == 3 then 						-- for "Gradient Green" background window
		defaults.txt_job.red = 255
		defaults.txt_job.green = 255
		defaults.txt_job.blue = 0

		defaults.txt_subjob.red = 102
		defaults.txt_subjob.green = 214
		defaults.txt_subjob.blue = 224

		defaults.txt_traits.red = 144
		defaults.txt_traits.green = 244
		defaults.txt_traits.blue = 168
	elseif bg == 4 then							-- for "Heavy Metal Plate" background window
		defaults.txt_job.red = 194
		defaults.txt_job.green = 254
		defaults.txt_job.blue = 252

		defaults.txt_subjob.red = 144
		defaults.txt_subjob.green = 200
		defaults.txt_subjob.blue = 220

		defaults.txt_traits.red = 222
		defaults.txt_traits.green = 255
		defaults.txt_traits.blue = 242
	else										-- Default / "Classic FFXI" background window
		defaults.txt_job.red = 255
		defaults.txt_job.green = 255
		defaults.txt_job.blue = 0

		defaults.txt_subjob.red = 60
		defaults.txt_subjob.green = 197
		defaults.txt_subjob.blue = 150

		defaults.txt_traits.red = 145
		defaults.txt_traits.green = 214
		defaults.txt_traits.blue = 222
	end

end

-- [UI GRAPHICS SETTINGS ------------------------------------------------------------------------->

-- WINDOW SETTINGS -------------------------------------------->

function Get_Window ()

	-- Create Main Window
	img_path = (ui_path .. ui_window[settings.bg.image])
	Set_Text_Colors(settings.bg.image)
	
	img_def = {}
	img_def.pos = {}
		img_def.pos.x = posX
		img_def.pos.y = posY
	img_def.color = {}
		img_def.color.alpha = settings.bg.alpha
	img_def.texture = {}
		img_def.texture.path = img_path
		img_def.texture.fit = false -- we want this image to be scalable
	img_def.size = {}
		img_def.size.height = 104
		img_def.size.width = winSize -- scales depending on length of the name of the trust
		img_def.draggable = false
		img_def.repeatable = {}
		img_def.repeatable.x = 1
		img_def.repeatable.y = 1
		
	return img_def
end

-- PORTRAIT SETTINGS ------------------------------------------>

function Get_Portrait (img)

	-- Create Portrait
	img_path = (p_path .. img .. '.png')
	
	-- If a portrait file does not exist, use the default "unknown" image
	if not windower.file_exists(img_path) then
		img_path = (p_path .. 'unknown.png')
	end
	
	img_def = {}
	img_def.pos = {}
		img_def.pos.x = (posX-81) -- offset with main window
		img_def.pos.y = (posY-30)
	img_def.texture = {}
		img_def.texture.path = img_path
		img_def.texture.fit = true
	img_def.size = {}
		img_def.size.height = 134
		img_def.size.width = 162
		img_def.draggable = false
		img_def.repeatable = {}
		img_def.repeatable.x = 1
		img_def.repeatable.y = 1
		
	return img_def
end

-- BULLET POINTS SETTINGS ------------------------------------->

function Get_Dot (nr)

	-- Create Bullet Point dots
	img_path = (ui_path .. 'dot.png')
	
	img_def = {}
	img_def.pos = {}
		-- Whether this is the first or second dot determines Y position change
		img_def.pos.x = (posX + 82)
		if nr == 1 then
			img_def.pos.y = (posY + 73)
		elseif nr == 2 then
			img_def.pos.y = (posY + 87)
		end
	img_def.texture = {}
		img_def.texture.path = img_path
		img_def.texture.fit = true
	img_def.size = {}
		img_def.size.height = 8
		img_def.size.width = 8
		
	return img_def
end


-- [TRUST TEXT SETTINGS] ------------------------------------------------------------------------->
function Get_TxtSettings (Text)
	-- settings to overwrite default settings for a new string (default settings in /texts.lua)
	-- only settings that you want to change need to be listed
	
	if Text == "Name" then
		-- create settings tables
		txt_def = {}
		txt_def.pos = {}
		txt_def.bg = {}
		txt_def.flags = {}
		txt_def.flags.draggable = false
		txt_def.text = {}
		txt_def.text.stroke = {}
	
		txt_def.pos.x = (posX + 48)
		txt_def.pos.y = (posY - 2)
		txt_def.bg.visible = false
		txt_def.text.font = "Candara"
		txt_def.text.size = 30
		txt_def.flags.italic = true
		txt_def.text.stroke.width = 2
		txt_def.text.stroke.alpha = 255
	elseif Text == "Job" then
		txt_def.pos.x = (posX + 58)
		txt_def.pos.y = (posY + 42)
		txt_def.flags.bold = true
		txt_def.text.size = 14
		txt_def.text.red = defaults.txt_job.red
		txt_def.text.green = defaults.txt_job.green
		txt_def.text.blue = defaults.txt_job.blue
	elseif Text == "Div" then
		-- determine the best distance between job and divider so it lines up nicely
		jobln = (string.len(trust_j)*10)
		if jobln <= 40 then -- for really short job names like bard or monk...
			jobln = 50 -- we add a bit more spacing
		elseif trust_j == "Paladin" or trust_j == "Bard" then
			jobln = (jobln - 5) -- Paladin needs a bit less spacing
		elseif trust_j == "Corsair" then
			jobln = (jobln - 10) -- corsair needs less spacing
		elseif trust_j == "Geomancer" or trust_j == "Red Mage" then
			jobln = (jobln + 5) -- Geomancer needs a bit more spacing
		end
		
		txt_def.pos.x = (posX + 58 + jobln)
		txt_def.text.red = 255
		txt_def.text.green = 255
		txt_def.text.blue = 255
	elseif Text == "Subjob" then
		txt_def.pos.x = (posX + 75 + jobln)
		txt_def.text.red = defaults.txt_subjob.red
		txt_def.text.green = defaults.txt_subjob.green
		txt_def.text.blue = defaults.txt_subjob.blue
	elseif Text == "Line1" then
		txt_def.pos.x = (posX + 92)
		txt_def.pos.y = (posY + 64)
		txt_def.flags.bold = false
		txt_def.flags.italic = false
		txt_def.text.size = 11
		txt_def.text.red = defaults.txt_traits.red
		txt_def.text.green = defaults.txt_traits.green
		txt_def.text.blue = defaults.txt_traits.blue
	elseif Text == "Line2" then
		txt_def.pos.x = (posX + 92)
		txt_def.pos.y = (posY + 78)
	end
		
	return txt_def
end

-- [TRUSTS TABLE DATA] ---------------------------------------------------------------------------> TODO: Make this a seperate file

trusts = T{
    [1]={id=896,name="Shantotto",job="Black Mage", subjob="", line1="Stays at range",line2=""},
    [2]={id=897,name="Naji", job="Warrior", subjob="", line1="Does not Skillchain", line2="Will use Provoke"},
    [3]={id=898,name="Kupipi",job="White Mage", subjob="", line1="Prioritizes status ailments", line2="Will overwrite lower tier Prot/Shell"},
    [4]={id=899,name="Excenmille",job="Paladin", subjob="", line1="Uses Sentinel and Flash",line2="Prioritizes healing"},
    [5]={id=900,name="Ayame",job="Samurai", subjob="", line1="Waits for player to have TP", line2="Always opens Skillchains"},
    [6]={id=901,name="NanaaMihgo",job="Thief", subjob="", line1="Has an AoE 'stun' TP Move", line2="Can use despoil and get items"},
    [7]={id=902,name="Curilla",job="Paladin", subjob="", line1="Only uses Flash for enmity", line2="Does not Skillchain"},
    [8]={id=903,name="Volker",job="Warrior", subjob="", line1="Will tank in a party without tanks", line2="Pure DD otherwise, uses Agressor/Berserk"},
    [9]={id=904,name="Ajido-Marujido",job="Black Mage", subjob="Red Mage", line1="Prioritizes dispel", line2="Highest elemental/enfeebling skill (A+)"},
    [10]={id=905,name="Trion",job="Paladin", subjob="Warrior", line1="Does not try to Skillchain", line2="Stuns TP Moves with Royal Bash"},
    [11]={id=906,name="Zeid",job="Dark Knight", subjob="", line1="Casts stun and uses stun TP move", line2="Very fashionable mask"},
    [12]={id=907,name="Lion",job="Thief", subjob="", line1="Treasure Hunter I + Gilfinder", line2="Uses stun TP moves"},
    [13]={id=908,name="Tenzen",job="Samurai", subjob="", line1="Can self-Skillchain up to 3-step", line2="Will try to close Skillchains"},
    [14]={id=909,name="MihliAliapoh", job="White Mage", subjob="", line1="Has high Healing Magic Skills", line2="Does not Skillchain"},
    [15]={id=910,name="Valaineral",job="Paladin", subjob="Warrior", line1="Tanks multiple targets", line2="Unique WS 'Uriel Blade'"},
    [16]={id=911,name="Joachim",job="Bard", subjob="White Mage", line1="Songs and Cures", line2="Cures and Songs"},
    [17]={id=912,name="NajaSalaheem", job="Monk", subjob="Warrior", line1="Are you slacking OFF " .. player.name .. "?!? ACQUHBAH!", line2="Weaponskills at 1,000 TP"},
    [18]={id=913,name="Prishe", job="Monk", subjob="White Mage", line1="Uses Curaga when party is asleep", line2="Does not Skillchain"},
    [19]={id=914,name="Ulmia",job="Bard", subjob="", line1="Stays at a distance", line2="Favors March Songs"},
    [20]={id=915,name="ShikareeZ", job="Dragoon", subjob="White Mage", line1="Uses Super Jump when she has hate", line2="Prioritizes Haste and dispelling Slow"},
    [21]={id=916,name="Cherukiki", job="White Mage", subjob="", line1="Uses high-tier Regens", line2="Stays at range"},
    [22]={id=917,name="IronEater", job="Warrior", subjob="", line1="Enhanced double attack", line2="Will use Restraint and get full TP"},
    [23]={id=918,name="Gessho", job="Ninja", subjob="Warrior", line1="Blink tank", line2="Ideal for avoiding light-based Skillchains"},
    [24]={id=919,name="Gadalar", job="Black Mage", subjob="", line1="Recovers MP when hit by physical attacks", line2="Unique AoE WS that applies Dia III"},
    [25]={id=920,name="Rainemard", job="Red Mage", subjob="Paladin", line1="Very powerful Enspells", line2="Only enhances himself"},
    [26]={id=921,name="Ingrid", job="White Mage", subjob="", line1="Highest priority Cursna caster", line2="Will close Skillchains"},
    [27]={id=922,name="LehkoHabhoka", job="Thief", subjob="Black Mage", line1="Very high double/triple attack", line2="Weaponskills at 1,000 TP"},
    [28]={id=923,name="Nashmeira", job="Puppetmaster", subjob="White Mage", line1="Cures low HP party members", line2="Uses stun TP move at 1,000 TP"},
    [29]={id=924,name="Zazarg", job="Monk", subjob="", line1="Uses Focus on mobs with high evasion",line2="Unique weaponskill 'Meteoric Impact'"},
    [30]={id=925,name="Ovjang", job="Red Mage", subjob="Black Mage", line1="Prioritizes Dispel",line2="Will try to close Skillchains"},
    [31]={id=926,name="Mnejing", job="Paladin", subjob="Warrior", line1="Best damage negation",line2=""},
    [32]={id=927,name="Sakura", job="Geomancer", subjob="Bard", line1="Indi-Regen, can't die",line2="Physical Skill gain+"},
    [33]={id=928,name="Luzaf", job="Corsair", subjob="Ninja", line1="Opens and closes Skillchains", line2="Uses Quick Draw"},
    [34]={id=929,name="Najelith", job="Ranger", subjob="", line1="Will try to close Skillchains at 1,500 TP", line2="Enhanced Critical Rate"},
    [35]={id=930,name="Aldo", job="Thief", subjob="Ninja", line1="Closes Skillchains up to 2,000 TP", line2="Treasure Hunter"},
    [36]={id=931,name="Moogle", job="Geomancer", subjob="", line1="Indi-Refresh & Magical Skill Gain+ Kupo",line2="Does not engage, take damage, or die"},
    [37]={id=932,name="Fablinix", job="Thief", subjob="Red Mage", line1="Will stun enemy's TP moves",line2="Will cast cure on low HP party members"},
    [38]={id=933,name="Maat", job="Monk", subjob="Thief", line1="Weapon skills at 1,000 TP",line2="Treasure Hunter"},
    [39]={id=934,name="D.Shantotto", job="Black Mage", subjob="", line1="Uses -aga spells", line2="Can nuke Tier V before engaging"},
    [40]={id=935,name="StarSibyl", job="Geomancer", subjob="Bard", line1="Indi-Acumen Matt/Macc+", line2="Doesn't take damage and cannot die"},
    [41]={id=936,name="Karaha-Baruha", job="White Mage", subjob="Summoner", line1="Will try to Skillchain", line2="Uses Spirit Taker when low on MP"},
    [42]={id=937,name="Cid", job="Warrior", subjob="Ranger", line1="Will Berserk + Weaponskill", line2="Only closes Skillchains"},
    [43]={id=938,name="Gilgamesh", job="Samurai", subjob="Warrior", line1="Will close Skillchains", line2="Will self-Skillchain at 2,000 TP"},
    [44]={id=939,name="Areuhat", job="Warrior", subjob="Paladin", line1="Can use Wyrm Weaponskills", line2="Will try to close Skillchains"},
    [45]={id=940,name="SemihLafihna", job="Ranger", subjob="Warrior", line1="Will close Skillchains", line2="Great trust for XP parties"},
    [46]={id=941,name="Elivira", job="Ranger", subjob="Warrior", line1="Weaponskill at 1,000 TP", line2="Will try to close Skillchains"},
    [47]={id=942,name="Noillurie", job="Samurai", subjob="Paladin", line1="Heavily favors light-based Skillchains", line2="Prefers to open Skillchains"},
    [48]={id=943,name="LhuMhakaracca", job="Beastmaster", subjob="Warrior", line1="Uses Feral Howl when enemy is low HP", line2=""},
    [49]={id=944,name="FerreousCoffin", job="White Mage", subjob="Warrior", line1="Uses Randgrith as soon as he has TP", line2="Will raise players (Raise III)"},
    [50]={id=945,name="Lilisette", job="Dancer", subjob="", line1="Sensual Dance / Rousing Samba are AoE buffs", line2="Does not Skillchain"},
    [51]={id=946,name="Mumor", job="Dancer", subjob="Warrior", line1="Uses Haste and Drain Samba", line2="Uses Stutter Step"},
    [52]={id=947,name="UkaTotlihn", job="Dancer", subjob="Warrior", line1="Uses Curing Waltz for AoE heals", line2="Uses Quick Step, and Reverse Flourish"},
    [53]={id=948,name="Klara", job="Warrior", subjob="", line1="Weaponskills at 1,000 TP", line2="Will use Provoke if player is low on HP"},
    [54]={id=949,name="RomaaMihgo", job="Thief", subjob="Warrior", line1="Uses Aura Steal (steals buff)", line2="Aura Steal can give items, which the player receives"},
    [55]={id=950,name="KuyinHathdenna", job="Geomancer", subjob="Bard", line1="Indi-Precision Acc+/R.Acc+", line2="Does not engage, take damage, or die"},
    [56]={id=951,name="Rahal", job="Paladin", subjob="Warrior", line1="Aggressive tank, uses Flash and Provoke", line2="Tries to stun with Shield Bash"},
    [57]={id=952,name="Koru-Moru",job="Red Mage",subjob="White Mage",line1="Casts Haste II / Refresh II", line2="He likes Big Buffs and he cannot lie"},
    [58]={id=953,name="Pieuje", job="White Mage", subjob="Paladin", line1="Has auto-Regain and auto-Refresh", line2="Will use Esuna when Misery is active"},
    [59]={id=954,name="InvincibleShld", job="Warrior", subjob="Corsair", line1="Uses Tomahawk on select enemies", line2="Will try to close Skillchains"},
    [60]={id=955,name="Apururu", job="White Mage", subjob="Red Mage", line1="Will use Curaga, Stoneskin and Devotion", line2="High auto-Regain (75 TP/t)"},
    [61]={id=956,name="JakohWahcondalo", job="Thief", subjob="Warrior", line1="Will SA·TA Weaponskills above 2,000 TP", line2="Does not try to Skillchain"},
    [62]={id=957,name="Flaviria", job="Dragoon", subjob="Warrior", line1="Weaponskills Weaponskills Weaponskills", line2="Excellent DD for leveling, very aggressive"},
    [63]={id=958,name="Babban", job="Monk", subjob="", line1="Does not try to Skillchain", line2="Uses Photosynthesis during daytime"},
    [64]={id=959,name="Abenzio", job="Monk", subjob="Warrior", line1="Has a huge max HP Boost", line2="Does not Skillchain"},
    [65]={id=960,name="Rughadjeen", job="Paladin", subjob="", line1="Uses Chivalry at 50% MP", line2="Will raise players (Raise I)"},
    [66]={id=961,name="Kukki-Chebukki", job="Black Mage", subjob="", line1="Casts elemental magic based on day", line2="Does nothing on lightsday"},
    [67]={id=962,name="Margret", job="Ranger", subjob="Thief", line1="Tries to stay at a distance", line2="Treasure Hunter I"},
    [68]={id=963,name="Chacharoon", job="Thief", subjob="Ranger", line1="TP Moves apply debuffs (incl Amnesia)", line2="Does not Skillchain"},
    [69]={id=964,name="LheLhangavo", job="Monk", subjob="Warrior", line1="Uses Formless Strikes when useful", line2="Will try to close Skillchains"},
    [70]={id=965,name="Arciela", job="Red Mage", subjob="Paladin", line1="Refresh II and Haste II", line2="Uses Curaga TP Move"},
    [71]={id=966,name="Mayakov", job="Dancer", subjob="Warrior", line1="Does not Skillchain", line2="Uses Feather Step and Climactic Flourish"},
    [72]={id=967,name="Qultada", job="Corsair", subjob="White Mage", line1="Uses Dark Shot (dispel) & Light Shot", line2="Defaults Chaos Roll / Fighter's Roll"},
    [73]={id=968,name="Adelheid", job="Scholar", subjob="Black Mage", line1="Casts a storm on herself", line2="Will Magic Burst and use stun"},
    [74]={id=969,name="Amchuchu", job="Rune Fencer", subjob="Warrior", line1="Very rapidly builds enmity", line2="Excellent magic tank"},
    [75]={id=970,name="Brygid", job="Geomancer", subjob="Bard", line1="DEF+ / MDEF+ aura", line2="Does not engage, take damage, or die"},
    [76]={id=971,name="Mildaurion", job="Paladin", subjob="Samurai", line1="Will open and close Skillchains", line2="Weaponskills at ~1,500 TP"},
    [77]={id=972,name="Halver", job="Paladin", subjob="Warrior", line1="Only acts as tank when HP is low", line2="Uses Berserk as much as possible"},
    [78]={id=973,name="Rongelouts", job="Warrior", subjob="", line1="Longer than normal Warcry", line2="Unique 'Beastmen Killer' trait"},
    [79]={id=974,name="Leonoyne", job="Black Mage", subjob="Paladin", line1="Has permanent Enblizzard effect", line2="Gains MP from taking damage"},
    [80]={id=975,name="Maximilian", job="Thief", subjob="Ninja", line1="Will open and close Skillchains", line2="Treasure Hunter I"},
    [81]={id=976,name="Kayeel-Payeel", job="Black Mage", subjob="Summoner", line1="Does not engage", line2="Magic Bursts Ice/Lightning only"},
    [82]={id=977,name="Robel-Akbel", job="Black Mage", subjob="Summoner", line1="Will Magic Burst", line2="Uses Stun on enemy TP moves"},
    [83]={id=978,name="Kupofried", job="Geomancer", subjob="Bard", line1="+20% Dedication / Commitment", line2="Does not engage, take damage, or die"},
    [84]={id=979,name="Selh\'teus", job="Paladin", subjob="Samurai", line1="Restores HP, MP and TP to entiry party", line2="Will close Skillchains at max TP"},
    [85]={id=980,name="Yoran-Oran", job="White Mage", subjob="Black Mage", line1="Turns auto-regain TP to MP", line2="Cure potency +50%"},
    [86]={id=981,name="Sylvie", job="Geomancer", subjob="White Mage", line1="Casts Indocolure spells & Entrust", line2="Does not engage but has Regain"},
    [87]={id=982,name="Abquhbah", job="Warrior", subjob="Monk", line1="Will try to close Skillchains", line2="'Salaheem Spirit' raises all attributes of party"},
    [88]={id=983,name="Balamor", job="Dark Knight", subjob="Black Mage", line1="Cures will damage him", line2="Immune to Drain-type spells"},
    [89]={id=984,name="August", job="Paladin", subjob="Warrior", line1="'Daybreak' is -50% PDT + Full Erase", line2="Does not Skillchain"},
    [90]={id=985,name="Rosulatia", job="Black Mage", subjob="Dark Knight", line1="Does not Skillchain", line2="Does not Magic Burst"},
    [91]={id=986,name="Teodor", job="Black Mage", subjob="Dark Knight", line1="Can not be healed with cures", line2="Does magic bursts"},
    [92]={id=987,name="Ullegore", job="Black Mage", subjob="Dark Knight", line1="Massive MP pool (~5k)", line2="Uses Stun on enemy TP moves"},
    [93]={id=988,name="Makki-Chebukki", job="Ranger", subjob="Black Mage", line1="Stays at a distance", line2="Does not Skillchain"},
    [94]={id=989,name="KingOfHearts", job="Red Mage", subjob="White Mage", line1="Actively debuffs and enfeebles", line2="Uses dispel on enemy"},
    [95]={id=990,name="Morimar", job="Beastmaster", subjob="Warrior", line1="Will try to close Skillchains", line2="'Vehement Resolution' is full heal + full debuff"},
    [96]={id=991,name="Darrcuiln", job="Warrior", subjob="Red Mage", line1="High HP Pool", line2="Does not Skillchain"},
    [97]={id=992,name="ArkHM", job="Ninja", subjob="Warrior", line1="Behaves as tank if there is none", line2="Behaves as DD if there is one"},
    [98]={id=993,name="ArkEV", job="Paladin", subjob="White Mage", line1="Single target tank", line2="Will close light/dark SC"},
    [99]={id=994,name="ArkMR", job="Beastmaster", subjob="Thief", line1="Will use SA·TA + WeaponSkill", line2="Treasure Hunter I"},
    [100]={id=995,name="ArkTT", job="Black Mage", subjob="Dark Knight", line1="Will stun and sleep", line2="Will Magic Burst"},
    [101]={id=996,name="ArkGK", job="Samurai", subjob="Dragoon", line1="Can self-skillchain at 2,000 TP", line2="Will try to close Skillchains"},
    [102]={id=997,name="Iroha", job="Samurai", subjob="White Mage", line1="Will try to solo Skillchain", line2="Resurrected if she dies"},
    [103]={id=998,name="Ygnas", job="White Mage", subjob="Paladin", line1="Cure Potency +50% / Fast Cast +50%", line2="Stays at a distance"},
    [104]={id=1004,name="Excenmille", job="Warrior", subjob="'Stags Call' is Hastega + 15% Att+ + MAB +15", line1="", line2="Will Weaponskill at 1,000 TP"},
    [105]={id=1005,name="Ayame", job="Samurai", subjob="", line1="", line2=""},
    [106]={id=1006,name="Maat", job="Monk", subjob="", line1="", line2=""},
    [107]={id=1007,name="Aldo", job="Thief", subjob="Ninja", line1="Excellent SC buddy for THF", line2="Will open Skillchains With 'Sarva's Storm'"},
    [108]={id=1008,name="NajaSalaheem", job="Monk", subjob="", line1="", line2=""},
    [109]={id=1009,name="Lion", job="Thief", subjob="Ninja", line1="Will try to close Skillchains", line2="Treasure Hunter / Gilfinder"},
    [110]={id=1010,name="Zeid", job="Samurai", subjob="Dragoon", line1="Uses High Jump and Konzen-Ittai", line2="Will close SC and self-SC"},
    [111]={id=1011,name="Prishe", job="White Mage", subjob="Monk", line1="Has phys/mag immunity abilities (5s)", line2="Casts Curaga to wake party"},
    [112]={id=1012,name="Nashmeira", job="White Mage", subjob="Puppetmaster", line1="Uses Curaga heals", line2="Uses stun TP move at 1,000 TP"},
    [113]={id=1013,name="Lilisette", job="Dancer", subjob="Warrior", line1="Very high attack rate", line2="Uses Rousing Samba (Crit+)"},
    [114]={id=1014,name="Tenzen", job="Samurai", subjob="Ranger", line1="Stays out of range", line2="Only opens Skillchains"},
    [115]={id=1015,name="Mumor", job="Black Mage", subjob="Dancer", line1="Will Magic Burst", line2="Uses Stun on enemy TP moves"},
    [116]={id=1016,name="Ingrid", job="White Mage", subjob="Warrior", line1="Will try to close Skillchains", line2="Excellent against undead"},
    [117]={id=1017,name="Arciela", job="Red Mage", subjob="Black Mage", line1="Haste II and Refresh II", line2="Will Magic Burst high-tier spells"},
    [118]={id=1018,name="Iroha", job="Samurai", subjob="White Mage", line1="Will try to solo Skillchain", line2="AoE HP/MP + Stoneskin Ability"},
    [119]={id=1019,name="Shantotto", job="Black Mage", subjob="White Mage", line1="Best Magic Burster around", line2="Will close Skillschains and MB"},
    [120]={id=1002,name="Cornelia", job="Samurai", subjob="", line1="", line2=""},
    [121]={id=999,name="Monberaux", job="Paladin", subjob="Runefencer", line1="'Chemist' that uses items", line2="Does not engage"},
    [122]={id=1003,name="Matsui-P", job="Ninja", subjob="Black Mage", line1="Will open and close Skillchains", line2="Magic Bursts with Ninjitsu"},
}