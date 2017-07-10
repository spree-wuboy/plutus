module Plutus
  # Entries are the recording of debits and credits to various accounts.
  # This table can be thought of as a traditional accounting Journal.
  #
  # Posting to a Ledger can be considered to happen automatically, since
  # Accounts have the reverse 'has_many' relationship to either it's credit or
  # debit entries
  #
  # @example
  #   cash = Plutus::Asset.find_by_name('Cash')
  #   accounts_receivable = Plutus::Asset.find_by_name('Accounts Receivable')
  #
  #   debit_amount = Plutus::DebitAmount.new(:account => cash, :amount => 1000)
  #   credit_amount = Plutus::CreditAmount.new(:account => accounts_receivable, :amount => 1000)
  #
  #   entry = Plutus::Entry.new(:description => "Receiving payment on an invoice")
  #   entry.debit_amounts << debit_amount
  #   entry.credit_amounts << credit_amount
  #   entry.save
  #
  # @see http://en.wikipedia.org/wiki/Journal_entry Journal Entry
  #
  # @author Michael Bulat
  class Entry < ActiveRecord::Base
    default_scope {order("date desc").includes(:debit_amounts => :account, :credit_amounts => :account)}
    before_save :default_date
    belongs_to :commercial_document, :polymorphic => true
    belongs_to :target, :polymorphic => true
    has_many :credit_amounts, :extend => AmountsExtension, :class_name => 'Plutus::CreditAmount', :inverse_of => :entry
    has_many :debit_amounts, :extend => AmountsExtension, :class_name => 'Plutus::DebitAmount', :inverse_of => :entry
    has_many :credit_accounts, :through => :credit_amounts, :source => :account, :class_name => 'Plutus::Account'
    has_many :debit_accounts, :through => :debit_amounts, :source => :account, :class_name => 'Plutus::Account'

    validates_presence_of :description
    validate :has_credit_amounts?
    validate :has_debit_amounts?
    validate :amounts_cancel?

    if Plutus.enable_tenancy
      belongs_to :tenant, class_name: Plutus.tenant_class
    end

    # Support construction using 'credits' and 'debits' keys
    accepts_nested_attributes_for :credit_amounts, :debit_amounts, allow_destroy: true
    alias_method :credits=, :credit_amounts_attributes=
    alias_method :debits=, :debit_amounts_attributes=

    # Support the deprecated .build method
    def self.build(hash)
      ActiveSupport::Deprecation.warn('Plutus::Transaction.build() is deprecated (use new instead)', caller)
      new(hash)
    end

    def initialize(*args)
      super
    end

    private
      def default_date
        self.date ||= Date.today
      end

      def has_credit_amounts?
        errors[:base] << I18n.t("plutus.at_least_one_credit_amount") if self.credit_amounts.blank?
      end

      def has_debit_amounts?
        errors[:base] << I18n.t("plutus.at_least_one_debit_amount") if self.debit_amounts.blank?
      end

      def amounts_cancel?
        errors[:base] << I18n.t("plutus.amounts_are_not_equal") if credit_amounts.balance_for_new_record != debit_amounts.balance_for_new_record
      end
  end
end
