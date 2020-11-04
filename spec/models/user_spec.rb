require 'rails_helper'

RSpec.describe User, type: :model do
  subject do
    described_class.new(
      chat_id: 'chat id',
      username: 'some_name',
      first_name: 'good first name',
      last_name: 'good last name',
      gender: 'F',
      birthday: Date.today
    )
  end

  describe 'Validations' do
    it 'is valid with valid attributes' do
      expect(subject).to be_valid
    end

    it { should validate_uniqueness_of(:chat_id) }

    it { should validate_presence_of(:chat_id) }
    it { should validate_presence_of(:birthday) }

    it 'is invalid with invalid attributes - missing birthday' do
      subject.birthday = ''
      expect(subject).not_to be_valid
    end

    it 'is invalid with invalid attributes - missing chat id' do
      subject.chat_id = ''
      expect(subject).not_to be_valid
    end
  end
end
