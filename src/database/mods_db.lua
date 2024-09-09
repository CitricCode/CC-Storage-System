--                    mods_db                    --
--    A storage system for CC:T and CC:R mods    --
--         Copyright (C) 2024 CitricCode         --

--[[
   This module is an interface that extends base_db
   for a custom binary database used to store mod
   names.
   
   Format:
   Byte 1-2:   mod_id    (uint16)   PK
   Byte 3:     null byte (\0)
   Byte 4-n:   mod_name  (Null terminated string)
   
   Example:
   00 01  00 6D 69 6E 65 63 72 61 66 74 00
   [ID ]  [             name             ]
   
   Notes:
    - ID must be unique
    - ID starts from 1
    - Name is assumed to only contain alphabetical
      characters
    - The database has a null byte at the start for
      convenience
]]--
--- @module "types"

--- @class mod_data
--- @field id uint16: ID of the mod
--- @field name string: Name of the mod


local db_misc = require "database.db_misc"
local base_db = require "database.base_db"
base_db.db_path = "/databases/mods.db"

local mods_db = base_db:init()


--- Serialises mod data to be stored in database
--- @param data mod_data: Dict containing mod data
--- @return string raw_data: Serialised data
function mods_db:_serialise(data)
   -- print(data.id)
   local id = db_misc.to_str(2, data.id)
   -- print(id)
   return id..db_misc.pack_str(data.name)
end

--- Deserialises mod data to be used
--- @param raw_dat string: Serialised mod data
--- @return mod_data data: Deserialised data table
function mods_db:_deserialise(raw_dat)
   return {
      ["id"] = db_misc.to_num(raw_dat:sub(1, 2)),
      ["name"] = db_misc.unpack_str(raw_dat:sub(3))
   }
end

--- a = (require "database.mods_db"):init()
--- for a,b in a:_iterate() do print(a,b) end
function mods_db:_iterate()
   local srt, fin = 0, 0
   return function ()
      if fin == #self.db then return nil, nil end
      srt, fin = fin + 1, fin + 3
      while self.db:byte(fin)<128 do fin=fin+2 end
      fin = fin + 1
      return srt, fin
   end
end

--- Returns the start index and end index for where
--- the given mod is stored in the database
--- @param data mod_data: Dict containing item data
--- @return number|nil,number|nil: Nil if not found
function mods_db:_get_pos(data)
   local srt, fin
   if data.id then
      local id = db_misc.to_str(2, data.id)
      id = db_misc.esc_char(id).."\0(.-)\0"
      srt, fin = self.db:find(id)
   else
      local name = "\0..\0"..data.name.."\0"
      srt, fin = self.db:find(name)
   end
   return srt, fin
end


return mods_db