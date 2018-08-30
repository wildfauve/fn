module Fn

  class Fn

    extend Dry::Monads::Try::Mixin
    extend Dry::Monads::Result::Mixin

    class << self

      # Common curried map higher order fn
      # > map.(-> i { i.to_s } ).([1,2,3])
      def map
        ->(f, enum) { enum.map {|e| f.(e) } }.curry
      end

      def fmap
        ->(f, enum) { enum.flat_map {|e| f.(e) } }.curry
      end

      def sequence
        ->(fs, i) { fs.inject([]) { |r, f| r << f.(i) } }.curry
      end

      def inject
        -> j, f, xs { xs.inject(j) {|r, x| f.(r).(x) } }.curry
      end

      def group_by
        -> f, xs { xs.group_by { |x| f.(x) } }.curry
      end

      def merge
        -> to, with { to.merge(with) }.curry
      end

      # Curryed fn that removes elements from a collection where f.(e) is true
      def remove
        ->(f, enum) { enum.delete_if {|e| f.(e) } }.curry
      end

      # finds the first element in a collecton where f.(e) is true
      def find
        ->(f, enum) { enum.find { |e| f.(e) } }.curry
      end

      def select
        ->(f, enum) { enum.select { |e| f.(e) } }.curry
      end

      def replace
        ->(r, with, s) { s.gsub(r,with)  }.curry
      end

      def join
        -> sep, i { i.join(sep) }.curry
      end

      def split
        -> sep, i { i.split(sep) }.curry
      end

      def max
        ->(f, enum) { f.(enum).max }.curry
      end

      def all?
        ->(f, enum) { enum.all? { |e| f.(e) } }.curry
      end

      def any?
        ->(f, enum) { enum.any? { |e| f.(e) } }.curry
      end

      def when_nil?
        ->(i) { i.nil? }
      end

      # lifts the value, otherwise returns nil
      def lift
        ->(f, with, i) { f.(i) ? with.(i) : nil }.curry
      end

      # Takes a structure (like a Monad), an OK test fn, and a fn to extract when OK
      # Returns the result of f, otherwise nil
      # > lift_value.(maybe_value_ok, maybe_value),
      def lift_value
        ->(value_type, f) { Fn.lift.(value_type, f) }.curry
      end

      def identity
        ->(i) { i }
      end

      def method
        -> m, obj { obj.send(m) }.curry
      end

      # The little Either Functor
      # returns either the result of f || g by applying the test <t>.
      # either.(maybe_value_ok, identity, maybe_value).(Success(1))  => 1
      def either
        ->(t, f_ok, f_fail, value) { t.(value) ? f_ok.(value) : f_fail.(value) }.curry
      end

      # f: a test fn to apply to the enum resulting from applying the tests; e.g. Fn.all? (and) or Fn.any? (or)
      # ts: [test_fn]; each test is called with (v)
      # v:  the test context
      def tests
        -> f, ts, v {
          Fn.compose.(
            f.(Fn.identity),
            Fn.map.(-> t { t.(v) } )
          ).(ts)
        }.curry
      end

      # the famous compose
      # Applies from right to left, taking the result of 1 fn and injecting into the next
      # No Monads tho!
      # compose.(-> n { n + 1}, -> n { n * 2 }).(10)
      def compose
        ->(*fns) { fns.reduce { |f, g| lambda { |x| f.(g.(x)) } } }
      end

      # Monadic Compose, using flat_map
      # The result of a fn must return an Either.
      # fmap_compose.([->(v) { M.Success(v + 1) }, ->(v) { M.Success(v + 10) }]).(M.Success(0))
      def fmap_compose
        ->(fns, value) {
          fns.inject(value) {|result, fn| result.success? ? result.fmap(fn).value_or : result}
        }.curry
      end


      # Apply that takes a function and an enum and applies the fn to the entire enum
      # Works with methods like #join, #split
      def apply
        ->(f, enum) { f.(enum)}.curry
      end

      def equality
        ->( field, value, i ) { i[field] == value }.curry
      end

      def include
        -> xs, v { xs.include?(v) }.curry
      end

      def linclusion
        ->( field, value, i ) { i[field].include?(value) }.curry
      end

      # takes a regex and applies it to a value
      def match
        ->(r, i) { i.match(r) }.curry
      end

      def take
        ->(f, i) { f.(i) unless i.nil? }.curry
      end

      # right at; takes the key/index and applies the enum
      def at
        ->(x, i) { i[x] unless i.nil? }.curry
      end

      # left at; takes the enum and applies the key/index to it.
      def lat
        ->(i, x) { i[x] }.curry
      end

      def all_keys
        -> h { h.flat_map { |k, v| [k] + (v.is_a?(Hash) ? all_keys.(v) : [v]) } }
      end

      def coherse
        -> f, xs { map.(-> x { x.send(f) } ).(xs) }.curry
      end

      def max_int
        -> limit, i { i > limit ? limit : i }.curry
      end

      # Takes a structure (like a Monad), an OK test fn, and a fn to extract when OK
      # Returns the result of f, otherwise nil
      # > lift_value.(maybe_value_ok?, maybe_value),
      def lift_monad
        -> value { maybe_value_ok?.(value) ? maybe_value.(value) : maybe_failure.(value) }
      end


      def failure
        -> v { Failure(v) }
      end

      def success
        -> v { Success(v) }
      end

      def maybe_value_ok?
        ->(v) { v.success? }
      end

      def maybe_value_fail?
        -> v { v.failure }
      end

      def maybe_value
        ->(v) { v.value_or }
      end

      def maybe_failure
        ->(v) { v.failure }
      end

      def status_value_ok?
        ->(v) { v.status == :ok }
      end

      def ctx_value
        ->(v) { v.context }
      end

      def method_caller
        -> obj, method, v { obj.send(method, v) }.curry
      end

      def break_point
        -> args { binding.pry }
      end

      def empty?
        -> xs { xs.empty? }
      end

      def present?
        -> x { x.present? }
      end

      def remove_nil
        Fn.remove.(->(i) { i.nil? } )
      end

      # f: add fn
      # g: remove fn
      # prev state
      # this state
      def change_set_fn
        -> f, g, prev, this {
          f.(Set.new(this) - Set.new(prev))
          g.(Set.new(prev) - Set.new(this))
        }.curry
      end

      def wrapper(f)
        -> { f }
      end

      # Provide a delimiter (such as "|")
      # Returns a curryed fn that takes 2 params:
      # @param f, a function that extracts a property from a map
      # @param enum, the map
      def delimiter_tokeniser
        -> delimiter, f, enum { f.(enum).join(delimiter) }.curry
      end

      def detokeniser(delimiter)
        ->(str) { str.split(delimiter) }.curry
      end

      def maybe_pipeline
        ->(pipeline) {
          Success(lambda do |value|
            pipeline.inject(value) do |result, fn|
              result.success? ? result.fmap(fn).value_or : result
            end
          end)
        }
      end


    end # class Self

  end  # class

end  # module
