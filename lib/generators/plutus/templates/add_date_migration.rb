class AddDateToPlutusEntries < ActiveRecord::Migration
  def change
    add_column :plutus_entries, :date, :datetime
    add_index :plutus_entries, :date
  end
end
