ActionDispatch::Callbacks.after do
  # Reload the factories
  return unless Rails.env.development? || Rails.env.test?

  if FactoryBot.factories.any? # first init will load factories, this should only run on subsequent reloads
    FactoryBot.factories.clear
    FactoryBot.find_definitions
  end
end
