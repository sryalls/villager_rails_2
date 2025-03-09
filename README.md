# Villager

This is a new Rails application.

## Requirements

- Ruby 3.2.0
- Rails (latest stable)

## Installation

1. Ensure you have Ruby and Rails installed:

    ```sh
    ruby -v
    rails -v
    ```

2. Install Ruby 3.2.0 if not already installed:

    ```sh
    rbenv install 3.2.0
    rbenv global 3.2.0
    ```

3. Install Rails if not already installed:

    ```sh
    gem install rails
    ```

4. Create a new Rails application:

    ```sh
    rails new villager -d postgresql
    cd villager
    ```

5. Setup the database:

    ```sh
    rails db:create
    rails db:migrate
    ```

6. Start the Rails server:

    ```sh
    rails server
    ```

    Open your web browser and go to `http://localhost:3000`.

7. for testing, ensure that the correct version of chromedriver is installed and in the correct place: 
```
wget https://storage.googleapis.com/chrome-for-testing-public/133.0.6943.141/linux64/chromedriver-linux64.zip

mv chromedriver-linux64/chromedriver bin/chromedriver-linux64/chromedriver
```