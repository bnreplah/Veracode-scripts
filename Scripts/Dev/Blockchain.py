### A simple python block chain program for fun and to be used for various use cases
### Author: Ben Halpern - Veracode
### Role: Associate CSE
### Manager: Justin Yao
### Date: 9/7/22
### Reference: https://www.geeksforgeeks.org/create-simple-blockchain-using-python/ 
### Still a work in progress


import datetime
import hashlib
import json

#from flask import Flask, jsonify

class Blockchain:
    def __init__(self):
        self.chain = []
        self.create_block(nonce=1, previous_hash='0')

    def create_block(self, nonce, previous_hash, data="[Default]"):
        block = {
            'index': len(self.chain) + 1,
            'timestamp': str(datetime.datetime.now()),
            'nonce': nonce,
            'data': data,
            'previous_hash': previous_hash
        }
        self.chain.append(block)
        return block

    def print_previous_block(self):
        return self.chain[-1]
    
    def proof_of_work(self, previous_nonce):
        new_nonce = 1
        check_proof = False
        while check_proof is False:
            hash_op = hashlib.sha512(
                str(new_nonce**2 - previous_nonce**2).encode()
            ).hexdigest()
            if hash_op[:5] == '00000':
                check_proof = True
            else:
                new_nonce += 1
        return new_nonce

    def hash(self, block):
        encoded_block = json.dumps(block, sort_keys=True).encode()
        return hashlib.sha512(encoded_block).hexdigest()

    def get_chain(self):
        return self.chain

    def chain_valid(self, chain):
        previous_block = chain[0]
        block_index = 1
        while block_index < len(chain):
            block = chain[block_index]
            if block['previous_hash'] != self.hash(previous_block):
                return False
            previous_nonce = previous_block['proof']
            nonce = block['proof']
            hash_op = hashlib.sha512(
                str(nonce**2 - previous_nonce**2).encode()
            ).hexdigest()
            if hash_op[:5] != '00000':
                return False
            previous_block = block
            block_index += 1

        return True

#TEST
new_blockchain = Blockchain()
print(new_blockchain.create_block(2, '000000', "random data"))
print(new_blockchain.proof_of_work(1))
print(new_blockchain.get_chain())
## Hosting the block chain via a browser end point

# # Creating the Web
# # App using flask
# app = Flask(__name__)
 
# # Create the object
# # of the class blockchain
# blockchain = Blockchain()
 
# # Mining a new block
# @app.route('/mine_block', methods=['GET'])
# def mine_block():
#     previous_block = blockchain.print_previous_block()
#     previous_nonce = previous_block['proof']
#     nonce = blockchain.proof_of_work(previous_nonce)
#     previous_hash = blockchain.hash(previous_block)
#     block = blockchain.create_block(nonce, previous_hash)
     
#     response = {'message': 'A block is MINED',
#                 'index': block['index'],
#                 'timestamp': block['timestamp'],
#                 'data': block['data'],
#                 'nonce': block['proof'],
#                 'previous_hash': block['previous_hash']}
     
#     return jsonify(response), 200
 
# # Display blockchain in json format
# @app.route('/get_chain', methods=['GET'])
# def display_chain():
#     response = {'chain': blockchain.chain,
#                 'length': len(blockchain.chain)}
#     return jsonify(response), 200
 
# # Check validity of blockchain
# @app.route('/valid', methods=['GET'])
# def valid():
#     valid = blockchain.chain_valid(blockchain.chain)
     
#     if valid:
#         response = {'message': 'The Blockchain is valid.'}
#     else:
#         response = {'message': 'The Blockchain is not valid.'}
#     return jsonify(response), 200
 
 
# # Run the flask server locally
# app.run(host='127.0.0.1', port=5000)
# #
# #

    