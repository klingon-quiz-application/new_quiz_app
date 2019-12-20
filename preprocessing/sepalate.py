import csv
file_name = "dataset.txt"
row_data = []
eng_data = []
klingon_data = []
with open(file_name,"r") as f:
    row_data = f.readlines()

for data in row_data:
    data = data.replace(", ","、")
    tmp_data = data[:data.index(" ")]
    klingon_data.append(data[:data.index(" ")])
    eng_data.append(data[data.index(" ")+1:])

with open("klingon_only.csv","w") as f:
    writer = csv.writer(f)
    for d,i in zip(klingon_data,range(len(klingon_data))):
        writer.writerow([str(i),d,str(i)])

with open("english_only.csv","w") as f:
    writer = csv.writer(f)
    for d,i in zip(eng_data,range(len(eng_data))):
        writer.writerow([str(i),d,str(i)])

with open("japanese.txt","r") as f:
    row_data = f.readlines()

with open("japanese_only.csv","w") as f:
    writer = csv.writer(f)
    for d,i in zip(row_data,range(len(row_data))):
        writer.writerow([str(i),d,str(i)])
