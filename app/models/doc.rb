# == Schema Information
#
# Table name: docs
#
#  id            :bigint(8)        not null, primary key
#  comment       :string
#  did           :string
#  doc_hash      :string
#  doc_tsr       :text
#  note          :text
#  tsr_timestamp :string
#  url           :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  merkle_id     :integer
#
# Indexes
#
#  index_docs_on_doc_hash  (doc_hash)
#

class Doc < ApplicationRecord
	belongs_to :merkle, optional: true
end
