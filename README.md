# README

This is a basic server that hosts and coordinates Tech & Check's media scraper gems ([zorki](https://www.github.com/cguess/zorki), [forki](https://github.com/oneroyalace/forki), and [YoutubeArchiver](https://github.com/TechAndCheck/YoutubeArchiver) 
The scrapers are kept separate from Zenodotus, because the IP addresses of traditional hosting servers (where Zenodotus resides), may be blocked by the media sources we're trying to scrape. The Hypatia server can be hosted on a Raspberry Pi in your house or something.

## Setup:
1. Make sure you have Ruby 3.1.0 installed (may work on older version, haven't checked)
1. Grab this repo
1. `$ bundle install` to get all the gems in
1. Install Redis and make sure it's running using `$ redis-server` if running locally.
1. Turn on Sidekiq (which is install with the gems) by running `$ bundle exec sidekiq` in the project directory.
1. Create `config/application.yml` and create `INSTAGRAM_USER_NAME`, `INSTAGRAM_PASSWORD`.
1. Run `$ rails secret` and then add a variable `secret_key_base` to `config/application.yml`
1. `$ rails db:migrate` to setup the database (this uses SQLite so there's no need for Postgres or MySQL or anything)
1. Setup Selenium standalone server
	1. Download the "Selenium Server (Grid)" JAR package at https://www.selenium.dev/downloads/
	1. Save it to the folder of this package
	1. Test that it works by running `java -jar ./selenium-server-4.2.1.jar standalone` (note the actual version you downloaded)
1. Download Firefox's geckodriver and Chrome's chromedriver and save both in a PATH-listed folder. Give the user and system execute privileges for both drivers. 
1. Ensure that Google Chrome and Mozilla Firefox are installed
1. Generate an API key for security purposes in the Rails console
	1. `$ rails c`
	1. `Setting.generate_auth_key`
	1. Note this key in a password manager or something, you'll need it later. It's currently stored in the database (this should be hashed at some point, but meh for now)
	1. `exit`
1. Start up the Selenium server `java -jar ./selenium-server-4.2.1.jar standalone` in a separate CLI pane
1. Start up the server `$ rails s`

If your auth key gets compromised just reload it using the same steps above.

## Use

This service allows you to pass in an Instagram, Facebook, or YouTube URL and it'll return a JSON structure with everything you'd want, including the images as base64 encoded fields.

The only endpoint is `GET /scrape` which access two parameters:
1. `url`: the url of the Instagram post
1. `auth_key`: this is generated in the setup

## Retries
Legend has it that external data sources and APIs fail every now and then. Hypatia implements retries through Sidekiq to manage these issues. Below, we list some scenarios that hopefully illuminate when Hypatia's retry system will/won't kick in.

### Scenario 1

**A scrape job succeeds!**

Sidekiq should dequeue the job so it isn't retried. Hypatia should send a POST request to Zenodotus containing the scraped post data.  

### Scenario 2

**A scrape job fails with an error that isn’t retryable (e.g. an `InvalidUrlError`)** 

Sidekiq should dequeue the job so it isn't retried. Hypatia should let Zenodotus know that the scrape request has failed.

### Scenario 3

**A scrape job that has failed and been re-queued `max_retries` times fails again with a `RetryableError`** 

Sidekiq should dequeue the job so it isn't retried, and Hypatia should let Zenodotus know that the scrape request has failed.

### Scenario 4

**A scrape job that has failed and been re-queued 0≤n<`max_retries` times fails with a `RetryableError`**

Sidekiq should re-queue the job so it's retried. If the job subsequently succeeds, Hypatia should follow the scenario 1 playbook. If the job subsequently fails, Hypatia should run through the scenario 2 or scenario 3 playbook. 

### Retry implementation notes
A few of the individual scraper gems implement their own retry logic. This makes tests, which don't engage ActiveJob/Sidekiq right now, more resillient. In the future, we can probably just force test to use ActiveJob/Sidekiq and move all retry logic to Hypatia.

## Development

Follow the same steps to set up and if you want to run tests it's done by `rails t`

## TODO

- [] Use a hash for the auth key instead of the key itself for comparison
- [] Allow the requests to be IP limited
