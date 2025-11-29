# frozen_string_literal: true

class OpportunityActivityPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def update?
    owner? || @account_user.administrator?
  end

  def destroy?
    owner? || @account_user.administrator?
  end

  def complete?
    owner? || @account_user.administrator?
  end

  private

  def owner?
    @record.user_id == @user.id
  end
end
