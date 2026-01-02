import json

DEBUG = True
# Define a class to represent a Component
class Component:
    def __init__(self, ref, name, version, component_type, hashes=None, license=None, vulnerabilities=None):
        self.ref = ref
        self.name = name
        self.version = version
        self.component_type = component_type
        self.hashes = hashes
        self.license = license
        self.vulnerabilities = vulnerabilities or []  # Store vulnerabilities here

    def __str__(self):
        vulnerability_str = "\n".join(self.vulnerabilities)
        return f"Component: {self.name}\n" \
               f"Version: {self.version}\n" \
               f"Package type: {self.component_type}\n" \
               f"Hashes: {self.hashes}\n" \
               f"License: {self.license}\n" \
               f"Vulnerabilities:\n{vulnerability_str}\n"

# Define a class to represent a Dependency
class Dependency:
    def __init__(self, ref):
        self.ref = ref
        self.depends_on = []

    def __str__(self):
        depends_on_str = "\n".join(self.depends_on)
        return f"Reference: {self.ref}\n" \
               f"Depends On:\n{depends_on_str}\n"

# Define a class to represent a Dependency Tree Node
class TreeNode:
    def __init__(self, component):
        self.component = component
        self.children = []

    def __str__(self):
        return str(self.component)

    def print_dependency_tree(self, depth=0):
        indentation = "  " * depth
        print(f"{indentation}{self}")
        for child_node in self.children:
            child_node.print_dependency_tree(depth + 1)

# Define a class to represent a Vulnerability
class Vulnerability:
    def __init__(self, id, description, ratings=None, affects=None, properties=None):
        self.id = id
        self.description = description
        self.ratings = ratings or []
        self.affects = affects or []
        self.properties = properties or []

    def __str__(self):
        return f"ID: {self.id}\n" \
               f"Description: {self.description}\n" \
               f"Ratings: {', '.join(self.ratings)}\n" \
               f"Affects:\n{', '.join(self.affects)}\n" \
               f"Properties:\n{', '.join(self.properties)}\n"

# Define a DependencyTree class to encapsulate the dependency tree operations
class DependencyTree:
    def __init__(self):
        self.component_map = {}
        self.dependency_trees = {}
        self.vulnerabilities = {}

    def build_dependency_tree(self, dependency, vulnerabilities_data=None):
        if dependency.ref not in self.component_map:
            return None

        node = TreeNode(self.component_map[dependency.ref])

        for direct_dependency_ref in dependency.depends_on:
            child_node = self.build_dependency_tree(Dependency(direct_dependency_ref), vulnerabilities_data)
            if child_node:
                node.children.append(child_node)

        return node

    def load_sbom(self, sbom_file, vulnerabilities_file=None):
        try:
            with open(sbom_file, 'r', encoding='utf-8') as file:
                sbom_data = json.load(file)

            # Print some basic information about the SBOM
            bom_format = sbom_data.get('bomFormat', '')
            components_data = sbom_data.get('components', [])
            dependencies_data = sbom_data.get('dependencies', [])
            vulnerabilities_data = sbom_data.get('vulnerabilities', {})  # Check if vulnerabilities data is present

            print(f"SBOM version: {bom_format}")
            print(f"Number of components: {len(components_data)}")
            print(f"Number of dependencies: {len(dependencies_data)}")
            print(f"Number of vulnerabilities: {len(vulnerabilities_data)}")

            if DEBUG:
                print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
                print("Loading in component data")
                print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
            # Create Component objects and populate the data
            components = []
            for component_data in components_data:
                ref = component_data.get('bom-ref', '')  # Use bom-ref as reference
                name = component_data.get('name', '')
                version = component_data.get('version', '')
                component_type = component_data.get('type', '')
                hashes = component_data.get('hashes', [])
                license = component_data.get('license', '')

                component = Component(ref, name, version, component_type, hashes, license)
                components.append(component)

                # Add the component to the component_map
                self.component_map[ref] = component

            if DEBUG:
                print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
                print("Loading in dependency data")
                print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")

            # Create Dependency objects and populate the data
            dependencies = []
            for dependency_data in dependencies_data:
                ref = dependency_data.get('ref', '')
                depends_on = dependency_data.get('dependsOn', '')

                dependency = Dependency(ref)
                dependency.depends_on = depends_on
                dependencies.append(dependency)
            
            if DEBUG:
                print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
                print("Loading in vulnerability data")
                print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")

            # vulnerabilities = []
            # for vulnerability_data in vulnerabilities_data:
                



            # Build dependency tree as a binary tree for each component
            for component in components:
                dependency_tree_root = self.build_dependency_tree(Dependency(component.ref), vulnerabilities_data)
                self.dependency_trees[component.ref] = dependency_tree_root

            # Populate vulnerabilities for the component if data is available
            for component_ref, vulnerabilities in vulnerabilities_data.items():
                if component_ref in self.component_map:
                    self.component_map[component_ref].vulnerabilities = [Vulnerability(**vuln) for vuln in vulnerabilities]

                    # Associate the vulnerability objects with affected components
                    for vuln in vulnerabilities:
                        for affected_ref in vuln.get('affects', []):
                            if affected_ref in self.component_map:
                                self.component_map[affected_ref].vulnerabilities.append(Vulnerability(**vuln))

        except FileNotFoundError:
            print(f"File not found: {sbom_file}")
        except json.JSONDecodeError as e:
            print(f"Error decoding JSON: {e}")
        except Exception as e:
            print(f"An error occurred: {e}")

if __name__ == "__main__":
    sbom_file = '..\SBOM.json'  # Replace with your SBOM file path

    dependency_tree = DependencyTree()
    dependency_tree.load_sbom(sbom_file)

    # # Print the dependency trees with vulnerabilities
    # for component_ref, tree_root in dependency_tree.dependency_trees.items():
    #     print(f"Dependency Tree for {component_ref}:")
    #     tree_root.print_dependency_tree()

    # # Print vulnerabilities in a tabular format
    # print("\nVulnerabilities:")

    # for component_ref, component in dependency_tree.component_map.items():
    #     if component.vulnerabilities:
    #         print(f"Component: {component.name} ({component.version})")
    #         for vulnerability in component.vulnerabilities:
    #             print(f"  Vulnerability ID: {vulnerability.id}")
    #             print(f"  Description: {vulnerability.description}")
    #             print(f"  Ratings: {', '.join(vulnerability.ratings)}")
    #             print(f"  Affects:")
    #             for affected_ref in vulnerability.affects:
    #                 print(f"    - {affected_ref}")
    #             print(f"  Properties:")
    #             for property_data in vulnerability.properties:
    #                 print(f"    - {property_data['name']}: {property_data['value']}")
    #             print("\n")