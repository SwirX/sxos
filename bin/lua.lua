-- /bin/lua.lua
-- Interactive Lua REPL for SXOS.
-- Provides a persistent evaluation environment across lines.
-- Supports multi-line input by detecting trailing incomplete expressions.
-- Type 'exit' or press Ctrl+D to quit.

local repl_env = setmetatable({}, { __index = _ENV })
repl_env._ENV = repl_env

print("SX Lua REPL. Type 'exit' to quit.")
print("Variables persist across lines.")
print("")

local line_count = 0
local accumulated = ""

while true do
    line_count = line_count + 1
    local prompt = (accumulated == "") and ("lua:%d> "):format(line_count) or ("   ...> ")
    io.write(prompt)
    local line = io.read()

    if line == nil or line == "exit" then
        break
    end

    local input = accumulated .. line

    -- Try to compile as an expression first (return <expr>).
    local as_expression = "return " .. input
    local expr_fn, _ = load(as_expression, "repl", "t", repl_env)
    if expr_fn then
        accumulated = ""
        local results = table.pack(pcall(expr_fn))
        if results[1] then
            for i = 2, results.n do
                local value = results[i]
                if value ~= nil then
                    print(tostring(value))
                end
            end
        else
            printError(tostring(results[2]))
        end
        goto continue
    end

    -- Try to compile as a statement block.
    local stmt_fn, stmt_err = load(input, "repl", "t", repl_env)
    if stmt_fn then
        accumulated = ""
        local ok, run_err = pcall(stmt_fn)
        if not ok then
            printError(tostring(run_err))
        end
    else
        -- If the error indicates an incomplete expression, accumulate more lines.
        if string.find(tostring(stmt_err), "<eof>") then
            accumulated = input .. "\n"
        else
            accumulated = ""
            printError(tostring(stmt_err))
        end
    end

    ::continue::
end
