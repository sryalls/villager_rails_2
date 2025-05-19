# Villager

Villager is a settlement construction game built on Ruby on Rails.

## Requirements

- Docker
- Docker Compose

## Installation

1. Ensure you have Docker and Docker Compose installed.

2. Clone the repository and navigate to the project directory.

3. Build and start the application using Docker Compose:

    ```sh
    docker compose up --build
    ```

    This will start the Rails app, Sidekiq, and all required services.

4. Open your web browser and go to `http://localhost:3000`.

## Running Rails and Sidekiq

- Rails server and Sidekiq are both managed by Docker Compose.
- No need to run them manually.

## Testing

For testing, ensure that the correct version of chromedriver is installed and available in your Docker environment. You can add the following to your Dockerfile or run inside the container:

```sh
wget https://storage.googleapis.com/chrome-for-testing-public/133.0.6943.141/linux64/chromedriver-linux64.zip
unzip chromedriver-linux64.zip
mv chromedriver-linux64/chromedriver /usr/local/bin/chromedriver
chmod +x /usr/local/bin/chromedriver
```

## Docker

All services (Rails, Sidekiq, database, etc.) are orchestrated via Docker Compose. See `docker-compose.yml` for configuration details.
