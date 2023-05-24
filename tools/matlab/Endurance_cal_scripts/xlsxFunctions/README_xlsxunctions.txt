
The functions in this xlsxFunctions folder ultimately came from numerous web searches; they all have in common use of actxserver, available only on Windows systems. There are several ways each of these functions could have been written; in fact, most were written in bunches, when needed, and code from each bunch will usually share a common architecture.

At the times most of this code was written, it was\is required that the input filename contain the full path.

Much of my Matlab code that writes to Excel files uses the old Matlab function xlswrite, which Mathworks no longer  recommends. However, the actions of xlswrite and writecell, one of the recommended replacements, work differently when Matlab writes Excel formulas into Excel cells; formulas written into Excel cells by xlswrite will be executed when the Excel file is opened, which is not true for those written with writecell.

R. Desiderio
Oregon State University