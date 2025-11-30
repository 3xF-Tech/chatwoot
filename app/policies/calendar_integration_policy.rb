# frozen_string_literal: true

class CalendarIntegrationPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record_belongs_to_user?
  end

  def auth_url?
    true
  end

  def oauth_callback?
    true
  end

  def update?
    record_belongs_to_user?
  end

  def destroy?
    record_belongs_to_user?
  end

  def sync?
    record_belongs_to_user?
  end

  def calendars?
    record_belongs_to_user?
  end

  private

  def record_belongs_to_user?
    @record.account_id == @account_user.account_id && @record.user_id == @user.id
  end

  class Scope
    attr_reader :user, :account_user, :scope

    def initialize(account_user, scope)
      @account_user = account_user
      @user = account_user.user
      @scope = scope
    end

    def resolve
      scope.where(account_id: @account_user.account_id, user_id: @user.id)
    end
  end
end
