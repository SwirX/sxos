-- /bin/diff.lua
-- Line-by-line diff between two files.
-- Output follows a simplified UNIX diff style: context lines are unmarked,
-- removed lines are prefixed with "-", added lines with "+".
-- This is a standard LCS-based diff, not a trivial line comparison, so it
-- correctly handles insertions and deletions together.

local args = { ... }
if #args < 2 then
    print("Usage: diff <file_a> <file_b>")
    return
end

local path_a = shell and shell.resolve(args[1]) or args[1]
local path_b = shell and shell.resolve(args[2]) or args[2]

if not fs.exists(path_a) then
    printError("diff: " .. args[1] .. ": No such file")
    return
end
if not fs.exists(path_b) then
    printError("diff: " .. args[2] .. ": No such file")
    return
end
if fs.isDir(path_a) or fs.isDir(path_b) then
    printError("diff: directory comparison is not supported")
    return
end

local function read_lines(path)
    local f = fs.open(path, "r")
    if not f then return nil, "cannot open " .. path end
    local lines = {}
    local raw_line = f.readLine()
    while raw_line ~= nil do
        table.insert(lines, raw_line)
        raw_line = f.readLine()
    end
    f.close()
    return lines
end

local lines_a, err_a = read_lines(path_a)
local lines_b, err_b = read_lines(path_b)
if not lines_a then
    printError("diff: " .. err_a); return
end
if not lines_b then
    printError("diff: " .. err_b); return
end

-- Compute the LCS (Longest Common Subsequence) table.
local n = #lines_a
local m = #lines_b

-- For large files the full dp table may be heavy; CC memory permits ~100KB Lua
-- state, so cap at a sane size and warn if exceeded.
local MAX_LINES = 200
if n > MAX_LINES or m > MAX_LINES then
    printError("diff: files are too large for in-memory diff (max " .. MAX_LINES .. " lines each)")
    return
end

local dp = {}
for i = 0, n do
    dp[i] = {}
    for j = 0, m do
        dp[i][j] = 0
    end
end

for i = 1, n do
    for j = 1, m do
        if lines_a[i] == lines_b[j] then
            dp[i][j] = dp[i - 1][j - 1] + 1
        else
            dp[i][j] = math.max(dp[i - 1][j], dp[i][j - 1])
        end
    end
end

-- Walk back through the dp table to produce the edit script.
local edits = {}
local i, j = n, m
while i > 0 or j > 0 do
    if i > 0 and j > 0 and lines_a[i] == lines_b[j] then
        table.insert(edits, 1, { op = "=", text = lines_a[i] })
        i = i - 1; j = j - 1
    elseif j > 0 and (i == 0 or dp[i][j - 1] >= dp[i - 1][j]) then
        table.insert(edits, 1, { op = "+", text = lines_b[j] })
        j = j - 1
    else
        table.insert(edits, 1, { op = "-", text = lines_a[i] })
        i = i - 1
    end
end

-- Display results.
local changed = false
for _, edit in ipairs(edits) do
    if edit.op == "+" then
        term.setTextColor(colors.lime)
        print("+" .. edit.text)
        changed = true
    elseif edit.op == "-" then
        term.setTextColor(colors.red)
        print("-" .. edit.text)
        changed = true
    else
        term.setTextColor(colors.gray)
        print(" " .. edit.text)
    end
end
term.setTextColor(colors.white)

if not changed then
    print("Files are identical.")
end
