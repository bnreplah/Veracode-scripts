# import veracode_api_py
# from veracode_api_py import apihelper
import json

VDEBUG = True


# next holds the next node in the list
# previous holds the previous node in the list
# if direct is false, then dependsOn holds an array of the next level on Nodes similar to a BTree should hold a value of the next top level node
#     N1 ----- N2 ----- N3
#     |_N4              |_N5
#        |_N6---N7
class Node:
    def __init__(self, obj = None, previous = None, nxt = None,direct = True, top = None, depends = [], head = False):
        self.prev = previous
        self.next = nxt
        self.top = top
        self.dependsOn = depends
        self.direct = direct # same as leaf
        self.data = obj
        self.DEBUG = True
        self.isHead = head

    # Setter Functions

    def setDirect(self, direct):
        self.direct = direct

    def setPrev(self, prv):
        self.prev = prv
    
    def setNext(self, nxt):
        self.next = nxt

    def setTop(self, tp):
        self.top = tp

    def setData(self, dat):
        self.data = dat

    # Depends list functions

    def addDepend(self, module):
        self.dependsOn.append(module)
    
    def popDepend(self):
        self.dependsOn.pop()

    def getDepend(self):
        return self.dependsOn
    # Getter Functions

    def getDirect(self):
        return self.direct
    
    # Directional Functions

    def getTop(self):
        if(self.direct):
            return self
        return self.top
    
    def getNext(self):
        return self.next
    
    def getPrev(self):
        return self.prev
    
    def getData(self):
        return self.data

    def getHead(self):
        return self.isHead

    def print(self):
        output = " "
        if(self.direct):
            output += "----" + self.data + "----"
        else:
            output += "|_|----" + self.data + "-----"
        return output
        
        
# class Tree: 
#     def __init__(self, head = Node):
#         self.head = head
        
#         self.next = None


######################
## Sandbox testing ::
######################
dependency = []
components = []
#dependencyTree = Tree()
start = None
currentNode = Node()
nextNode = None
previousNode = Node()
previousNode.isHead = True
previousNode.setData(None)
#dependencyTree.head
previousNode.setNext(currentNode)
currentNode.setPrev(previousNode)
start = previousNode

file_name = 'sbom.json'
with open(file_name, 'r', encoding='utf-8') as f:
    data = json.load(f, strict=False)
    # print(data["components"])
    nextNode = Node()
    for comp in data["components"]:
        currentNode.setData(comp)
        currentNode.setDirect(True)
        currentNode.setNext(nextNode)
        nextNode.setPrev(currentNode)
        components.append(currentNode)
        
        #previousNode = currentNode
        previousNode = currentNode
        currentNode = nextNode
        nextNode = None
        nextNode = Node()

        #components.append(comp)
        if( VDEBUG ):
            print("Components: ")
            print(comp)
            print("Nodes: ")
            print(previousNode.getData()['bom-ref'])
            print(currentNode.getData())
            print(nextNode.getData())

    print(len(components))
    for element in components:
        print(element.getData()['bom-ref'])


    # print("----------------")
    # print(components[0])
    # print("----------------")
    # for i in components:
    #     print( "\n")
    #     print(i)
    #     print(i["bom-ref"])
    #     if "group" in i.keys():
    #         print(i["group"])

    print("========================================================= DEPENDENCIES ================================================================")
    for dep in data["dependencies"]:
        if "dependsOn" in dep.keys():
            print("-------------------------------------")

            for elements in components:
                if (elements.getData()['bom-ref'] == dep['ref'] ):
                    print("found match")
                    
                    for value in dep["dependsOn"]:
                        print(value)
                        elements.addDepend(value)
                        print("Depend on Added to ")
                        print( elements.getData())
                        print(elements.getDepend())
                        if (elements.getData()['bom-ref'] == dep['dependsOn']):
                            print("Self match")
                elif (elements.getData()['bom-ref'] == dep["dependsOn"]):
                    print("dependency found")
            print(dep["ref"] + " depends on ")
            print("\t")
            print("=====")
            print(dep["dependsOn"])
            print("-------------------------------------")
    
    currentNode = start
    nextNode = currentNode.getNext()
    while ((currentNode != None)):
        print("=========================================================================")
        print("Is Head Node:")
        print(currentNode.getHead())
        print("Node Data: ")
        print(currentNode.getData())
        if(currentNode.getData() != None):
            print(currentNode.getData()["bom-ref"])
        print("\nDirect: ")
        print(currentNode.direct)
        if(currentNode.direct):
            print("Found from the component section")
        print("Top relation: ")
        print(currentNode.top)
        if(len(currentNode.dependsOn) > 0):
            print("Depends On: ")
            print(currentNode.dependsOn)
            if(nextNode != None):
                if(len(nextNode.dependsOn ) > 0):
                    if(currentNode.dependsOn == nextNode.dependsOn):
                        print("Matches next node")


        currentNode = nextNode
        if(currentNode != None):
            nextNode = currentNode.getNext()

print("Done")
        
    