class CreateSignups < ActiveRecord::Migration[8.1]
  def change
    create_table :signups do |t|
      t.references :shift, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :attendance, null: false, default: 0

      t.timestamps
    end
    # A volunteer may hold at most one active (confirmed or waitlisted) sign-up per shift.
    add_index :signups, [ :shift_id, :user_id ], unique: true,
              where: "status <> 2", name: "index_signups_on_shift_and_user_active"
    add_index :signups, [ :shift_id, :status, :created_at ]
  end
end
