print("; Block ROM, created 04-Jun-2021")
print("MEMORY_INITIALIZATION_RADIX=16;")
print("MEMORY_INITIALIZATION_VECTOR=")
for x in range (0, 10000):
    print('%04d,' % x)
print("")
