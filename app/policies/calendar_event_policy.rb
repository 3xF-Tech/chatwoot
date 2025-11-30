# frozen_string_literal: true

class CalendarEventPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record_accessible?
  end

  def create?
    true
  end

  def update?
    record_accessible?
  end

  def destroy?
    record_accessible?
  end

  def upcoming?
    true
  end

  def by_link?
    true
  end

  private

  def record_accessible?
    return true if @record.account_id == @account_user.account_id

    false
  end

  class Scope
    attr_reader :user, :account_user, :scope

    def initialize(account_user, scope)
      @account_user = account_user
      @user = account_user.user
      @scope = scope
    end

    def resolve
      scope.where(account_id: @account_user.account_id)
    end
  end
end
