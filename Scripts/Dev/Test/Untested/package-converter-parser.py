#!/usr/bin/env python3
"""
Package Identifier Parser and Converter

This script parses PURLs, CPEs, and package details into a standardized JSON format
and provides conversion between different package identifier formats.

Supports:
- Package URLs (PURLs) - pkg:type/namespace/name@version?qualifiers#subpath
- Common Platform Enumeration (CPEs) - cpe:2.3:part:vendor:product:version:update:edition:language:sw_edition:target_sw:target_hw:other
- Plain text package descriptions
"""

import json
import re
from urllib.parse import unquote, parse_qs
from typing import Dict, Any, Optional, Union


class PackageParser:
    def __init__(self):
        # CPE part mappings
        self.cpe_parts = {
            'a': 'application',
            'o': 'operating-system', 
            'h': 'hardware'
        }
        
        # Common PURL type mappings to CPE vendors
        self.purl_to_cpe_vendor = {
            'npm': 'npmjs',
            'pypi': 'python',
            'maven': 'apache',
            'nuget': 'microsoft',
            'gem': 'ruby-lang',
            'cargo': 'rust-lang',
            'composer': 'packagist',
            'golang': 'golang',
            'generic': '*'
        }

    def parse_input(self, input_str: str) -> Dict[str, Any]:
        """
        Parse input string and determine format (PURL, CPE, or plain text)
        Returns standardized JSON structure
        """
        input_str = input_str.strip()
        
        if input_str.startswith('pkg:'):
            return self._parse_purl(input_str)
        elif input_str.startswith('cpe:'):
            return self._parse_cpe(input_str)
        else:
            return self._parse_plain_text(input_str)

    def _parse_purl(self, purl: str) -> Dict[str, Any]:
        """Parse a Package URL (PURL) into components"""
        # Remove pkg: prefix
        purl = purl[4:]
        
        # Split main components
        parts = purl.split('@', 1)
        if len(parts) == 2:
            name_part, version_part = parts
        else:
            name_part = parts[0]
            version_part = ""
        
        # Extract version, qualifiers, and subpath
        version = ""
        qualifiers = {}
        subpath = ""
        
        if version_part:
            # Check for subpath (after #)
            if '#' in version_part:
                version_part, subpath = version_part.split('#', 1)
            
            # Check for qualifiers (after ?)
            if '?' in version_part:
                version, qual_str = version_part.split('?', 1)
                qualifiers = parse_qs(qual_str, keep_blank_values=True)
                # Flatten single-value lists
                qualifiers = {k: v[0] if len(v) == 1 else v for k, v in qualifiers.items()}
            else:
                version = version_part
        
        # Parse type/namespace/name
        name_parts = name_part.split('/')
        purl_type = name_parts[0] if name_parts else ""
        
        if len(name_parts) >= 3:
            namespace = '/'.join(name_parts[1:-1])
            name = name_parts[-1]
        elif len(name_parts) == 2:
            namespace = name_parts[1] if purl_type in ['maven', 'golang'] else ""
            name = name_parts[1] if purl_type not in ['maven', 'golang'] else name_parts[1]
        else:
            namespace = ""
            name = ""
        
        # URL decode components
        purl_type = unquote(purl_type)
        namespace = unquote(namespace) if namespace else ""
        name = unquote(name)
        version = unquote(version) if version else ""
        
        return {
            "format": "purl",
            "type": purl_type,
            "namespace": namespace,
            "name": name,
            "version": version,
            "qualifiers": qualifiers,
            "subpath": subpath,
            "vendor": self._infer_vendor_from_purl(purl_type, namespace),
            "product": name,
            "part": "application",
            "original": f"pkg:{purl}"
        }

    def _parse_cpe(self, cpe: str) -> Dict[str, Any]:
        """Parse a Common Platform Enumeration (CPE) string"""
        if cpe.startswith('cpe:2.3:'):
            return self._parse_cpe23(cpe)
        elif cpe.startswith('cpe:/'):
            return self._parse_cpe22(cpe)
        else:
            raise ValueError(f"Unsupported CPE format: {cpe}")

    def _parse_cpe23(self, cpe: str) -> Dict[str, Any]:
        """Parse CPE 2.3 format"""
        parts = cpe.split(':')
        if len(parts) < 6:
            raise ValueError(f"Invalid CPE 2.3 format: {cpe}")
        
        # CPE 2.3 format: cpe:2.3:part:vendor:product:version:update:edition:language:sw_edition:target_sw:target_hw:other
        cpe_dict = {
            "format": "cpe",
            "cpe_version": "2.3",
            "part": self.cpe_parts.get(parts[2], parts[2]),
            "vendor": self._decode_cpe_component(parts[3]) if len(parts) > 3 else "",
            "product": self._decode_cpe_component(parts[4]) if len(parts) > 4 else "",
            "version": self._decode_cpe_component(parts[5]) if len(parts) > 5 else "",
            "update": self._decode_cpe_component(parts[6]) if len(parts) > 6 else "",
            "edition": self._decode_cpe_component(parts[7]) if len(parts) > 7 else "",
            "language": self._decode_cpe_component(parts[8]) if len(parts) > 8 else "",
            "sw_edition": self._decode_cpe_component(parts[9]) if len(parts) > 9 else "",
            "target_sw": self._decode_cpe_component(parts[10]) if len(parts) > 10 else "",
            "target_hw": self._decode_cpe_component(parts[11]) if len(parts) > 11 else "",
            "other": self._decode_cpe_component(parts[12]) if len(parts) > 12 else "",
            "original": cpe
        }
        
        # Add standardized fields
        cpe_dict.update({
            "type": self._infer_purl_type_from_cpe(cpe_dict["vendor"], cpe_dict["product"]),
            "namespace": cpe_dict["vendor"],
            "name": cpe_dict["product"],
            "qualifiers": {}
        })
        
        return cpe_dict

    def _parse_cpe22(self, cpe: str) -> Dict[str, Any]:
        """Parse CPE 2.2 format (legacy)"""
        # CPE 2.2 format: cpe:/part:vendor:product:version:update:edition:language
        parts = cpe.split(':')
        if len(parts) < 4:
            raise ValueError(f"Invalid CPE 2.2 format: {cpe}")
        
        part_char = parts[0][-1] if parts[0] else ""
        
        cpe_dict = {
            "format": "cpe",
            "cpe_version": "2.2", 
            "part": self.cpe_parts.get(part_char, part_char),
            "vendor": self._decode_cpe_component(parts[1]) if len(parts) > 1 else "",
            "product": self._decode_cpe_component(parts[2]) if len(parts) > 2 else "",
            "version": self._decode_cpe_component(parts[3]) if len(parts) > 3 else "",
            "update": self._decode_cpe_component(parts[4]) if len(parts) > 4 else "",
            "edition": self._decode_cpe_component(parts[5]) if len(parts) > 5 else "",
            "language": self._decode_cpe_component(parts[6]) if len(parts) > 6 else "",
            "original": cpe
        }
        
        # Add standardized fields
        cpe_dict.update({
            "type": self._infer_purl_type_from_cpe(cpe_dict["vendor"], cpe_dict["product"]),
            "namespace": cpe_dict["vendor"],
            "name": cpe_dict["product"],
            "qualifiers": {}
        })
        
        return cpe_dict

    def _parse_plain_text(self, text: str) -> Dict[str, Any]:
        """Parse plain text package description"""
        # Try to extract package info from common formats
        # Examples: "apache:tomcat:9.0.1", "numpy==1.21.0", "lodash@4.17.21"
        
        result = {
            "format": "plain_text",
            "original": text,
            "vendor": "",
            "product": "",
            "name": "",
            "version": "",
            "namespace": "",
            "type": "generic",
            "part": "application",
            "qualifiers": {}
        }
        
        # Pattern matching for common formats
        patterns = [
            # vendor:product:version (CPE-like)
            r'^([^:]+):([^:]+):([^:]+)$',
            # name==version (Python pip)
            r'^([^=]+)==([^=]+)$',
            # name@version (npm-like)
            r'^([^@]+)@([^@]+)$',
            # name-version (generic)
            r'^([^-]+)-([0-9].*)$',
            # name version (space separated)
            r'^([^\s]+)\s+([0-9].*)$'
        ]
        
        for pattern in patterns:
            match = re.match(pattern, text)
            if match:
                groups = match.groups()
                if len(groups) == 3:  # vendor:product:version
                    result["vendor"] = groups[0]
                    result["product"] = groups[1] 
                    result["name"] = groups[1]
                    result["version"] = groups[2]
                    result["namespace"] = groups[0]
                elif len(groups) == 2:  # name version
                    result["name"] = groups[0]
                    result["product"] = groups[0]
                    result["version"] = groups[1]
                break
        
        # If no pattern matched, treat entire string as product name
        if not result["name"]:
            result["name"] = text
            result["product"] = text
        
        return result

    def _decode_cpe_component(self, component: str) -> str:
        """Decode CPE component (handle wildcards and escaping)"""
        if component in ['*', '-', '']:
            return ""
        # Basic CPE unescaping (simplified)
        return component.replace('\\:', ':').replace('\\\\', '\\')

    def _infer_vendor_from_purl(self, purl_type: str, namespace: str) -> str:
        """Infer vendor from PURL type and namespace"""
        if namespace:
            return namespace
        return self.purl_to_cpe_vendor.get(purl_type, "")

    def _infer_purl_type_from_cpe(self, vendor: str, product: str) -> str:
        """Infer PURL type from CPE vendor/product"""
        vendor_lower = vendor.lower()
        product_lower = product.lower()
        
        if 'python' in vendor_lower or 'pypi' in vendor_lower:
            return 'pypi'
        elif 'npm' in vendor_lower or 'node' in vendor_lower:
            return 'npm'
        elif 'apache' in vendor_lower and 'maven' in product_lower:
            return 'maven'
        elif 'microsoft' in vendor_lower or 'nuget' in vendor_lower:
            return 'nuget'
        elif 'ruby' in vendor_lower or 'gem' in vendor_lower:
            return 'gem'
        elif 'rust' in vendor_lower or 'cargo' in vendor_lower:
            return 'cargo'
        elif 'golang' in vendor_lower or 'go' in product_lower:
            return 'golang'
        else:
            return 'generic'

    def to_purl(self, package_data: Dict[str, Any]) -> str:
        """Convert package data to PURL format"""
        purl_type = package_data.get('type', 'generic')
        namespace = package_data.get('namespace', '')
        name = package_data.get('name', '')
        version = package_data.get('version', '')
        qualifiers = package_data.get('qualifiers', {})
        subpath = package_data.get('subpath', '')
        
        # Build PURL
        purl_parts = ['pkg:', purl_type]
        
        if namespace:
            purl_parts.extend(['/', namespace])
        
        purl_parts.extend(['/', name])
        
        if version:
            purl_parts.extend(['@', version])
        
        if qualifiers:
            qual_str = '&'.join([f"{k}={v}" for k, v in qualifiers.items()])
            purl_parts.extend(['?', qual_str])
        
        if subpath:
            purl_parts.extend(['#', subpath])
        
        return ''.join(purl_parts)

    def to_cpe(self, package_data: Dict[str, Any], version: str = "2.3") -> str:
        """Convert package data to CPE format"""
        part = 'a'  # default to application
        vendor = package_data.get('vendor', package_data.get('namespace', ''))
        product = package_data.get('product', package_data.get('name', ''))
        pkg_version = package_data.get('version', '')
        
        # Encode empty/wildcard values
        def encode_cpe_component(value):
            if not value:
                return '*'
            return value.replace('\\', '\\\\').replace(':', '\\:')
        
        if version == "2.3":
            return f"cpe:2.3:{part}:{encode_cpe_component(vendor)}:{encode_cpe_component(product)}:{encode_cpe_component(pkg_version)}:*:*:*:*:*:*:*"
        else:  # 2.2
            return f"cpe:/{part}:{encode_cpe_component(vendor)}:{encode_cpe_component(product)}:{encode_cpe_component(pkg_version)}"

    def to_plain_text(self, package_data: Dict[str, Any]) -> str:
        """Convert package data to plain text description"""
        name = package_data.get('name', package_data.get('product', ''))
        version = package_data.get('version', '')
        vendor = package_data.get('vendor', package_data.get('namespace', ''))
        
        if vendor and vendor != name:
            if version:
                return f"{vendor}:{name}:{version}"
            else:
                return f"{vendor}:{name}"
        else:
            if version:
                return f"{name}@{version}"
            else:
                return name


def main():
    """Example usage and testing"""
    parser = PackageParser()
    
    # Test cases
    test_inputs = [
        "pkg:pypi/numpy@1.21.0",
        "pkg:npm/lodash@4.17.21",
        "pkg:maven/org.apache.commons/commons-lang3@3.12.0",
        "cpe:2.3:a:apache:tomcat:9.0.1:*:*:*:*:*:*:*:*",
        "cpe:/a:microsoft:windows:10.0.19042",
        "apache:tomcat:9.0.1",
        "numpy==1.21.0",
        "lodash@4.17.21"
    ]
    
    print("Package Parser and Converter")
    print("=" * 50)
    
    for test_input in test_inputs:
        print(f"\nInput: {test_input}")
        try:
            result = parser.parse_input(test_input)
            print(f"Parsed: {json.dumps(result, indent=2)}")
            
            # Convert to different formats
            if result['format'] != 'purl':
                purl = parser.to_purl(result)
                print(f"As PURL: {purl}")
            
            if result['format'] != 'cpe':
                cpe = parser.to_cpe(result)
                print(f"As CPE: {cpe}")
            
            plain = parser.to_plain_text(result)
            print(f"As Plain Text: {plain}")
            
        except Exception as e:
            print(f"Error: {e}")
        
        print("-" * 30)


if __name__ == "__main__":
    main()