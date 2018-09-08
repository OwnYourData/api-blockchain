module Api
    module V1
        class DocsController < ApiController
            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def worker
                hash = params[:hash].to_s

                if hash.length == 64 && !hash[/\H/]
                    if Doc.exists?(doc_hash: hash)
                        @doc = Doc.find_by_doc_hash(hash)
                        @merkle = @doc.merkle

                        retVal = {}
                        retVal["status"] = "exist"
                        retVal["address"] = ""
                        retVal["root-node"] = ""
                        retVal["audit-proof"] = []
                        retVal["ether-timestamp"] = ""
                        retVal["oyd-timestamp"] = ""


                        if !@merkle.nil?
                            payload = JSON.parse(@merkle.payload)
                            transaction = @merkle.oyd_transaction
                            if payload.length > 1
                              mht = Marshal::load(Base64.decode64(@merkle.merkle_tree.delete("\n")))
                              pos = payload.index(@doc['id'])
                              audit_proof = mht.audit_proof(pos).collect {|item| item.unpack('H*')[0] }.join(', ')
                              retVal["audit-proof"] = lr_annotate(audit_proof, payload.length, pos)
                            end
                            blockchain_url = 'http://' + ENV["DOCKER_LINK_BC"].to_s + ':4510/getTransactionStatus'
                            response = HTTParty.get(blockchain_url,
                                headers: { 'Content-Type' => 'application/json'},
                                body: { id:   @merkle.id, 
                                        hash: transaction }.to_json ).parsed_response
                            retVal["address"] = @merkle.oyd_transaction.to_s unless @merkle.nil?
                            retVal["root-node"] = @merkle.root_hash.to_s unless @merkle.nil?
                            if !response["transaction-status"].nil?
                                blockTimestamp = response["transaction-status"]["blockTimestamp"]
                                retVal["ether-timestamp"] = Time.at(blockTimestamp.to_i(16)).strftime('%Y-%m-%dT%H:%M:%SZ')
                            end
                        end
                        retVal["oyd-timestamp"] = @doc.created_at.utc.strftime('%Y-%m-%dT%H:%M:%SZ')

                        render json: retVal,
                               status: 200
                    else
                        @doc = Doc.new(doc_hash: hash)
                        if @doc.save
                            render json: {"status": "new",
                                          "address": "",
                                          "root-node": "",
                                          "audit-proof": [],
                                          "ether-timestamp": "",
                                          "oyd-timestamp": @doc.created_at.utc.strftime('%Y-%m-%dT%H:%M:%SZ')},
                                   status: 200
                        else
                            render json: {"error": @doc.errors.messages.join(", ")},
                                   status: 500
                        end
                    end
                else
                    render json: { "error": "invalid hash" },
                           status: 500
                end
            end

            def status
                blockchain_url = 'http://' + ENV["DOCKER_LINK_BC"].to_s + ':4510/getBalance'
                response = HTTParty.get(blockchain_url).parsed_response

                render json: { "docs": Doc.count, 
                               "pending": Doc.where(merkle_id: nil).count,
                               "last_date": Merkle.last.created_at.utc.strftime('%Y-%m-%dT%H:%M:%SZ'),
                               "last_count": Merkle.last.docs.count,
                               "balance": response["balanceEther"].to_s,
                               "version":"0.4.0"}, 
                       status: 200
            end

            # audit_proof - array with hashes for audit proof
            # len - number of items in merkle tree
            # pos - zero-based position of item/leaf in merkle tree
            def lr_annotate(audit_proof, len, pos)
              pathStr = get_auditproof_path(len, pos)
              retVal = []
              audit_proof.split(", ").each do |item|
                item = pathStr[0] + item
                pathStr[0] = ''
                retVal << item
              end
              retVal.join(", ")
            end

            # return for a given element (defined by pos) in a merkle tree
            # with len number of leafes the path for the audit proof where
            # + indicates left element of a branch and - indicates right
            # element of a branch
            def get_auditproof_path(len, pos)
              if (len == 1)
                ""
              else
                p2 = 2 << (len.bit_length - 2)
                if (len == p2)
                  digits = Math.log2( 2 << ((len-1).bit_length - 2)) +1
                  pos.to_s(2).rjust(digits, "0").reverse.gsub("1", "+").gsub("0", "-")
                else
                  if (pos < p2)
                    get_auditproof_path(p2, pos) + "-"
                  else
                    get_auditproof_path(len-p2, pos-p2) + "+"
                  end
                end
              end
            end

            # validate hash and audit proof against root_node
            # audit proof ="hash; +audit, -proof, +values" in hexadecimal
            # root_node in hexadecimal
            def validate(audit_proof, root_node)
                node = Digest::SHA256.digest("\0" + audit_proof.split("; ")[0])
                ap = audit_proof.split("; ")[1].split(", ")
                ap.each do |item|
                    if item[0] == "+"
                        item[0] = ""
                        left_node = [item].pack("H*")
                        right_node = node
                    else
                        item[0] = ""
                        left_node = node
                        right_node = [item].pack("H*")
                    end
                    node = Digest::SHA256.digest("\x01" + left_node + right_node)
                end
                if node.unpack('H*')[0] == root_node
                    puts "successfully validated\n"
                else
                    puts "audit proof does not match root hash"
                end
            end            
        end
    end
end


# 1 element
#   0 []

# 2 elements
#   0 [-] - 0
#   1 [+] - 1

# 3 elements
#   0 [-,-] - 00
#   1 [+,-] - 01
#   2 [+]   - 10

# 4 elements
#   0 [-,-] - 00
#   1 [+,-] - 01
#   2 [-,+] - 10
#   3 [+,+] - 11

# 5 elements
#   0 [-,-,-] - 000
#   1 [+,-,-] - 001
#   2 [-,+,-] - 010
#   3 [+,+,-] - 011
#   4 [+]     - 100

# 6 elements
#   0 [-,-,-] - 000
#   1 [+,-,-] - 001
#   2 [-,+,-] - 010
#   3 [+,+,-] - 011
#   4 [-,+]   - 100
#   5 [+,+]   - 101

# 7 elements
#   0 [-,-,-] - 000
#   1 [+,-,-] - 001
#   2 [-,+,-] - 010
#   3 [+,+,-] - 011
#   4 [-,-,+] - 100
#   5 [+,-,+] - 101
#   6 [+,+]   - 110

# 8 elements
#   0 [-,-,-] - 000
#   1 [+,-,-] - 001
#   2 [-,+,-] - 010
#   3 [+,+,-] - 011
#   4 [-,-,+] - 100
#   5 [+,-,+] - 101
#   6 [-,+,+] - 110
#   7 [+,+,+] - 111


# 9 elements
#   0 [-,-,-,-] - 0000
#   1 [+,-,-,-] - 0001
#   2 [-,+,-,-] - 0010
#   3 [+,+,-,-] - 0011
#   4 [-,-,+,-] - 0100
#   5 [+,-,+,-] - 0101
#   6 [-,+,+,-] - 0110
#   7 [+,+,+,-] - 0111
#   8 [+]       - 1000

# 10 elements
#   0 [-,-,-,-] - 0000
#   1 [+,-,-,-] - 0001
#   2 [-,+,-,-] - 0010
#   3 [+,+,-,-] - 0011
#   4 [-,-,+,-] - 0100
#   5 [+,-,+,-] - 0101
#   6 [-,+,+,-] - 0110
#   7 [+,+,+,-] - 0111
#   8 [-,+]     - 1000
#   9 [+,+]     - 1001

# 11 elements
#   0 [-,-,-,-] - 0000
#   1 [+,-,-,-] - 0001
#   2 [-,+,-,-] - 0010
#   3 [+,+,-,-] - 0011
#   4 [-,-,+,-] - 0100
#   5 [+,-,+,-] - 0101
#   6 [-,+,+,-] - 0110
#   7 [+,+,+,-] - 0111
#   8 [-,-,+]   - 1000
#   9 [+,-,+]   - 1001
#  10 [+,+]     - 1010

# 12 elements
#   0 [-,-,-,-]
#   1 [+,-,-,-]
#   2 [-,+,-,-]
#   3 [+,+,-,-]
#   4 [-,-,+,-]
#   5 [+,-,+,-]
#   6 [-,+,+,-]
#   7 [+,+,+,-]
#   8 [-,-,+]
#   9 [+,-,+]
#  10 [-,+,+]
#  11 [+,+,+]

#  ---

# 13 elements
#   0 [-,-,-,-]
#   1 [+,-,-,-]
#   2 [-,+,-,-]
#   3 [+,+,-,-]
#   4 [-,-,+,-]
#   5 [+,-,+,-]
#   6 [-,+,+,-]
#   7 [+,+,+,-]
#   8 [-,-,-,+]
#   9 [+,-,-,+]
#  10 [+,-,+]
#  11 [-,+,+]
#  12 [+,+,+]

# 14 elements
#   0 [-,-,-,-]
#   1 [+,-,-,-]
#   2 [-,+,-,-]
#   3 [+,+,-,-]
#   4 [-,-,+,-]
#   5 [+,-,+,-]
#   6 [-,+,+,-]
#   7 [+,+,+,-]
#   8 [-,-,-,+]
#   9 [+,-,-,+]
#  10 [-,+,-,+]
#  11 [+,+,-,+]
#  12 [-,+,+]
#  13 [+,+,+]

# 15 elements
#   0 [-,-,-,-]
#   1 [+,-,-,-]
#   2 [-,+,-,-]
#   3 [+,+,-,-]
#   4 [-,-,+,-]
#   5 [+,-,+,-]
#   6 [-,+,+,-]
#   7 [+,+,+,-]
#   8 [-,-,-,+]
#   9 [+,-,-,+]
#  10 [-,+,-,+]
#  11 [+,+,-,+]
#  12 [-,-,+,+]
#  13 [+,-,+,+]
#  14 [+,+,+]

# 16 elements
#   0 [-,-,-,-]
#   1 [+,-,-,-]
#   2 [-,+,-,-]
#   3 [+,+,-,-]
#   4 [-,-,+,-]
#   5 [+,-,+,-]
#   6 [-,+,+,-]
#   7 [+,+,+,-]
#   8 [-,-,-,+]
#   9 [+,-,-,+]
#  10 [-,+,-,+]
#  11 [+,+,-,+]
#  12 [-,-,+,+]
#  13 [+,-,+,+]
#  14 [-,+,+,+]
#  15 [+,+,+,+]