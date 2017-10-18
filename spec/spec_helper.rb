require "bundler/setup"
require "gun_dog"
require "active_record"

ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: ':memory:'
)

require "tester"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each, database: true) do
    ActiveRecord::Base.connection.create_table :test_records do |t|
      t.integer :foo
      t.string :bar
    end
  end

  config.after(:each, database: true) do
    ActiveRecord::Base.connection.drop_table :test_records
  end
end
