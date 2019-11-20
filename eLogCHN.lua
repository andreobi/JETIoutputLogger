--[[
Description

This is a simple logger extention for JETI remote control devices.
You can select Output or Trainer channels you want to log.
Depending on your device you can have upto 24 log channels in total over
all applications. If you wand to deletea log channel, go to the row 
select it and choose "del"
It is not possible to register a channel twice.
Due to the system design it also makes no sence to sort the log channels.

This application requiers V4.28 


Licence:

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

]]
-- when you reached 24 log channels it might be, even if you deleted a channel that
-- you are not able do add another channel: work around delete one and restart the 
-- application - don't ask me why
--
-- how to get long name to to label and output channels???
--
----------------------------------------------------------------------
-- Locals for the application
local appName ="Ext Channel Logger"
local extLog								-- [logId]{label,unit,orderNum}
local lastSel=0
-- const
local logMax=24								-- maximum of Log channels
local chMax=24								-- maximum of Servo output channels
local tMax=16								-- maximum of Trainer inputs
local selDel="del"							-- 

----------------------------------------------------------------------
-- write logger data by return value [,resolution]
local function callbackLog(logId)
--  pcall ???
  return system.getInputs(extLog[logId].label)*1000,3
end

----------------------------------------------------------------------
-- configuration menue
local function initForm()
  local liInputLabel									-- list of selected inputs to be display
  local liInputIndex									-- list id to logId
  local revLogTab={}									-- list orderNum to  logId
  
  local liChannel={}									-- list to select new input from
  
  liChannel[1]=selDel
  for i=2, (chMax+tMax+1), 1 do
    if i<=chMax+1 then
      liChannel[i]="O"..(i-1)
	else
      liChannel[i]="T"..(i-chMax-1)
    end	  
  end

------
  local function initLiInput()							-- create display list
    revLogTab={}
    for logId,v in pairs(extLog) do
	  if v.orderNum and logId then
	    revLogTab[v.orderNum]=logId
	  end
    end
    liInputLabel={}
	liInputIndex={}
	local index=1
	liInputLabel[index]="New"
	liInputIndex[index]=nil
    for orderNum=1, logMax,1 do
      local logId=revLogTab[orderNum]
	  if logId then
        if extLog[logId] and extLog[logId].label then
          if extLog[logId].label then
            index=index+1
            liInputLabel[index]=extLog[logId].label
			liInputIndex[index]=logId
          end
	    end
      end
    end
  end
------
  local function changeInput(slIndex)					-- handle selected switchItem
	local selctedRow
	local double
	local highlight
----
    local function setLogChannel(orderNum,unit)			-- register log channel
      local logId =system.registerLogVariable(slInput,unit,callbackLog)
      if logId then										-- got log channel
        extLog[logId]={}
        extLog[logId].label=slInput
        extLog[logId].unit=unit
        extLog[logId].orderNum=orderNum
		return logId
      else
        system.messageBox ("<< "..slInput.." >> not registered",3)
		return nil
      end
	end
----
    local function clearLogChannel(logId)
      system.unregisterLogVariable(logId)
      extLog[logId]=nil
    end
----
    slInput= liChannel[slIndex]
    lastSel=slIndex
	selctedRow=form.getFocusedRow()
	double = false
    if slInput~=selDel then								-- got an item
      for i, label in pairs(liInputLabel) do
        if label == slInput then						-- already present
          double=true
	      if selctedRow > 1 then
            local changeLgId=liInputIndex[selctedRow]	-- look up logID
			local changeOrNu=extLog[changeLgId].orderNum
            clearLogChannel(changeLgId)					-- delete entry to change
			if liInputIndex[i]~=changeLgId then
              clearLogChannel(liInputIndex[i])			-- delete douplicate
            end
			if setLogChannel(changeOrNu,"") then	-- set entry to change
		      highlight=slInput
            end
          else
            local changeLgId=liInputIndex[i]			-- replace douplicate
			local changeOrNu=extLog[changeLgId].orderNum
            clearLogChannel(changeLgId)
			if setLogChannel(changeOrNu,"") then
		      highlight=slInput
            end
		  end
          break
        end
      end
      if double==false then								
        if selctedRow>1 then							-- change log channel
          local changeLgId=liInputIndex[selctedRow]		-- look up logID
          local changeOrNu=extLog[changeLgId].orderNum
          clearLogChannel(changeLgId)
          if setLogChannel(changeOrNu,"") then
		    highlight=slInput
          end
        else											-- create new log channel
          local done=false
          for orderNum=1, logMax,1 do					-- find empty entry
            local logId=revLogTab[orderNum]
            if logId == nil then
              setLogChannel(orderNum,"")
			  done=true
			  break
			end
		  end
		  if not done then
            system.messageBox ("<< "..slInput.." >> not registered",3)
          end
        end
	  end
    else
      if selctedRow>1 then								-- clear selected row
        local clearLgId=liInputIndex[selctedRow]
        clearLogChannel(clearLgId)
		form.setFocusedRow(selctedRow-1)
      end	
	end
    initLiInput()
    if highlight then									-- find row to highlight
      for i, label in pairs(liInputLabel) do
	    if highlight==label then
		  form.setFocusedRow(i)
        end
      end
	end
    form.reinit()
    for i=1, logMax, 1 do								-- save changes
	  local logId=revLogTab[i]
	  if logId and extLog[logId].label then
        system.pSave("exCHLg"..i,extLog[logId].label)
      else 
	    system.pSave("exCHLg"..i,nil)
	  end
    end
  end
--
  initLiInput()
  for lineId, label in ipairs(liInputLabel) do			-- display List
    form.addRow(2)
	if lineId>1 then
      form.addLabel({label= extLog[liInputIndex[lineId]].orderNum.." - Log Ch: "..liInputIndex[lineId].."  "..extLog[liInputIndex[lineId]].label})
      form.addSelectbox(liChannel,0,true,changeInput)
    else
      local newSw
      form.addLabel({label="New:"})
      form.addSelectbox(liChannel,lastSel,true,changeInput)
	end
  end
end

----------------------------------------------------------------------
-- Application initialization
local function init()
-- check device and set maxLog

  extLog={}
  
  for i=1, logMax, 1 do
    local label=system.pLoad("exCHLg"..i)		-- read previous configuration
    if label then
	  local logId =system.registerLogVariable(label,"",callbackLog)
      if logId then									-- got log channel
        extLog[logId]={}
        extLog[logId].label=label
        extLog[logId].unit="READ"					-- ??? properties
		extLog[logId].orderNum=i
      end
	end
  end

  system.registerForm(1,MENU_APPS,appName,initForm)
end
----------------------------------------------------------------------
-- Runtime functions
local function loop()
  -- NOP
end
----------------------------------------------------------------------

return {init=init, loop=loop, author="Andre", version="0.20", name=appName}
