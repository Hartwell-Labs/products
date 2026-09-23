#!/usr/bin/env ruby
# frozen_string_literal: true

# Seed MongoDB Atlas with the Hartwell Labs products catalog.
# Idempotent: replaces the products collection with data/products.json.

require "json"
require "time"
require "mongo"
require_relative "../lib/products_catalog"

catalog = ProductsCatalog.load
abort "no products in data/products.json" if catalog[:products].empty?

client = Mongo::Client.new(ENV.fetch("MONGODB_URI"), server_api: { version: 1 })
coll = client.use(ENV.fetch("MONGODB_DB", "hartwell"))[ENV.fetch("MONGODB_COLLECTION", "products")]

now = Time.now.utc.iso8601
docs = catalog[:products].map { |p| p.merge("updated_at" => now) }

coll.delete_many({})
result = coll.insert_many(docs)
idx = coll.indexes.create_one({ slug: 1 }, unique: true) rescue nil

puts "seeded #{result.inserted_ids.size} products into #{coll.database.name}.#{coll.name} (unique index on slug: #{idx ? "created" : "exists"})"
client.close
