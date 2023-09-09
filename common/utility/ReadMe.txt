Parameters:
"f",   "Folder",         "A folder to search",                                   Folders list retrieved from the registry if not defined
"a",   "Algorithm",      "The hash algorithm to use (CRC32/HMACSHA1)"            Default = HMACSHA1
"r",   "Recurse",        "Recurse subfolders"                                    Default = false
"h",   "Header",         "Include header in output file"                         Default = false
"q",   "Quiet",          "Suppress console output (except errors)",              Default = false
"p",   "Search Pattern", "Overrides the default search pattern if provided",     Default = *.exe|*.dll|*.bin
"v",   "View",           "View the generated file in the default text editor",   Default = false
"o",   "Output File",    "Output file path",                                     Default = .\m1vcout.csv


Examples:
Search installed program folders and sub folders for exe. dll and bin files 
m1vc /r

Search specified folders and subfolders for exe files and supress console output.
m1vc /f c:\temp /f "c:\another folder" /r /q /p |*.exe"