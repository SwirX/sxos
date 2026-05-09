local jobs = shell.get_jobs and shell.get_jobs() or {}
print("PID\tSTATUS\t\tCMD")
if #jobs == 0 then
    print("No active background jobs.")
    return
end

for _, j in ipairs(jobs) do
    local state = coroutine.status(j.co)
    print(string.format("%d\t%s\t\t%s", j.pid, state, j.cmd))
end
