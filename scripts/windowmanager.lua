---
---
---


aWindowList = {}; 
aIgnoredWindowClasses = {};

function onInit()
  -- set default window classes we dont only want singles for
  setIgnoredWindowClasses({"imagewindow","charsheet"});
  -- assign handlers
  Interface.onWindowOpened = onWindowOpened; 
  Interface.onWindowClosed = onWindowClosed; 
end

-- check if we have this type of window already
function oneWindowGroupExists(sName)
  return aWindowList[sName];
end

-- let extensions tweak this if they like
function setIgnoredWindowClasses(aList)
  aIgnoredWindowClasses = {"masterindex"}; -- we always ignore this
  for _,sIgnoredClass in pairs(aList) do
    table.insert(aIgnoredWindowClasses,sIgnoredClass);
  end
end

-- any window class in "aIgnoredWindowClasses" array will not be managed 
function ignoredWindowClass(sName)
  local bIgnored = false;
  for _,sIgnoredClass in pairs(aIgnoredWindowClasses) do
    if sName == sIgnoredClass then
      bIgnored = true;
      break;
    end
  end
  return bIgnored;
end

-- called when window opened
function onWindowOpened(window)
  local node = window.getDatabaseNode(); 
  if not window.getClass then
    --Debug.console("No class")
    return
  end
  local sName = window.getClass(); 
  local aNodes = aWindowList[sName]; 
  local sPath = nil; 
  --Debug.console("windowmanager.lua","onWindowOpened","node",node); 
  --Debug.console("windowmanager.lua","onWindowOpened","sName",sName); 
  --Debug.console("windowmanager.lua","onWindowOpened","aNodes",aNodes); 
  if node then
    aNodes = aWindowList[sName]; 
    -- ignore masterindex
    if not ignoredWindowClass(sName) then 
      if aWindowList[sName] then
        sPath = aNodes[#aNodes]; 
        local w = Interface.findWindow(sName,sPath); 
        if w then
          sPath = node.getPath(); 
          table.insert(aNodes,sPath); 
          window.setPosition(w.getPosition());
          window.setSize(w.getSize());
          -- if control down, we don't close current open window of this class
          -- else we close them
          if not Input.isControlPressed() then
            onWindowClosed(w); 
            w.close(); 
          end
        else
          -- window is not around/opened
          table.remove(aNodes,#aNodes); 
          if #aNodes == 0 then
            aWindowList[sName] = nil; 
          end
        end
      else
        sPath = node.getPath(); 
        aNodes = {}; 
        table.insert(aNodes, sPath); 
        aWindowList[sName] = aNodes; 
      end
    end
  end
end

-- function called when any window is closed.
function onWindowClosed(window)

  if not window.getClass then
    -- Debug.console("No class on close")
    return
  end
  local sName = window.getClass(); 
  local aNodes = aWindowList[sName]; 
  local sPath = nil; 
  local node = window.getDatabaseNode(); 
-- Debug.console("windowmanager.lua","onWindowClosed","node",node); 
-- Debug.console("windowmanager.lua","onWindowClosed","sName",sName); 
-- Debug.console("windowmanager.lua","onWindowClosed","aNodes",aNodes); 
  if node then
    local sPath = node.getPath(); 
    if aNodes ~= nil then
      for i = #aNodes,1,-1 do
        if aNodes[i] == sPath then
          table.remove(aNodes,i); 
          break; 
        end
      end
      if #aNodes == 0 then
        aWindowList[sName] = nil; 
      end
    end
  end
end
