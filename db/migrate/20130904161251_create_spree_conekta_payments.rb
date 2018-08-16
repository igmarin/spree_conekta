class CreateSpreeConektaPayments < SolidusSupport::Migration[4.2]
  def change
    create_table :spree_conekta_payments do |t|
      t.string :type

      t.timestamps
    end
  end
end
