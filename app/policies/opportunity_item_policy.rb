# frozen_string_literal: true

class OpportunityItemPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    opportunity_owner? || @account_user.administrator?
  end

  def update?
    opportunity_owner? || @account_user.administrator?
  end

  def destroy?
    opportunity_owner? || @account_user.administrator?
  end

  def reorder?
    opportunity_owner? || @account_user.administrator?
  end

  private

  def opportunity_owner?
    @record.opportunity.owner_id == @user.id
  end
end
