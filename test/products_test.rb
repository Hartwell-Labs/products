#!/usr/bin/env ruby
# frozen_string_literal: true

# Tests for the Products Catalog: validates data/products.json shape
# and exercises the live API when PRODUCTS_API_URL is reachable.

require "minitest/autorun"
require "json"
require "net/http"
require_relative "../lib/products_catalog"

class CatalogDataTest < Minitest::Test
  def setup
    @catalog = ProductsCatalog.load
    @products = @catalog[:products]
  end

  def test_org_block_present
    assert_equal "Hartwell Labs", @catalog[:org]["name"]
    assert @catalog[:org]["website"]
  end

  def test_all_three_flagships_present
    slugs = @products.map { |p| p["slug"] }
    %w[talus-process-monitor externum aurora-os].each do |s|
      assert_includes slugs, s
    end
  end

  def test_every_product_has_required_fields
    @products.each do |p|
      %w[slug name tagline description repo status].each do |field|
        assert p[field], "#{p["slug"]} missing #{field}"
      end
      assert p["repo"].start_with?("https://github.com/"), "#{p["slug"]} bad repo URL"
    end
  end

  def test_packages_reference_valid_registries
    known = %w[pypi npm github-packages github-releases cargo]
    @products.flat_map { |p| p["packages"] }.each do |pkg|
      assert_includes known, pkg["registry"], "unknown registry #{pkg["registry"]}"
    end
  end
end

class LiveApiTest < Minitest::Test
  def api_available?
    @base = ENV["PRODUCTS_API_URL"]
    return false unless @base
    Net::HTTP.get_response(URI("#{@base}/health")).code.to_i < 500
  rescue StandardError
    false
  end

  def test_products_endpoint_returns_json
    skip "no live API (set PRODUCTS_API_URL)" unless api_available?
    res = Net::HTTP.get_response(URI("#{@base}/products"))
    assert_equal 200, res.code.to_i
    body = JSON.parse(res.body)
    assert_operator body["count"], :>=, 3
  end
end
