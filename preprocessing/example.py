from PIL import Image
import sys

import pyocr
import pyocr.builders

tools = pyocr.get_available_tools()
if len(tools) == 0:
    print("No OCR tool found")
    sys.exit(1)

tool = tools[0]
print("Will use tool '%s'" % (tool.get_name()))

klingon_data = tool.image_to_string(
    #Image.open("Klingon_Dictionary/Klingon Dictionary-43.png"),
    Image.open("sample2-klingon.png"),
    lang="eng",
    builder=pyocr.builders.TextBuilder(tesseract_layout=6)
)
english_data = tool.image_to_string(
    #Image.open("Klingon_Dictionary/Klingon Dictionary-43.png"),
    Image.open("sample2-english.png"),
    lang="eng",
    builder=pyocr.builders.TextBuilder(tesseract_layout=6)
)
klingon_dataset =  klingon_data.split("\n")
english_dataset =  english_data.split("\n")
for k in klingon_dataset:
    if k == '':
        del klingon_dataset[klingon_dataset.index(k)]


del english_dataset[0]
del english_dataset[-1]
for index,e in enumerate(english_dataset):
    if e == '':
        del english_dataset[index]

for index,e in enumerate(english_dataset):
    english_dataset[index] = e.replace('}',')').replace('))',')')
    if english_dataset[index][-1] != ')':
        english_dataset[index] += english_dataset[index+1]
        del english_dataset[index+1]

for k,e in zip(klingon_dataset,english_dataset):
    print(k,e)
