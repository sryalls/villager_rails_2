module CsrfHelper
  def inject_csrf_token
    page.execute_script <<-JS
      var meta = document.createElement('meta');
      meta.name = "csrf-token";
      meta.content = "#{SecureRandom.base64(32)}";
      document.getElementsByTagName('head')[0].appendChild(meta);
    JS
  end
end

RSpec.configure do |config|
  config.include CsrfHelper, type: :feature
end
