class User < ApplicationRecord
  serialize :important_days
  validates_presence_of :birthday
  validates :chat_id, presence: true, uniqueness: true
end
