require "capybara/dsl"
require "selenium-webdriver"

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument("--window-size=1400,1400")
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")
options.add_argument("--user-data-dir=/tmp/tarun")

Capybara.register_driver :chrome do |app|
  client = Selenium::WebDriver::Remote::Http::Default.new
  client.read_timeout = 10
  Capybara::Selenium::Driver.new(app, browser: :chrome, url: "http://localhost:4444/wd/hub", capabilities: options, http_client: client)
end

Capybara.default_max_wait_time = 7
Capybara.threadsafe = true
Capybara.reuse_server = true
Capybara.default_driver = :chrome
