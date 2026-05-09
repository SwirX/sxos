-- /lib/fs/path.lua
-- Standard path manipulation utilities for SXOS.
-- Provides POSIX-style path operations on top of CraftOS's fs module.

local path = {}

-- Normalize a path by resolving . and .. components, collapsing multiple
-- slashes, and ensuring it is absolute.
function path.normalize(raw_path)
    -- Treat empty path as root.
    if not raw_path or raw_path == "" then return "/" end

    local parts = {}
    -- Preserve leading slash to detect absolute paths.
    local is_absolute = string.sub(raw_path, 1, 1) == "/"

    for segment in string.gmatch(raw_path, "[^/]+") do
        if segment == ".." then
            if #parts > 0 then
                table.remove(parts)
            end
        elseif segment ~= "." then
            table.insert(parts, segment)
        end
    end

    local result = table.concat(parts, "/")
    if is_absolute then
        return "/" .. result
    end
    return result == "" and "." or result
end

-- Join path segments together and normalize the result.
function path.join(...)
    local segments = { ... }
    return path.normalize(table.concat(segments, "/"))
end

-- Return the parent directory of a path.
function path.dirname(raw_path)
    local normalized = path.normalize(raw_path)
    local last_slash = 0
    for i = #normalized, 1, -1 do
        if string.sub(normalized, i, i) == "/" then
            last_slash = i
            break
        end
    end
    if last_slash <= 1 then return "/" end
    return string.sub(normalized, 1, last_slash - 1)
end

-- Return the filename component of a path (everything after the last slash).
function path.basename(raw_path)
    local normalized = path.normalize(raw_path)
    for i = #normalized, 1, -1 do
        if string.sub(normalized, i, i) == "/" then
            return string.sub(normalized, i + 1)
        end
    end
    return normalized
end

-- Return the file extension (without the dot), or an empty string if none.
function path.extension(raw_path)
    local base = path.basename(raw_path)
    local dot = string.find(base, "%.[^%.]+$")
    if dot then
        return string.sub(base, dot + 1)
    end
    return ""
end

-- Return the filename without its extension.
function path.stem(raw_path)
    local base = path.basename(raw_path)
    local dot = string.find(base, "%.[^%.]+$")
    if dot then
        return string.sub(base, 1, dot - 1)
    end
    return base
end

-- Split a path into directory and filename parts.
function path.split(raw_path)
    return path.dirname(raw_path), path.basename(raw_path)
end

-- Resolve a potentially relative path against a base directory.
function path.resolve(base_dir, target)
    if string.sub(target, 1, 1) == "/" then
        return path.normalize(target)
    end
    return path.normalize(base_dir .. "/" .. target)
end

-- Check whether a string looks like an absolute path.
function path.is_absolute(raw_path)
    return type(raw_path) == "string" and string.sub(raw_path, 1, 1) == "/"
end

return path
