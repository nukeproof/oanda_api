require 'spec_helper'

describe "OandaAPI::Utils" do
  describe ".camelize" do
    it "puts humps on a string starting out low" do
      expect(OandaAPI::Utils.camelize("ruby_is_awesome")).to eq("rubyIsAwesome")
    end

    it "works with already camelized" do
      expect(OandaAPI::Utils.camelize("imACamel")).to eq("imACamel")
    end

    it "works with numbers" do
      expect(OandaAPI::Utils.camelize("a_number_1_concern")).to eq("aNumber1Concern")
    end

    it "works with symbols" do
      expect(OandaAPI::Utils.camelize(:ugly_symbol)).to eq("uglySymbol")
    end

    it "turns nil to empty" do
      expect(OandaAPI::Utils.camelize(nil)).to eq("")
    end

    it "ignores empty" do
      expect(OandaAPI::Utils.camelize("")).to eq("")
    end
  end

  describe '.classify' do
    it 'return capitalized one word text' do
      expect(OandaAPI::Utils.classify('ruby')).to eq("Ruby")
    end
    it 'capitalizes first word and each word after _ sign' do
      expect(OandaAPI::Utils.classify('this_is_ruby')).to eq("ThisIsRuby")
    end
    it 'downcase letters inside the word (except first letter)' do
      expect(OandaAPI::Utils.classify('RUBY')).to eq("Ruby")
    end
  end

  describe ".pluralize" do
    it "naively adds an s to the end of strings" do
      expect(OandaAPI::Utils.pluralize("thing")).to eq("things")
    end

    it "doesn't add an s if it's already there" do
      expect(OandaAPI::Utils.pluralize("things")).to eq("things")
    end

    it "turns nil to empty" do
      expect(OandaAPI::Utils.pluralize(nil)).to eq("")
    end

    it "ignores empty" do
      expect(OandaAPI::Utils.pluralize("")).to eq("")
    end
  end

  describe ".singularize" do
    it "naively removes trailing s" do
      expect(OandaAPI::Utils.singularize("things")).to eq("thing")
    end

    it "turns nil to empty" do
      expect(OandaAPI::Utils.singularize(nil)).to eq("")
    end

    it "ignores empty" do
      expect(OandaAPI::Utils.singularize("")).to eq("")
    end
  end

  describe ".rubyize_keys" do
    it "converts all keys in a hash into snake_cased_symbols, " do
      hash            = { "a" => "a", "b" => [{ "a" => "a" }], :c => "c", "camelCase" => "" }
      symbolized_hash = { :a  => "a", :b  => [{ :a  => "a" }], :c => "c", :camel_case => "" }
      expect(OandaAPI::Utils.rubyize_keys(hash)).to eq(symbolized_hash)
    end
  end

  describe ".underscore" do
    it "converts a string to snake_case" do
      expect(OandaAPI::Utils.underscore("camelCase-dashedTLA")).to eq("camel_case_dashed_tla")
    end

    it "turns nil to empty" do
      expect(OandaAPI::Utils.underscore(nil)).to eq("")
    end

    it "ignores empty" do
      expect(OandaAPI::Utils.underscore("")).to eq("")
    end
  end

  describe ".transform_hash_keys" do
    it "yields every key in a nested hash" do
      hash = { "a" => "a", :b => [{ :c => "c" }], :d => "d" }
      expect { |b| OandaAPI::Utils.transform_hash_keys(hash, &b) }.to yield_successive_args("a", :b, :c, :d)
    end

    it "replaces hash keys with the yielded return values" do
      hash             = { "a" => "a", "b" => [{ "c" => "c" }], "d" => "d" }
      transformed_hash = { :a  => "a", :b  => [{ :c  => "c" }], :d  => "d" }
      expect(OandaAPI::Utils.transform_hash_keys(hash) { |key| key.to_sym }).to eq(transformed_hash)
    end
  end

  describe ".transform_hash_values" do
    it "yields every scalar key,value pair in a nested hash" do
      hash = { "a" => "a", :b => [{ :c => "c" }], :d => "d" }
      expect { |b| OandaAPI::Utils.transform_hash_values(hash, &b) }.to yield_successive_args(["a", "a"], [:c, "c"], [:d, "d"])
    end

    it "replaces scalar hash element values with the yielded return values" do
      hash             = { :a => "a", :b => [{ :c => "c" }], :d => "d" }
      transformed_hash = { :a => :a,  :b => [{ :c => :c  }], :d => :d  }
      expect(OandaAPI::Utils.transform_hash_values(hash) { |_key, value| value.to_sym }).to eq(transformed_hash)
    end
  end
end
