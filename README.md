# Villager

Villager is a settlment constrcution game built on Ruby on Rails

## Requirements

- Ruby 3.2.0
- Rails 8.0.1

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

4. Setup the database:

    ```sh
    rails db:create
    rails db:schema:load
    ```

5. Start the Rails server:
    ```sh
    rails server
    ```

    Open your web browser and go to `http://localhost:3000`.


## Testing
for testing, ensure that the correct version of chromedriver is installed and in the correct place: 
```
wget https://storage.googleapis.com/chrome-for-testing-public/133.0.6943.141/linux64/chromedriver-linux64.zip

mv chromedriver-linux64/chromedriver bin/chromedriver-linux64/chromedriver
```