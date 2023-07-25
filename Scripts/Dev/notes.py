#
# Python note processing application
#
#
#
#
import datetime


fileName = input("Please Enter the name of the file to append, case sensitive: ")
markdownFileName = fileName + ".md"
f = open(markdownFileName, "a+")
EOF = False
while EOF != True:
    line = input("Please enter the meeting name: ")
    if(line == "EOF" or line == "EXIT!"):
            EOF = True
            f.close()
            exit()
            #break
    f.write("\n# " + line + " #   \n\n")
    line = None
    EOM = False
    while (EOM != True or line != "EOM" ):
        time = datetime.datetime.now()
        speaker = input("[" + str(time) + "] Who is speaking: ")
        line = speaker
        #exit condition
        if(speaker == "EOF" or speaker == "EXIT!"):
            EOF = True
            f.close()
            exit()
            #break

        f.write("[" + str(time) + "]::*" + speaker + "*::   \n")
        while (line != "CHS" or line != "EXIT!"):
            line = None
            time = datetime.datetime.now()
            line = input("[" + str(time) + "]: ")
            if(line == "LST"):                                                      # LST   | Command to start list
                while (line != "ENDL"):                                             # ENDL  | Command to end List
                  line = input("List item: -")
                  if(line == "ENDL"):
                      break
                  f.write(" - " + line + "   \n")
            elif(line == "SBTP"):                                                   # SBTP  | command to have a subtopic
                line = input("Enter a subtopic with '#' for smaller topics: ")
                f.write("\n#" + line + "#   \n")  
            elif(line == "RAW"):                                                    # RAW   | command to enter raw input
                line = input("Enter Raw MD Line: ")
                f.write(line + "   \n")
            elif(line == "CODE"):                                                   # CODE  | command to enter code block
                lang = input("Enter file type: ")
                f.write("\n```" + lang + "   \n")
                while(line != "ENDC"):                                              # ENDC  | command to end code block
                    line = input(">")
                    if(line == "ENDC"):
                        break
                    f.write(line + "   \n")
                f.write("\n```   \n")
            else:                                                                   # Writing regular line
                f.write("[" + str(time) + "] - " + line + "   \n")
            
            # EOM exit condition for meeting
            # CHS exit condition for speaker
            if(line == "EOM" or line == "EOF" or line == "CHS" or line == "EXIT!"): # EOM | Command to end meeting, CHS | Command to change speaker, EOF/EXIT! | program save and exit
                #exit condition for file
                if(line == "EOF" or line == "EXIT!"):
                    EOF = True
                    f.close()
                    exit()
                # exit condition for meeting                    
                if(line == "EOM"):
                    EOM = True
                
                #exit condition for loop ( speaker )
                print("EOM/CHS/EXIT!/EOF Detected")
                break

f.close()
print(fileName + " has been written to")        