module Qernel
  # Wraps around a subhash from the regional dataset. The regional dataset is
  # immutable; the ObjectDataset provides the ability to extend the the regional
  # dataset with values appropriate for a particular scenario.
  class ObjectDataset
    # Public: Create a new ObjectDataset, using the given +parent+ hash as an
    # (immutable) base.
    #
    # Returns an ObjectDataset.
    def initialize(parent)
      @parent = parent || {}
      @data   = {}
    end

    # Public: Determines if the given +key+ has a corresponding value in the
    # dataset.
    #
    # Returns true or false.
    def has_key?(key)
      @parent.key?(key) || @data.key?(key)
    end

    alias_method :key?, :has_key?

    # Public: Retrieves a value from the dataset.
    #
    # Returns the stored value, or nil if none is present.
    def get(key)
      @data.key?(key) ? @data[key] : @parent[key]
    end

    alias_method :[], :get

    # Public: Sets a +value+ in the dataset, associated with with given +key+.
    #
    # Returns the value.
    def set(key, value)
      @data[key.to_sym] = value
    end

    alias_method :[]=, :set
  end # ObjectDataset
end # Qernel
