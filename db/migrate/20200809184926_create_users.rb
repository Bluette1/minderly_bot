class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|

      t.string :chat_id
      t.string :first_name
      t.string :last_name
      t.string :username
      t.string :gender
      t.date :birthday
      t.string :important_days, default: {}.to_yaml

      t.timestamps
    end
  end
end
