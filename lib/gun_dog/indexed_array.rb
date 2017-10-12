module GunDog
  class IndexedArray < Array
    attr_reader :lut

    def initialize(*args)
      super(args)
      @lut = {}
    end

    def <<(obj)
      super(obj)
      @lut[obj.object_id] = length
      obj
    end

    def index_of_object(obj)
      @lut.fetch(obj.object_id)
    end

    def find_object(obj)
      at(index_of_object(obj))
    end
  end
end
