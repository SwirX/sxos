-- /lib/sh/tokenizer.lua
-- Lexical analysis for the SXOS shell (bsh).
-- Converts a raw input string into a flat list of typed tokens.
--
-- Token types produced:
--   WORD         - a bare word or quoted string (their content after unquoting)
--   PIPE         - the | operator
--   REDIR_OUT    - the > operator (stdout redirect, truncate)
--   REDIR_APPEND - the >> operator (stdout redirect, append)
--   REDIR_IN     - the < operator (stdin redirect)
--   SEMICOLON    - the ; command separator
--   AMPERSAND    - the & background execution marker
--   NEWLINE      - end of logical line (treated as SEMICOLON in the parser)
--   EOF          - end of input

local tokenizer = {}

local TOKEN = {
    WORD         = "WORD",
    PIPE         = "PIPE",
    REDIR_OUT    = "REDIR_OUT",
    REDIR_APPEND = "REDIR_APPEND",
    REDIR_IN     = "REDIR_IN",
    SEMICOLON    = "SEMICOLON",
    AMPERSAND    = "AMPERSAND",
    NEWLINE      = "NEWLINE",
    EOF          = "EOF",
}
tokenizer.TOKEN = TOKEN

-- Tokenize a single line of shell input.
-- Returns a list of { type, value } tables, always ending with an EOF token.
function tokenizer.tokenize(input)
    local tokens = {}
    local index = 1
    local length = #input

    local function peek()
        return index <= length and string.sub(input, index, index) or nil
    end

    local function consume()
        local ch = string.sub(input, index, index)
        index = index + 1
        return ch
    end

    local function emit(token_type, value)
        table.insert(tokens, { type = token_type, value = value })
    end

    while index <= length do
        local ch = peek()

        -- Skip whitespace between tokens.
        if ch == " " or ch == "\t" then
            consume()

            -- Double-quoted string: preserves spaces and applies variable expand later.
        elseif ch == '"' then
            consume() -- opening quote
            local word = ""
            while index <= length do
                local inner = consume()
                if inner == '"' then break end
                if inner == "\\" and index <= length then
                    -- Escape sequences inside double quotes.
                    local escaped = consume()
                    if escaped == "n" then
                        word = word .. "\n"
                    elseif escaped == "t" then
                        word = word .. "\t"
                    else
                        word = word .. escaped
                    end
                else
                    word = word .. inner
                end
            end
            emit(TOKEN.WORD, word)

            -- Single-quoted string: completely literal, no expansion.
        elseif ch == "'" then
            consume()
            local word = ""
            while index <= length do
                local inner = consume()
                if inner == "'" then break end
                word = word .. inner
            end
            emit(TOKEN.WORD, word)

            -- Backslash: escape the next character outside of quotes.
        elseif ch == "\\" then
            consume()
            if index <= length then
                emit(TOKEN.WORD, consume())
            end

            -- Pipe operator.
        elseif ch == "|" then
            consume()
            emit(TOKEN.PIPE, "|")

            -- Background or logical AND (simplified: just & for now).
        elseif ch == "&" then
            consume()
            emit(TOKEN.AMPERSAND, "&")

            -- Semicolon command separator.
        elseif ch == ";" then
            consume()
            emit(TOKEN.SEMICOLON, ";")

            -- Redirect operators: >> or > or <
        elseif ch == ">" then
            consume()
            if peek() == ">" then
                consume()
                emit(TOKEN.REDIR_APPEND, ">>")
            else
                emit(TOKEN.REDIR_OUT, ">")
            end
        elseif ch == "<" then
            consume()
            emit(TOKEN.REDIR_IN, "<")

            -- Comments: # to end of line.
        elseif ch == "#" then
            break

            -- Bare word: read until a delimiter character.
        else
            local word = ""
            while index <= length do
                local next_ch = peek()
                if next_ch == " " or next_ch == "\t"
                    or next_ch == "|" or next_ch == "&"
                    or next_ch == ";" or next_ch == ">"
                    or next_ch == "<" or next_ch == '"'
                    or next_ch == "'" or next_ch == "#"
                then
                    break
                end
                word = word .. consume()
            end
            emit(TOKEN.WORD, word)
        end
    end

    emit(TOKEN.EOF, nil)
    return tokens
end

return tokenizer
