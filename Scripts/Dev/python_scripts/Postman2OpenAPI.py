import json
import sys
# Notes from tests,
# it seems to create examples, but null or poor examples

def convert_postman_to_openapi(postman_collection):
    openapi = {
        "openapi": "3.0.0",
        "info": {
            "title": postman_collection.get("info", {}).get("name", "Converted API"),
            "version": "1.0.0",
            "description": postman_collection.get("info", {}).get("description", "Automatically converted from Postman collection")
        },
        "paths": {}
    }
    
    for item in postman_collection.get("item", []):
        path, methods = extract_path_and_methods(item)
        if path and methods:
            openapi["paths"].setdefault(path, {}).update(methods)
    
    return openapi

def extract_path_and_methods(item):
    if not isinstance(item, dict) or "request" not in item:
        return None, None
    
    request = item["request"]
    url = request.get("url", {}).get("raw", "")
    if not url:
        return None, None
    
    path = "/" + "/".join(url.split("/")[3:])
    method = request.get("method", "get").lower()
    
    operation = {
        "summary": item.get("name", ""),
        "description": request.get("description", ""),
        "operationId": item.get("name", "").replace(" ", "_"),
        "parameters": extract_parameters(request),
        "responses": {
            "200": {
                "description": "Successful response",
                "content": {
                    "application/json": {
                        "schema": {
                            "type": "object"
                        },
                        "example": generate_example_from_response(item)
                    }
                }
            }
        }
    }
    
    return path, {method: operation}

def extract_parameters(request):
    parameters = []
    query_params = request.get("url", {}).get("query", [])
    for param in query_params:
        parameters.append({
            "name": param.get("key", ""),
            "in": "query",
            "required": param.get("disabled", False) is False,
            "schema": {"type": "string"},
            "description": param.get("description", "")
        })
    return parameters

def generate_example_from_response(item):
    responses = item.get("response", [])
    if isinstance(responses, list):
        for response in responses:
            if isinstance(response, dict) and response.get("status", "") == "OK":
                try:
                    return json.loads(response.get("body", "{}"))
                except (json.JSONDecodeError, TypeError):
                    return response.get("body", "")
    return {}

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python script.py <postman_collection.json>")
        sys.exit(1)
    
    postman_file = sys.argv[1]
    
    try:
        with open(postman_file, "r", encoding="utf-8") as f:
            postman_collection = json.load(f)
        
        openapi_spec = convert_postman_to_openapi(postman_collection)
        
        output_file = "openapi.json"
        with open(output_file, "w", encoding="utf-8") as f:
            json.dump(openapi_spec, f, indent=4)
        
        print(f"OpenAPI spec written to {output_file}")
    except (FileNotFoundError, json.JSONDecodeError) as e:
        print(f"Error: {e}")
        sys.exit(1)
