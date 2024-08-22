# Lernen

> a simple automata learning library.

## Usage

```ruby
require "lernen"

alphabet = %w[0 1]
sul = Lernen::SUL.from_block { |inputs| inputs.count { _1 == "1" } % 4 == 3 }
oracle = Lernen::BreadthFirstExplorationOracle.new(alphabet, sul)

dfa = Lernen::LStar.learn(alphabet, sul, oracle, automaton_type: :dfa)
# => Lernen::DFA.new(
#      0,
#      Set[3],
#      {
#        [0, "0"] => 0,
#        [0, "1"] => 1,
#        [1, "0"] => 1,
#        [1, "1"] => 2,
#        [2, "0"] => 2,
#        [2, "1"] => 3,
#        [3, "0"] => 3,
#        [3, "1"] => 0
#      }
#    )
```

## License

[MIT](https://opensource.org/license/MIT)

2024 (C) Hiroya Fujinami
