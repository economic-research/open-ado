## Install ado files that we've found to be useful

Simply run
`do ados_to_install.do`

## Use user written functionality

Clone this repository into your `ado/` folder and remember to `pull` changes frequently.
You can find the location of your `ado/personal` folder by typing `sysdir`

## Read our Wiki
Seriously, we spent a lot of time coming with all those handy tricks

## Contributions are welcome
Our base of ado files will improve the more people contribute to it. Please do contribute as follows:

## Commit
1. Create a separate branch with a descriptive name, e.g., `feature-count-missing`. *Do not commit to master*.
2. `push` your changes into that branch
3. Make a `pull` request to master

## Directory of ados
- _graph2_ exports a graph to PNG and PDF and optionally passes project functionality
- _init_ starts a STATA dofile with commonly used options
- _merge2_ merges to a CSV file, optionally passes project functionality
- _missing2zero_ replaces missing values for a user specified value for a given list of variables
- _psave_ saves to CSV and DTA and registers with project
- _puse_ reads a DTA and, if it doesn't exist, tries to find a matching CSV file to read
- _uniquevals_ counts the number of unique values for a list of variables
