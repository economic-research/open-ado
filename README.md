## Why we created this repo
Three reasons:

1. Share useful ado files
2. Give a down-to-earth, practical how-to on git. As we worked with more people (some of whom weren't already using git), providing material and going over aspects of git became burdersome. So we created a unified repository with a _lot_ of material on git!
3. Implement `project` functionality (`project` is an ado file that you can install with `ssc install project`. This is covered in our Wiki, but the general idea is that it allows you to use relatives paths, detect bugs in your code more easily and avoid compiling dofiles when there's no need to). 

We realized that while `project` is extremely useful, using it forced us to write a bunch of extra code and modify it on the fly if we wanted to compile a single dofile, as oppossed as an entire project. Thus, we wrote a bunch of dofiles that make using `project` as painless as possible. Instead of using `clear` you can use our functionality `init`, as oppossed to `save filename` you use `psave , file(filename)`, etc. That's it! This might seem a bit esoteric at first, so we encourage you to read the rest of the documentation and check our examples.

## Install ado files that we've found to be useful

Simply run
`do ados_to_install.do`

## How to use our repository and codes

Some of our codes can be installed directly from STATA's SSC. To install the part of our codes that deal with `project` functionality simply run `ssc install pmanage`.

If you want to have the most up to date version of our codes, clone this repository into your `ado/` folder and remember to `pull` changes frequently. You can find the location of your `ado/personal` folder by typing `sysdir`. You can make your workflow easier and more efficient by copy-pasting `profile.do` in the directory where STATA is installed and modifying the parameters in that dofile so that every time STATA starts it `discard` old version of the `ado` files from memory and points to your appropriate `personal` ado file directory.

## Read our Wiki
Seriously, we spent a lot of time coming with all those handy tricks

## Check out our examples
We have written basic examples under `./examples/` that illustrate what you can do with `project` and the functionality that we support.

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
- **eventin** constructs a binary variable that identifies overlapping periods when using event studies
- **evstudy** utility to perform event study analysis
- **graph2** exports a graph to PNG and PDF and optionally passes project functionality
- **init** starts a STATA dofile with commonly used options (`ssc install pmanage`)
- **isorder** tells user if one or more variables describe order of dataset
- **merge2** merges to a CSV file, optionally passes project functionality
- **mcompare** multi compares a list of variables to a base variable
- **missing2zero** replaces missing values for a user specified value for a given list of variables
- **pdo** executes dofiles using project functionality
- **pexit** closes open log files, generates summary stats for verification purposes and stops dofile (`ssc install pmanage`)
- **polgenerate** generates polynomials out of a varlist and labels them
- **psave** saves to CSV and DTA and registers with project (`ssc install pmanage`)
- **puse** reads a DTA's, CSV and Excel files, and register dependencies using project functionality (`ssc install pmanage`)
- **sumby** produces summary statistics for a list of variables according to the categories of a specified variable
- **tsperiods** divides a panel dataset into equisized groups, with zero denoting the date of an event
- **twowayscatter** plots one or two-way scatters and saves the results 
- **uniquevals** counts the number of unique values for a list of variables
- **usstates** given a variable containing the name of US states, return abbreviations (and viceversa)
- **values2ascii** converts some UTF-8 into ASCII
