local args = { ... }
if args[1] == "clone" then
    printError("git clone is not fully implemented in this minimal env. Use wget.")
else
    print("SXOS Git Wrapper")
    print("Commands:")
    print("  clone <repo> (Stubbed)")
end
