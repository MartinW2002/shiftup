class AddRemovalToSignups < ActiveRecord::Migration[8.1]
  def change
    # When an organizer removed the volunteer from the shift, and when the volunteer was told.
    add_column :signups, :removed_at, :datetime
    add_column :signups, :removal_notified_at, :datetime
    add_index :signups, :user_id, where: "removed_at IS NOT NULL AND removal_notified_at IS NULL",
                                  name: "index_signups_on_user_id_unnotified_removals"
  end
end
