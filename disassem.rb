# get argument from command (default compile chois is -O1 if is not specified)
fileName = ARGV[0]
compileChoice = ARGV[1]
if compileChoice == nil
    compileChoice = "-O1"
end
cFileName = fileName+".c"
`gcc -g3 #{compileChoice} -o #{fileName} #{cFileName}`
llvm = `llvm-dwarfdump --debug-line #{fileName}` # string
objdump = `/usr/bin/objdump -d #{fileName}` # string
llvmSplit = llvm.split("------------------ ------ ------ ------ --- ------------- -------------")
llvmRemove = llvmSplit.last

puts llvmRemove
# address from llvm dwarfdump
addressArray = Array.new()
# array stores the top address in right side
topAddressHash = Hash.new()
# all address in right side (right button)
finalAddressArray = Array.new()
# stores all 0s that is removed
addSub = ""

# Line -> Address
# Address -> Line
line2address = Hash.new()
address2line = Hash.new()
llvmArray = llvmRemove.split("0x") # array

# add the line <-> address mapping from llvm debug file
$i = 1
$arrLength = llvmArray.length
begin
    temp = llvmArray[$i].split(" ")
    line = temp[1]
    address = temp[0]
    temp1 = address.dup
    address = address.sub!(/([0]*)/, "")
    addSub = temp1.sub(address, "")
    addressArray.append(address)
    # if already exist -> append to array
    # else: new to hash -> add array
    # line2address
    if(line2address.key?(line))
        temp = line2address[line].append(address)
        temp = temp.uniq
        line2address[line] = temp
    else
        line2address[line] = Array[address]
    end
    # address2line
    if(address2line.key?(address))
        temp = address2line[address].append(line)
        temp = temp.uniq
        address2line[address] = temp
    else
        address2line[address] = Array[line]
    end
    $i +=1
end while $i < $arrLength

# Source Code: Left Side --------------------------------------------------------------
# Line -> Source code (mapping from line to c source code)
line2source = Hash.new()
fullFileName = fileName+".c"
$index = 1
File.open(fullFileName).each do |sourceC|
    line2source[$index] = sourceC
    $index+=1
end

# PART2: CLICK FROM THE RIGHT SIDE ----------------------------------------------------------------
# 2.1 Address -> Line
# 2.2 Address -> Assembly code

# remove unnecessory code in objdump, clean up
address2assemb = Hash.new()
objdumpSplit = objdump.split(">:")
remainObjdump = Array.new()

$j = 0
$jLength = objdumpSplit.length-1
begin
    temp = objdumpSplit[$j].split(" ")
    topAddress = temp[-2]
    temp2 = topAddress.sub!(/([0]*)/, "")
    if(addressArray.include?(topAddress))
        fullStr = addSub+temp[-2] + " " + temp[-1] + ">:"
        topAddressHash[temp[-2]] = fullStr
        remainObjdump.append(objdumpSplit[$j+1])
    end
    $j +=1
end while $j < $jLength

# for each block, add to hashmap
remainObjdump.each do |obj|
    obj.each_line do |li|
        tempArr = li.split(" ")
        if(tempArr[0] =~ /([0-9a-f]{6}):/)
            tempArr[0].sub!(/:/, "")
            finalAddressArray.append(tempArr[0])
            li = li.sub!(/([0-9a-f]{6}):/, "")
            address2assemb[tempArr[0]] = li
        end
    end
end

# sort all address in order
finalAddressArray.each do |add|
    add.to_i(16)
end
finalAddressArray.sort

# add missing address <-> line mapping from objdump file
$x = 1
$finalLength = finalAddressArray.length
begin
  # if address2line includes current address -> do nothing
  # if not include -> address2line[currentAddress] = address2line[previous address in final address]
  currentAdd = finalAddressArray[$x]
  prevAdd = finalAddressArray[$x-1]
  if(address2line.key?(currentAdd) == false)
      arr = address2line[prevAdd]
      arrLast = arr.last(1)
      tempLine = arrLast[0].to_s
      address2line[currentAdd] = arrLast
      line2address[tempLine] = line2address[tempLine].append(currentAdd)
  end
  $x += 1
end while $x < $finalLength


# # PART3: HTML -----------------------------------------------------------------------------------
# # make sure '<' and '>' is properly represented in html
# def lineContentValidate(string_line)
#   string_line = string_line.gsub("<", "&lt;")
#   string_line = string_line.gsub(">", "&gt;")
#   return string_line
# end
# #use for insert space on the button
# longestLength = line2source.size().to_s

# #use for insert space on the button
# def addSpaceToKey(key, longestLength)

#   r_string=key
#   keyLength = key.length
#   space = "&nbsp;"

#   while keyLength < longestLength.length
#     r_string = space + r_string
#     keyLength = keyLength + 1
#   end

#   return r_string
# end

# # return all source code section html:  
# def source_code(line2Source, line2address, longestLength)
#   result_string = ""
#   sclick = ""
#   aline = ""

# line2Source.each do |key, value|
#     #for lines that link to assem address, attach the event listener.
#     if line2address.key?(key.to_s)
#         sclick = "onclick=\"sclick('s#{key}', 'a#{line2address[key.to_s][0]}')\""
#         aline = "a"+line2address[key.to_s].join(" a")   
#     end
#     #append the button and span string using ascii.html provided
#     result_string = result_string +  "<button #{sclick}>#{addSpaceToKey(key.to_s, longestLength)}</button> <span id=\"s#{key}\" aline=\"#{aline}\" >#{lineContentValidate(value).chomp}</span> 
# "
#   end
#   return result_string
# end

# # return all assem code section html:  
# def assem_code(address2assemb, address2line,topAddressHash )
#   result_string = ""
#   sline= ""
#   address2assemb.each do |key, value|
#     #if address is the start of a assem code block in objdump file, append the address the block name in html
#     if topAddressHash.has_key?(key.to_s)
#       result_string = result_string + "\n"+lineContentValidate(topAddressHash[key.to_s]) +"\n\n"
#     end
#     #append the button and span string using ascii.html provided
#   result_string = result_string + "<button onclick=\"aclick('a#{key.to_s}','s#{address2line[key.to_s][0]}')\" >#{key.to_s}</button> <span id=\"a#{key.to_s}\"   sline=\"s#{address2line[key].join(" s")}\">#{lineContentValidate(value).chomp}</span>
# "
#   end
#   return result_string
# end


# #Construct and output html file, mostly reference to the ascii.html file format.  
# File.open("#{fileName}_disassem.html", "w") do |file|
#   # Write the HTML content to the file
  
#   file.puts "
#   <!DOCTYPE html>
#   <html lang=\"en\">
#   <head>
#   <meta charset=\"UTF-8\">
#   <title>#{lineContentValidate(fileName)} disassem</title>
# </head>
#   <!--
#       This is a sample of the sort of output your tool should produce.
#       It has been created (by hand) for the ascii.c test program.
  
#       (c) Michael L. Scott, 2022.
#       For use by students in CSC 2/454 at the University of Rochester,
#       during the Fall 2022 term.  All other use requires written permission
#       of the author.
#   -->
#   <style>
#   button {
#       border: none;
#       margin: none;
#       font-family: \"Courier New\", \"Courier\", \"monospace\";
#       background-color: Azure;
#   }
#   button[onclick] {
#       background-color: LightCyan;
#   }
#   button[onclick]:hover {
#       background-color: PaleGreen;
#   }
#   #assembly {
#       height: 88vh;
#       overflow: auto;
#       font-family: \"Courier New\", \"Courier\", \"monospace\";
#       font-size: 80%;
#       white-space: pre
#   }
#   #source {
#       height: 88vh;
#       overflow: auto;
#       font-family: \"Courier New\", \"Courier\", \"monospace\";
#       font-size: 80%;
#       white-space: pre
#   }
#   table {
#       border-spacing: 0px;
#   }
#   td {
#       padding: 0px;
#       padding-right: 15px;
#   }
#   </style>
  
#   <body>
#   <script>
#   // scroll line into the middle of its respective subwindow
#   function reveal(line) {
#     const element = document.getElementById(line);
#      element.scrollIntoView({
#        behavior: 'auto',
#        block: 'center',
#        inline: 'center'
#      });
#   }
#   // green-highlight aline,
#   // yellow-highlight all source lines that contributed to aline,
#   // and scroll sline into view
#   function aclick(aline, sline) {
#     const sLines = document.querySelectorAll(\"span[aline]\");  // slines have an aline list
#     const aLines = document.querySelectorAll(\"span[sline]\");  // alines have an sline list
#     // clear all assembly lines
#     aLines.forEach((l) => {
#       l.style.backgroundColor = 'white';
#     })
#     sLines.forEach((sl) => {
#       if (sl.matches(\"span[aline~=\"+aline+\"]\")) {
#           sl.style.backgroundColor = 'yellow';
#           aLines.forEach((al) => {
#             if (al.matches(\"span[sline~=\"+sl.id+\"]\")) {
#               al.style.backgroundColor = 'PapayaWhip';
#             }
#           })
#       } else {
#           sl.style.backgroundColor = 'white';
#       }
#     })
#     const l = document.getElementById(aline);
#     l.style.backgroundColor = 'PaleGreen';
#     reveal(sline);
#   }
#   // green-highlight sline,
#   // yellow-highlight all assembly lines that correspond to sline,
#   // and scroll aline into view
#   function sclick(sline, aline) {
#     const aLines = document.querySelectorAll(\"span[sline]\");  // alines have an sline list
#     const sLines = document.querySelectorAll(\"span[aline]\");  // slines have an aline list
#     // clear all source lines
#     sLines.forEach((l) => {
#       l.style.backgroundColor = 'white';
#     })
#     aLines.forEach((l) => {
#       if (l.matches(\"span[sline~=\"+sline+\"]\")) {
#           l.style.backgroundColor = 'yellow';
#       } else {
#           l.style.backgroundColor = 'white';
#       }
#     })
#     const l = document.getElementById(sline);
#     l.style.backgroundColor = 'PaleGreen';
#     reveal(aline);
#   }
#   </script>
#   <h1>#{lineContentValidate(fileName)}</h1>

# <table width=\"100%\">
# <tr>
# <td width=\"49%\">
# <h2>source</h2>

# <div id=\"source\">
# #{source_code(line2source, line2address,longestLength)}

# </div>
# </td>

# <td width=\"49%\">
# <h2>assembly</h2>
# <div id=\"assembly\">
# #{assem_code(address2assemb, address2line,topAddressHash)}
# </div>
# </td>
# </tr>
# </table>

# </body>
# </html>"
# end

