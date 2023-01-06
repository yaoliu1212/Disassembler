How to run:
- ruby disassem.rb argument1 argument2
- argument1: c file without ".c"
- argument2: compile option, such as -O3 (if left empty, then it will be -O1 on default)
- example command: ruby disassem.rb ascii -O3

Files:
- disassem.rb
  main file that compile the C code, uses the output of llvm-dwarfdump --debug-line and objdump -d, and generate corresponding html file named filename_disassem.html
- README
- C code file

Part 1: processing data
We first got the result of llvm-dwarfdump and objdump, storing in strings. We built four hashes to help the left/right and button/line mapping. 
We also had a hash to store all topAddressArray on the right side, and finalAddressArray that stores all adress on the right side.
With the string stores llvm result, we clean all informationm above the address, loop the remaining addresses and corresponding line numbers, and store the correspondance into address2line and line2address hashes.
We also stores every addresses from llvm into addressArray.

Then, we clean up the objdump and remove the whole section if the top address is included in addressArray. For the remaining sections, we added the addresses into finalAddressArray. 
After removing duplicate elements from the finalAddressArray and sorting, the finalAddressArray is completed.

We looped the finalAddressArray from the top and compared each address with the key in address2line.
If address2line does not include finalAddressArray, it indicates the current address is added from objdump file. The corresponding line for this address should be the same with the previous address. 
We then added successfully the missing mapping for address2line and line2address.

Part 2: construct website

We reference on the example file ascii.html for building our UIs. For the html file, we use Ruby to write a html file where the content is
interpolated. The interpolated contents are:
Buttons and spans for line to source code and address to assembly code sections. 
The name, title, and heading for the html file.

For line to source code, we loop through line2sources and line2address to write corresponding button and span, if a line matches to address then we will attach 'onclick' eventlistner on the button.
For address to assembly, we loop through address2assemb and address2line  to write corresponding button span, if a address indicate a start of assemble code block then we will attach its address and block tag on the html.
For all content values, we passed them to a validate function to make sure '<' and '>' can be writed in html.  

