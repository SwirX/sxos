local args = { ... }
if #args == 0 then return end
local formatStr = args[1]
local formatArgs = {}
for i = 2, #args do table.insert(formatArgs, args[i]) end
write(string.format(formatStr, table.unpack(formatArgs)))
