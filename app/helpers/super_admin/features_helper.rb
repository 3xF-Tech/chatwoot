module SuperAdmin::FeaturesHelper
  def self.available_features
    YAML.load(ERB.new(Rails.root.join('app/helpers/super_admin/features.yml').read).result).with_indifferent_access
  end

  def self.plan_details
    plan = ChatwootHub.pricing_plan

    # 3xF.Tech: Custom message for our fork
    if plan == 'enterprise'
      "You are on the <span class='font-semibold'>3xF.Tech Enterprise</span> edition " \
        "with <span class='font-semibold'>unlimited agents</span>."
    elsif plan == 'premium'
      quantity = ChatwootHub.pricing_plan_quantity
      "You are currently on the <span class='font-semibold'>#{plan}</span> plan " \
        "with <span class='font-semibold'>#{quantity} agents</span>."
    else
      "You are currently on the <span class='font-semibold'>#{plan}</span> edition plan."
    end
  end
end
