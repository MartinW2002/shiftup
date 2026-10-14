class CreateShifts < ActiveRecord::Migration[8.1]
  def change
    create_table :shifts do |t|
      t.references :activity, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :capacity, null: false

      t.timestamps
    end
    add_index :shifts, :starts_at
    add_check_constraint :shifts, "capacity > 0", name: "shifts_capacity_positive"
    add_check_constraint :shifts, "ends_at > starts_at", name: "shifts_ends_after_start"
  end
end
