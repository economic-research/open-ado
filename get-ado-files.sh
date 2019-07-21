## This scripts exports all ado files into a dofile called program-list.do
## This is useful when you want to use open-ado functionality, but you can't install
## ado files because of insufficient permissions.

# Simply run in STATA: "do program-list.do"
(rm program-list.do) || (echo "program-list.do does not exist")

# Loop over ado files in directory
for f in *.ado;
	do cat "$f" >> program-list.do;
done
