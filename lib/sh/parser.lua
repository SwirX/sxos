-- /lib/sh/parser.lua
-- Shell parser for bsh: converts a token stream into a command AST.
--
-- Grammar (simplified):
--   pipeline    ::= command (PIPE command)*
--   command     ::= WORD* redirect*
--   redirect    ::= (REDIR_OUT | REDIR_APPEND | REDIR_IN) WORD
--   sequence    ::= pipeline (SEMICOLON pipeline)*
--   statement   ::= sequence [AMPERSAND]
--
-- AST node types:
--   { type = "command",  args = [...], redirs = [...] }
--   { type = "pipeline", commands = [...] }
--   { type = "sequence", statements = [...], background = bool }

local parser = {}

local tokenizer_module = dofile("/lib/sh/tokenizer.lua")
local TOKEN = tokenizer_module.TOKEN

-- Parse a token list into an AST.
-- tokens: result from tokenizer.tokenize()
-- Returns the root AST node or nil + error string.
function parser.parse(tokens)
    local index = 1

    local function peek()
        return tokens[index]
    end

    local function consume()
        local tok = tokens[index]
        index = index + 1
        return tok
    end

    local function expect(token_type)
        local tok = consume()
        if tok.type ~= token_type then
            return nil, "expected " .. token_type .. " got " .. tok.type
        end
        return tok
    end

    -- Parse a single command: collect WORD args and redirect specs.
    local function parse_command()
        local args = {}
        local redirs = {}

        while true do
            local tok = peek()
            if not tok or tok.type == TOKEN.EOF
                or tok.type == TOKEN.PIPE
                or tok.type == TOKEN.SEMICOLON
                or tok.type == TOKEN.AMPERSAND
            then
                break
            end

            if tok.type == TOKEN.REDIR_OUT
                or tok.type == TOKEN.REDIR_APPEND
                or tok.type == TOKEN.REDIR_IN
            then
                local redir_type = consume().type
                local target = consume()
                if not target or target.type ~= TOKEN.WORD then
                    return nil, "expected filename after redirect operator"
                end
                table.insert(redirs, { direction = redir_type, target = target.value })
            elseif tok.type == TOKEN.WORD then
                table.insert(args, consume().value)
            else
                consume() -- skip unexpected token
            end
        end

        if #args == 0 and #redirs == 0 then return nil end
        return { type = "command", args = args, redirs = redirs }
    end

    -- Parse a pipeline: one or more commands joined by PIPE.
    local function parse_pipeline()
        local commands = {}
        local first = parse_command()
        if not first then return nil end
        table.insert(commands, first)

        while peek() and peek().type == TOKEN.PIPE do
            consume() -- consume |
            local next_cmd = parse_command()
            if not next_cmd then
                return nil, "expected command after pipe"
            end
            table.insert(commands, next_cmd)
        end

        if #commands == 1 then return commands[1] end
        return { type = "pipeline", commands = commands }
    end

    -- Parse a sequence of pipelines separated by semicolons.
    local statements = {}
    local background = false

    while peek() and peek().type ~= TOKEN.EOF do
        -- Skip leading semicolons.
        if peek().type == TOKEN.SEMICOLON then
            consume()
        elseif peek().type == TOKEN.AMPERSAND then
            consume()
            background = true
        else
            local statement, err = parse_pipeline()
            if err then return nil, err end
            if statement then
                table.insert(statements, statement)
            end
        end
    end

    if #statements == 0 then return nil end
    if #statements == 1 and not background then return statements[1] end
    return { type = "sequence", statements = statements, background = background }
end

return parser
