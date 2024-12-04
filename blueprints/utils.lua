local json = require('json')
local bint = require('.bint')(512)

local mod = {
  add = function(a, b)
      return tostring(bint(a) + bint(b))
  end,
  subtract = function(a, b)
      return tostring(bint(a) - bint(b))
  end,
  toBalanceValue = function(a)
      return tostring(bint(a))
  end,
  toNumber = function(a)
      return tonumber(a)
  end,
  lt = function (a, b)
      return bint.__lt(bint(a), bint(b))
  end
}

mod.getNoteIDs = function(data)
  if string.find(data, "null") then
    return nil
  end
  
  local noteIDs, err = json.decode(data)
  if err then
    return nil
  end

  if type(noteIDs) == "string" then
    return {noteIDs}
  end

  if type(noteIDs) == "table" then
    for i = 1, #noteIDs do
      if noteIDs[i] == nil or type(noteIDs[i]) ~= "string" then
        return nil
      end
    end
    return noteIDs
  end

  return nil
end

mod.SettlerIO = function (notes)
  local settlerIn = {}
  local settlerOut = {}

  local bc = {}
  for _, note in ipairs(notes) do
      if not bc[note.AssetID] then bc[note.AssetID] = bint(0) end
      if not bc[note.HolderAssetID] then bc[note.HolderAssetID] = bint(0) end
      bc[note.AssetID] = mod.add(bc[note.AssetID], note.Amount)
      bc[note.HolderAssetID] = mod.subtract(bc[note.HolderAssetID], note.HolderAmount)
  end
  
  for k, v in pairs(bc) do
      if v == '0' then bc[k] = nil end
  end

  for k, v in pairs(bc) do
      if mod.lt(v, '0') then
          settlerOut[k] = v
      else
          settlerIn[k] = v
      end
  end

  return settlerIn, settlerOut
end
    
return mod
