file_name = "klingon_english.txt"
row_data = ""
with open(file_name,"r") as f:
    row_data = f.read()
data = row_data.replace(") ",")\n")
print(data)
with open("_dataset.txt","w") as f:
    f.write(data)
