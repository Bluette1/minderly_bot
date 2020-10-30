class User < ApplicationRecord
  serialize :important_days
  validates_uniqueness_of :chat_id
end
