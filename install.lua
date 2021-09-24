args = {...}
name = args[1]..".lua"

print("Installing: "..name)

shell.run("delete "..name)
shell.run("wget http://192.168.0.39:8000/"..textutils.urlEncode(name))
