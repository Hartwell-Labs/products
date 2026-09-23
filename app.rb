#!/usr/bin/env ruby
# frozen_string_literal: true

# Hartwell Labs — Products Registry API
# Minimal REST API (Sinatra) backed by MongoDB Atlas.
# Lists Hartwell Labs products: source repos + packages wherever they live.

require "sinatra"
require "json"
require "mongo"

set :bind, "0.0.0.0"
set :port, ENV.fetch("PORT", 4576).to_i
set :show_exceptions, false
set :raise_errors, false

MONGODB_DB = ENV.fetch("MONGODB_DB", "hartwell")
MONGODB_COLLECTION = ENV.fetch("MONGODB_COLLECTION", "products")

def mongo_client
  @mongo_client ||= Mongo::Client.new(
    ENV.fetch("MONGODB_URI"),
    server_api: { version: 1 }
  )
end

def products_collection
  mongo_client.use(MONGODB_DB)[MONGODB_COLLECTION]
end

# ----- helpers -----------------------------------------------------------

def public_product(doc)
  {
    slug:        doc["slug"],
    name:        doc["name"],
    tagline:     doc["tagline"],
    description: doc["description"],
    language:    doc["language"],
    license:     doc["license"],
    status:      doc["status"],
    repo:        doc["repo"],
    homepage:    doc["homepage"],
    topics:      doc["topics"] || [],
    packages:    doc["packages"] || [],
    containers:  doc["containers"] || [],
    updated_at:  doc["updated_at"]
  }
end

def json_response(payload, status = 200)
  content_type :json
  status status
  JSON.pretty_generate(payload)
end

def error_payload(code, message)
  { error: { code: code, message: message } }
end

# ----- routes ------------------------------------------------------------

get "/" do
  json_response(
    name:        "Hartwell Labs — Products Registry",
    description: "Machine-readable index of Hartwell Labs open-source products: repos + packages wherever they are published.",
    version:     "1.0.0",
    org: {
      website: "https://hartwell-labs.github.io",
      github:  "https://github.com/Hartwell-Labs"
    },
    endpoints: {
      "GET /"            => "this document",
      "GET /health"      => "liveness + DB connectivity check",
      "GET /products"    => "list all products (supports ?registry=pypi&lang=rust)",
      "GET /products/:slug" => "single product by slug"
    }
  )
end

get "/health" do
  begin
    mongo_client.database.command(ping: 1)
    json_response(status: "ok", database: "connected", time: Time.now.utc.iso8601)
  rescue Mongo::Error => e
    json_response(error_payload("db_unreachable", e.message), 503)
  end
end

get "/products" do
  filter = {}
  filter["language"] = Regexp.new("^#{Regexp.escape(params["lang"])}$", Regexp::IGNORECASE) if params["lang"]
  if params["registry"]
    registry = params["registry"].downcase
    filter["$or"] = [{ "packages.registry" => registry }, { "containers.registry" => registry }]
  end
  filter["status"] = "active" unless params["all"] == "true"

  begin
    docs = products_collection.find(filter).sort(slug: 1).to_a
    json_response(
      count: docs.size,
      filters_used: params.reject { |k, _| k.empty? },
      products: docs.map { |d| public_product(d) }
    )
  rescue Mongo::Error => e
    json_response(error_payload("db_error", e.message), 503)
  end
end

get "/products/:slug" do
  begin
    doc = products_collection.find(slug: params["slug"]).first
    halt 404, json_response(error_payload("not_found", "no product with slug '#{params["slug"]}'")) unless doc
    json_response(public_product(doc))
  rescue Mongo::Error => e
    json_response(error_payload("db_error", e.message), 503)
  end
end

not_found do
  content_type :json
  JSON.pretty_generate(error_payload("not_found", "unknown route"))
end

error do
  content_type :json
  JSON.pretty_generate(error_payload("internal_error", env["sinatra.error"].message))
end
