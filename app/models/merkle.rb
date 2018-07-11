# == Schema Information
#
# Table name: merkles
#
#  id              :bigint(8)        not null, primary key
#  merkle_tree     :text
#  oyd_transaction :string
#  payload         :text
#  root_hash       :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Merkle < ApplicationRecord
	has_many :docs
end
