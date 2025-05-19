FROM ruby:3.2

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs yarn

# Set working directory
WORKDIR /rails

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the rest of the app
COPY . .

# Set development environment
ENV RAILS_ENV=development

# Expose port for Rails server
EXPOSE 3000

# Default command (can be overridden by docker-compose)
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]