class AddPromotionToSignups < ActiveRecord::Migration[8.1]
  def change
    # When a volunteer was moved from the waiting list to confirmed, and when they were told.
    add_column :signups, :promoted_at, :datetime
    add_column :signups, :promotion_notified_at, :datetime
    add_index :signups, :user_id, where: "promoted_at IS NOT NULL AND promotion_notified_at IS NULL",
                                  name: "index_signups_on_user_id_unnotified_promotions"
  end
end
