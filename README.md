## Install ado files that we've found to be useful

Simply run
`do ados_to_install.do`

## Use user written functionality

Clone this repository into your `ado/` folder and remember to `pull` changes frequently.
You can find the location of your `ado/personal` folder by typing `sysdir`. You can make your workflow easier and more efficient by copy-pasting `profile.do` in the directory where STATA is installed and modifying the parameters in that dofile so that every time STATA starts it `discard` old version of the `ado` files from memory and points to your appropriate `personal` ado file directory.

## Read our Wiki
Seriously, we spent a lot of time coming with all those handy tricks

## Contributions are welcome
Our base of ado files will improve the more people contribute to it. There are two ways to contribute:

### Ask to join the repository as editor
1. Send an email to jose_jurado_vadillo@brown.edu asking to join the repository as editor. Please provide your GitHub email and username.
2. Create a separate branch with a descriptive name, e.g., `feature-count-missing`. *You will not be able to commit to master*.
3. `push` your changes into that branch
4. Make a `pull` request to master

### Forking the repository
1. `fork` the repository into your account.
2. `clone`
3. Introduce your changes and `commit`
4. `push` to your `fork`
5. Send a `pull` request

(for more info watch [this](https://www.youtube.com/watch?v=G9yBPk4SltE))

## Directory of ados
- **date2string** generates a new date variable in string format
- **esttab2** wrapper for esttab with commonly used options and project functionality
- **graph2** exports a graph to PNG and PDF and optionally passes project functionality
- **init** starts a STATA dofile with commonly used options
- **merge2** merges to a CSV file, optionally passes project functionality
- **mcompare** multi compares a list of variables to a base variable
- **missing2zero** replaces missing values for a user specified value for a given list of variables
- **polgenerate** generates polynomials out of a varlist and labels them
- **psave** saves to CSV and DTA and registers with project
- **puse** reads a DTA and, if it doesn't exist, tries to find a matching CSV file to read
- **sumby** produces summary statistics for a list of variables according to the categories of a specified variable
- **twowayscatter** plots one or two-way scatters and saves the results 
- **uniquevals** counts the number of unique values for a list of variables
- **values2ascii** converts some UTF-8 into ASCII
