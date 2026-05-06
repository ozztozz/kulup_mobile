import re

pattern = r"^(\d+){1,8}(?=[\(A-ZÇĞİÖŞÜa-zçğışöü])"
text = '5Barış TAŞDEMİR 15 Ferdi NT'

result = re.match(pattern, text)

if result:
    print(f"Matched: '{result.group(0)}'")
else:
    print("No match found.")