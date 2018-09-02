namespace :scheduler do
    desc "write merkle root hash of all open documents to Ethereum blockchain"
    task write_ethereum: :environment do
        require 'merkle-hash-tree'
        require 'digest'
        require 'base64'

        @doc = Doc.where(merkle_id: nil)
        puts "open docs: " + @doc.count.to_s
        if @doc.count > 0
            id_array = Array.new
            hash_array = Array.new
            mht = MerkleHashTree.new(hash_array, Digest::SHA256)
            @merkle = Merkle.new()
            @merkle.save

            @doc.each do |item|
                item_id = item['id']
                item_hash = item['doc_hash']
                id_array << item_id
                hash_array << item_hash
                Doc.find(item_id).update_attributes(merkle_id: @merkle.id)
                puts "add hash: " + item_hash.to_s
            end

            if hash_array.length == 1
                root_node = hash_array.first
                serialized_object = ""
            else 
                serialized_object = Base64.encode64(Marshal::dump(mht)).strip
                root_node = mht.head().unpack('H*')[0]
            end
            puts "root_node: " + root_node.to_s

            puts "perform srv-blockchain"
            # request transaction
            blockchain_url = 'http://' + ENV["DOCKER_LINK_BC"].to_s + ':4510/create'
            # puts "blockchain_url: " + blockchain_url.to_s
            response = HTTParty.post(blockchain_url,
                            headers: { 'Content-Type' => 'application/json'},
                            body: { id:   @merkle.id, 
                                    hash: root_node }.to_json ).parsed_response
            # puts "repsonse: " + response.to_s
            oyd_transaction = response['transaction-id']

            @merkle.update_attributes(
                payload:         id_array.to_json,
                merkle_tree:     serialized_object,
                root_hash:       root_node,
                oyd_transaction: oyd_transaction)

        end
    end

end
