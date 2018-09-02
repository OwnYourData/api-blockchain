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
                              retVal["audit-proof"] = audit_proof
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

            def validate
                render json: {"coming": "soon"}, 
                       status: 200
            end

            def merkle
                render json: {"coming": "soon"}, 
                       status: 200
            end

            def status
                blockchain_url = 'http://' + ENV["DOCKER_LINK_BC"].to_s + ':4510/getBalance'
                response = HTTParty.get(blockchain_url).parsed_response

                render json: { "docs": Doc.count, 
                               "pending": Doc.where(merkle_id: nil).count,
                               "last_date": Merkle.last.created_at.utc.strftime('%Y-%m-%dT%H:%M:%SZ'),
                               "last_count": Merkle.last.docs.count,
                               "balance": response["balanceEther"].to_s,
                               "version":"0.3.1"}, 
                       status: 200
            end
        end
    end
end