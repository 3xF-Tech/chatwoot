# frozen_string_literal: true

class OpportunityPolicy < ApplicationPolicy
  def index?
    true
  end

  def search?
    true
  end

  def show?
    true
  end

  def stats?
    true
  end

  def create?
    true
  end

  def update?
    owner? || @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end

  def move_stage?
    update?
  end

  def mark_won?
    update?
  end

  def mark_lost?
    update?
  end

  def link_conversation?
    true
  end

  def unlink_conversation?
    true
  end

  private

  def owner?
    @record.owner_id == @user.id
  end

  class Scope
    attr_reader :user, :account_user, :scope

    def initialize(context, scope)
      @user = context.user
      @account_user = context.account_user
      @scope = scope
    end

    def resolve
      # All agents can see all opportunities in their account
      scope.all
    end
  end
end
