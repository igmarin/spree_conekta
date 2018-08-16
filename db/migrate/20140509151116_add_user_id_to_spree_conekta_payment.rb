class AddUserIdToSpreeConektaPayment < SpreeSupport::Migration[4.2]
  def change
    add_column :spree_conekta_payments, :user_id, :integer
    add_index :spree_conekta_payments, :user_id
  end
end
