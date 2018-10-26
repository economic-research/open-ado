## Install ado files that we've found to be useful

Simply run
`do ados_to_install.do`

## Use user written functionality

Clone this repository into your `ado/` folder and remember to `pull` changes frequently.
You can find the location of your `ado/personal` folder by typing `sysdir`. You can make your workflow easier and more efficient by copy-pasting `profile.do` in the directory where STATA is installed and modifying the parameters in that dofile so that every time STATA starts it `discard` old version of the `ado` files from memory and points to your appropriate `personal` ado file directory.

## Read our Wiki
Seriously, we spent a lot of time coming with all those handy tricks

## Contributions are welcome
Our base of ado files will improve the more people contribute to it. Please do contribute as follows:

## Commit
1. Create a separate branch with a descriptive name, e.g., `feature-count-missing`. *Do not commit to master*.
2. `push` your changes into that branch
3. Make a `pull` request to master

## Directory of ados
- **graph2** exports a graph to PNG and PDF and optionally passes project functionality
- **init** starts a STATA dofile with commonly used options
- **merge2** merges to a CSV file, optionally passes project functionality
- **missing2zero** replaces missing values for a user specified value for a given list of variables
- **psave** saves to CSV and DTA and registers with project
- **puse** reads a DTA and, if it doesn't exist, tries to find a matching CSV file to read
- **twowayscatter** plots one or two-way scatters and saves the results 
- **uniquevals** counts the number of unique values for a list of variables
