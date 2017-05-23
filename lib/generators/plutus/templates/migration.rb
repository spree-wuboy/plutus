class CreatePlutusTables < ActiveRecord::Migration
  def self.up
    create_table :plutus_accounts do |t|
      t.string :name
      t.string :type
      t.boolean :contra
      
      t.integer :code, index: true
      t.integer :rollup_code, index: true
      t.references :plutus_account, index: true

      t.timestamps
    end
    add_index :plutus_accounts, [:name, :type]

    create_table :plutus_entries do |t|
      t.references :target, polymorphic: true, index: true
      t.string :description
      t.datetime :date, index: true
      t.references :commercial_document, polymorphic: true, index: true

      t.timestamps
    end

    create_table :plutus_amounts do |t|
      t.string :type
      t.references :account
      t.references :entry
      t.decimal :amount, :precision => 20, :scale => 10
    end
    add_index :plutus_amounts, :type
    add_index :plutus_amounts, [:account_id, :entry_id]
    add_index :plutus_amounts, [:entry_id, :account_id]
  end

  def self.down
    drop_table :plutus_accounts
    drop_table :plutus_entries
    drop_table :plutus_amounts
  end
end
