# frozen_string_literal: true

# Shared loader for data/products.json (used by seed script and tests).

module ProductsCatalog
  def self.load(path = nil)
    path ||= File.expand_path("../data/products.json", __dir__)
    raw = JSON.parse(File.read(path))
    {
      org: raw["org"],
      products: raw["products"] || []
    }
  end
end

require "json"
