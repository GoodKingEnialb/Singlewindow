---
---
---

-- Variables
local aWindowList = {} 
local aIgnoredWindowClasses = {}
local fullWindowList = {}
local onWindowOpened_orig = nil
local onWindowClosed_orig = nil

function onInit()
  aWindowList = {} 
  aIgnoredWindowClasses = {}
  registerOptions()

  -- set default window classes we dont only want singles for
  -- setIgnoredWindowClasses({"imagewindow","charsheet"})
  changeOptions()

  -- squirrel away old functions
  onWindowOpened_orig = Interface.onWindowOpened
  onWindowClosed_orig = Interface.onWindowClosed

  -- assign handlers
  Interface.onWindowOpened = onWindowOpened 
  Interface.onWindowClosed = onWindowClosed 
end

function registerOptions()
	OptionsManager.registerOption2 (
        "SINGLEWINDOWIMAGES",
        true,
        "option_header_single_window",
        "option_label_single_window_images",
        "option_entry_cycler",
        {
            labels = "option_val_no",
            values = "no",
            baselabel = "option_val_yes",
            baseval = "yes",
            default = "no"
        }
    ) 

    OptionsManager.registerOption2 (
      "SINGLEWINDOWCHARS",
      true,
      "option_header_single_window",
      "option_label_single_window_chars",
      "option_entry_cycler",
      {
          labels = "option_val_no",
          values = "no",
          baselabel = "option_val_yes",
          baseval = "yes",
          default = "no"
      }
    ) 

    OptionsManager.registerOption2 (
      "SINGLEWINDOWITEMS",
      true,
      "option_header_single_window",
      "option_label_single_window_items",
      "option_entry_cycler",
      {
          labels = "option_val_no",
          values = "no",
          baselabel = "option_val_yes",
          baseval = "yes",
          default = "yes"
      }
    ) 

    OptionsManager.registerOption2 (
      "SINGLEWINDOWNPCS",
      true,
      "option_header_single_window",
      "option_label_single_window_npcs",
      "option_entry_cycler",
      {
          labels = "option_val_no",
          values = "no",
          baselabel = "option_val_yes",
          baseval = "yes",
          default = "yes"
      }
    ) 

    OptionsManager.registerOption2 (
      "SINGLEWINDOWVEHICLES",
      true,
      "option_header_single_window",
      "option_label_single_window_vehicles",
      "option_entry_cycler",
      {
          labels = "option_val_no",
          values = "no",
          baselabel = "option_val_yes",
          baseval = "yes",
          default = "yes"
      }
    ) 

    OptionsManager.registerCallback("SINGLEWINDOWIMAGES", changeOptions)
    OptionsManager.registerCallback("SINGLEWINDOWCHARS", changeOptions)
    OptionsManager.registerCallback("SINGLEWINDOWITEMS", changeOptions)
    OptionsManager.registerCallback("SINGLEWINDOWNPCS", changeOptions)
    OptionsManager.registerCallback("SINGLEWINDOWVEHICLES", changeOptions)
end

-- Change whether window classes are single only or multiple
function changeOptions()
  local ignoredWindowClasses = {}
  if OptionsManager.getOption("SINGLEWINDOWIMAGES") == "no" then
    table.insert(ignoredWindowClasses, "imagewindow")
  end
  if OptionsManager.getOption("SINGLEWINDOWCHARS") == "no" then
    table.insert(ignoredWindowClasses, "charsheet")
  end
  if OptionsManager.getOption("SINGLEWINDOWITEMS") == "no" then
    table.insert(ignoredWindowClasses, "item")
  end
  if OptionsManager.getOption("SINGLEWINDOWNPCS") == "no" then
    table.insert(ignoredWindowClasses, "npc")
  end
  if OptionsManager.getOption("SINGLEWINDOWVEHICLES") == "no" then
    table.insert(ignoredWindowClasses, "vehicle")
  end

  setIgnoredWindowClasses(ignoredWindowClasses)
end

-- check if we have this type of window already
function oneWindowGroupExists(sName)
  return aWindowList[sName]
end

-- let extensions tweak this if they like
function setIgnoredWindowClasses(aList)
  aIgnoredWindowClasses = {"masterindex", "charselect_host", "charselect_client"} -- we always ignore these
  -- Window classes:
  --  Images: imagewindow
  --  Characters: charsheet
  --  Notes: note
  --  Encounters: battle
  --  Items: item
  --  NPCs: npc
  --  Parcels: treasureparcel
  --  Quests: quest
  --  Story: encounter
  --  Tables: tables
  --  Vehicles: vehicle

  for _,sIgnoredClass in pairs(aList) do
    table.insert(aIgnoredWindowClasses,sIgnoredClass)
  end
end

-- any window class in "aIgnoredWindowClasses" array will not be managed 
function ignoredWindowClass(sName)
  local bIgnored = false
  for _,sIgnoredClass in pairs(aIgnoredWindowClasses) do
    if sName == sIgnoredClass then
      bIgnored = true
      break
    end
  end
  return bIgnored
end

-- called when window opened
function onWindowOpened(window)
  local node = window.getDatabaseNode() 
  if not window.getClass then
    --Debug.console("No class on open")
    return
  end
  local sName = window.getClass() 
  local aNodes = aWindowList[sName] 
  local sPath = nil 
--Debug.console("windowmanager.lua","onWindowOpened","node",node) 
--Debug.console("windowmanager.lua","onWindowOpened","sName",sName) 
--Debug.console("windowmanager.lua","onWindowOpened","aNodes",aNodes) 
  if node then
    -- Store the current window since FGU doesn't seem to be storing it consistently
    sPath = node.getPath() 
    local key = sName .. sPath
    fullWindowList[key] = window
    --Debug.console("Storing " .. type(window) .. " in " .. key)

    if not ignoredWindowClass(sName) then 
      --Debug.console("Not ignored")
      if aWindowList[sName] then
        local sPrevPath = aNodes[#aNodes] 
        --Debug.console("sPrevPath = " .. sPrevPath .. " numNodes = " .. #aNodes)

        -- local w = Interface.findWindow(sName,sPath) 
        local oldWindowKey = sName .. sPrevPath
        if oldWindowKey ~= key then
          local w = fullWindowList[oldWindowKey]
          --Debug.console("type(w) = " .. type(w))
          if w and type(w) == "windowinstance" then
            --Debug.console("Retrieved " .. type(w) .. " from " .. oldWindowKey)
            sPath = node.getPath() 
            --Debug.console("sPath2 = " .. sPath)
            table.insert(aNodes,sPath) 
            window.setPosition(w.getPosition())
            window.setSize(w.getSize())
            -- if control down, we don't close current open window of this class
            -- else we close them
            if not Input.isControlPressed() then
              --Debug.console("Closing window")
              --onWindowClosed(w) 
              w.close() 
              --removeNode(sName, aNodes)
            end
          else
            --Debug.console("No w")
            -- window is not around/opened
            removeNode(sName, aNodes)
          end
        --else
          --Debug.console("Same window")
        end
      end
      addWindow(node, sName)
    end
  end

  --onWindowOpened_orig(window)
end

-- function called when any window is closed.
function onWindowClosed(window)
  --Debug.console("Closing " .. window)
  local sName = nil
  if window.getClass then
    sName = window.getClass()
  else
    sName = window
  end
  local aNodes = aWindowList[sName] 
  local sPath = nil 
--Debug.console("windowmanager.lua","onWindowClosed","node",node) 
--Debug.console("windowmanager.lua","onWindowClosed","sName",sName) 
--Debug.console("windowmanager.lua","onWindowClosed","aNodes",aNodes) 

  removeNode(sName, aNodes)

  if onWindowClosed_orig then
    onWindowClosed_orig(window)
  end
end

-- Add a window to the window list
function addWindow(node, sName)
  sPath = node.getPath() 
  --Debug.console("addWindow sPath = " .. sPath)
  aNodes = {} 
  table.insert(aNodes, sPath) 
  aWindowList[sName] = aNodes 
  --Debug.console("Setting aWindowList[",sName,"] to ",aNodes)
end

-- Clean up the windows
function removeNode(sName, aNodes)
  if aNodes then
    table.remove(aNodes,#aNodes) 
    if #aNodes == 0 then
      aWindowList[sName] = nil 
    end
  end
end

-- DEBUG: Print the list of windows
function printWindowList()
  Debug.console("Windowlist:")
  local windowList = Interface.getWindows()
  local iter = 0
  for _,w in pairs(windowList) do
    Debug.console(iter .. ": ")
    Debug.console(w)
    if w.getClass then
      Debug.console("  class = " .. w.getClass())
    end
    if w.getDatabaseNode then
      local n = w.getDatabaseNode()
      if n then
        Debug.console("  path = " .. n.getPath())
      end
    end
    iter = iter + 1
  end
end