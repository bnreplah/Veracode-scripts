#!/usr/bin/env python3

import sys, json

__version__ = "0.0.2"
__spec_version__ = "1.6"
def convert(results_file, output_file):

	# Check if no results file or output file currently available
	if(results_file == "" or output_file == ""):
		print("Results file not found\n")
		print("Usage: srcclr-sbom-gen.py <scan_results.json> <output_file.json>")
		return

	# TODO: Add more SBOM formats
	sbom = {"bomFormat": "CycloneDX", "version": "1", "specVersion": "1.6","components":[], "dependencies": [] , "vulnerabilities": [], "annotations":[]}
	components = []
	# TODO: Add Vulnerabilities section
	# TODO: ADd the ability to combine SBOMs
	

	with open(results_file) as file:
		scanresults = json.load(file)
		records = scanresults['records']
		libraries = records[0]['libraries']
		for lib in libraries:
			coordinate2 = "" if lib['coordinate2'] == "" else ":" + lib['coordinate2']
			lib_name = lib['coordinate1'] if lib['coordinate2'] == "" else lib['coordinate1'] + "/" + lib['coordinate2'] # need to potentially put a patch in here if to use it for CPE as well
			try:
				hash_sha1 = lib['versions'][0]['sha1']
			except:
				hash_sha1 = ""
			try:
				hash_sha2 = lib['versions'][0]['sha2']
			except:
				hash_sha2 = ""
			purl = "pkg:{}/{}@{}".format(lib['coordinateType'].lower(), lib_name, lib["versions"][0]['version'])
			cpe = "cpe:2.3:o:{}:{}:{}:*:*:*:*:*:*:*"
			# checking to see if the components are populated? 
			# Need to figure out what is going on here before coming back
			for c in components:
				if c['purl'] == purl:
					continue
			dataset = {
			"description": lib['description'],
			"hashes": [
				{
					"alg": "SHA-1",
					"content": hash_sha1
				},
				{
					"alg": "SHA-256",
					"content": hash_sha2
				}],
			"licenses": lib['versions'][0]['licenses'],
			"modified": False,
			"name": "{}{}".format(lib['coordinate1'], coordinate2),
			"publisher": lib['author'],
			"purl": purl,
			"type": "library",
			"version": lib["versions"][0]['version']
			}
			components.append(dataset)


	with open(output_file, 'w') as outfile:
		sbom['components'] = components
		json.dump(sbom, outfile, indent=4, sort_keys=True)


#Run as script
if __name__ == "__main__":
	if(len(sys.argv) != 3):
			print("Usage: srcclr-sbom-gen.py <scan_results.json> <output_file.json>")
			sys.exit()

	convert(sys.argv[1], sys.argv[2])