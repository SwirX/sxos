local e = _ENV.ENV
if e then
    for k, v in pairs(e) do print(k .. "=" .. v) end
else
    printError("env: Environment space unavailable")
end
