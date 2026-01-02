import json
import argparse
# Original Author: Justin Bukstel 
# Description: The purpose of this module is to add examples to the API specification scan
#       This is an extension module to the Veracode DAST framework



def prompt_example_values(parameters):
    example_values = {}
    for parameter in parameters:
        parameter_name = parameter["name"]
        parameter_type = parameter["schema"]["type"]
        if "example" in parameter["schema"]:
            continue  # Skip parameters with existing example values
        method = parameter["method"]
        endpoint = parameter["endpoint"]
        example = input(f"Enter an example value for parameter '{parameter_name}' of type '{parameter_type}' for the '{method}' request in '{endpoint}': ")
        example_values[parameter_name] = example
    return example_values

def add_example_values(openapi_spec, example_values):
    for path in openapi_spec["paths"]:
        for method in openapi_spec["paths"][path]:
            if "parameters" in openapi_spec["paths"][path][method]:
                for parameter in openapi_spec["paths"][path][method]["parameters"]:
                    parameter_name = parameter["name"]
                    if parameter_name in example_values:
                        parameter["schema"]["example"] = example_values[parameter_name]
                        parameter.pop("method", None)
                        parameter.pop("endpoint", None)

def write_openapi_spec(openapi_spec, filename):
    with open(filename, "w") as file:
        json.dump(openapi_spec, file, indent=2)

def main():
    parser = argparse.ArgumentParser(description="Add example values to OpenAPI specification.")
    parser.add_argument("filepath", help="Path to the JSON OpenAPI specification file")
    args = parser.parse_args()

    # Read the OpenAPI specification file
    filename = args.filepath
    with open(filename, "r") as file:
        openapi_spec = json.load(file)

    # Identify parameters requiring example values
    parameters = []
    for path in openapi_spec["paths"]:
        for method in openapi_spec["paths"][path]:
            if "parameters" in openapi_spec["paths"][path][method]:
                for parameter in openapi_spec["paths"][path][method]["parameters"]:
                    parameter["method"] = method
                    parameter["endpoint"] = path
                    parameters.append(parameter)

    # Prompt the user for example values
    example_values = prompt_example_values(parameters)

    if not example_values:
        print("All parameters already have example values. No further input needed.")
        return

    # Update the OpenAPI specification with example values
    add_example_values(openapi_spec, example_values)

    # Write the modified OpenAPI specification to a file
    updated_filename = "openapi_with_examples.json"
    write_openapi_spec(openapi_spec, updated_filename)
    print(f"Updated OpenAPI specification written to '{updated_filename}'.")

if __name__ == "__main__":
    main()