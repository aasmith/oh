module Ohbjects
  class AccountBuilder
    extend Buildable

    # Not building anything real for now.
    builds "//data/account[isVirtual='true']"

    class << self
      def build(fragment)
        account = Account.new

        account.id = fragment.at("accountId").text
        account.name = fragment.at("accountName").text
        account.virtual = fragment.at("isVirtual").text =~ /true/
        account.display_id = fragment.at("account").text

        account
      end
    end
  end

  class Account
    attr_accessor :id, :display_id, :name, :virtual

    def virtual?
      virtual
    end
  end
end
