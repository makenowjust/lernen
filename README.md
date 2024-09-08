# Lernen

> an automata learning library written in Ruby.

## Short Introduction to Automata Learning and Lernen

**Automata learning** is a technique to *infer an [automaton](https://en.wikipedia.org/wiki/Automata_theory) from a program*.

Once getting an automaton from a program, we earn some benefits:

- **Visualization**: An automaton is a state-transition system, i.e., a labelled graph.
    Therefore, graph visualization tools such as [GraphViz](https://graphviz.org) and [Mermaid](https://mermaid.js.org) allow you to see the structure of the system at the ready.
- **Model checking**: An automaton is a model of the system.
    Model checking ensures some good properties about the system, e.g., that two different implementations of the system behave exactly the same.

**Lernen** is an automata learning library written in Ruby.
This library includes implementations of not only eminent automata learning algorithms such as Angluin's $L^\ast$ and $\textrm{Kearns-Vazirani}$ ($\textrm{KV}$), but also a modern algorithm such as $L^\\#$.
Also, this library supports inferring an automaton accepting a non-regular language, namely VPA (visibly pushdown automaton).

As case studies of the real-world applications of automata learning, we introduce two examples with Lernen.

### Case Study 1: `URI.parse` and `URI` Regexp ([`examples/uri_parse_regexp.rb`](./examples/uri_parse_regexp.rb))

URL validation is a common task in a Web application, and we can achieve this task by using `URI.parse`.
For example, the following method `valid_and_http_url?` checks whether or not a given string is valid as URI and its scheme is `http` or `https`.

```ruby
def valid_and_http_url?(string)
  uri = URI.parse(string)
  uri.scheme == "http" || uri.scheme == "https"
rescue URI::Error
  false
end
```

However, this method is *a bit inefficient* because it allocates a `URI` object for each call.

In Ruby's `uri` library, fortunately, we have the `URI::DEFAULT_PARSER.make_regexp` method to build a regexp pattern that matches valid URIs with given schemes.
Thus, we can rewrite the `valid_and_http_url?` method with using this.

```ruby
VALID_AND_HTTP_URL_REGEXP = /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/
def new_valid_and_http_url?(string)
  string.match?(VALID_AND_HTTP_URL_REGEXP)
end
```

Then, `new_valid_and_http_url?` avoids allocations.
The performance of the new one is better.

Now, we have a question: *Do these implementations behave exactly the same?*

It is a typical question appeared on refactoring a program, and Lernen and automata learning can give an answer for it.

First, we need to infer two automata from two validation methods.
That can be done by the following code.

```ruby
# `alphabet` is an array of pieces of words.
# Learning algorithm infers an automaton on this alphabet, so in this case,
# we specify some possible subwords in URLs to `alphabet`.
alphabet = %w[http https ftp example com foo 80 12 : / . ? = & # @ %]

# `oracle` specifies a kind of an equivalence oracle using on learning,
# and `oracle_params` is a paremeter object to it.
oracle = :random_word
oracle_params = { max_words: 2000 }.freeze

# Infer a automaton by calling the `Lernen.learn` method with the target program.

# `URI.parse` DFA:
uri_parse_dfa = Lernen.learn(alphabet:, oracle:, oracle_params:) do |word|
  # `word.join` is necessary because `word` is an array of `alphabet` elements.
  valid_and_http_url?(word.join)
end

# `URI` regexp DFA:
uri_regexp_dfa = Lernen.learn(alphabet:, oracle:, oracle_params:) do |word|
  new_valid_and_http_url?(word.join)
end
```

`uri_parse_dfa` and `uri_regexp_dfa` are `Lernen::Automaton::DFA` objects.
`DFA#to_mermaid` returns a [Mermaid](https://mermaid.js.org) diagram representation of the obtained DFA.

```ruby
uri_parse_dfa.to_mermaid
# => "flowchart TD\n" ...
uri_regexp_dfa.to_mermaid
# => "flowchart TD\n" ...
```

<details>
  <summary>Mermaid diagrams for <code>URI.parse</code> and <code>URI</code> regexp DFAs</summary>

  #### `URI.parse` DFA

  ```mermaid
  flowchart TD
    0((0))
    1((1))
    2((2))
    3(((3)))
    4(((4)))
    5(((5)))
    6((6))
    7(((7)))

    0 -- "'http'" --> 1
    0 -- "'https'" --> 1
    0 -- "'ftp'" --> 2
    0 -- "'example'" --> 2
    0 -- "'com'" --> 2
    0 -- "'foo'" --> 2
    0 -- "'80'" --> 2
    0 -- "'12'" --> 2
    0 -- "':'" --> 2
    0 -- "'/'" --> 2
    0 -- "'.'" --> 2
    0 -- "'?'" --> 2
    0 -- "'='" --> 2
    0 -- "'&'" --> 2
    0 -- "'#'" --> 2
    0 -- "'@'" --> 2
    0 -- "'%'" --> 2
    1 -- "'http'" --> 2
    1 -- "'https'" --> 2
    1 -- "'ftp'" --> 2
    1 -- "'example'" --> 2
    1 -- "'com'" --> 2
    1 -- "'foo'" --> 2
    1 -- "'80'" --> 2
    1 -- "'12'" --> 2
    1 -- "':'" --> 3
    1 -- "'/'" --> 2
    1 -- "'.'" --> 2
    1 -- "'?'" --> 2
    1 -- "'='" --> 2
    1 -- "'&'" --> 2
    1 -- "'#'" --> 2
    1 -- "'@'" --> 2
    1 -- "'%'" --> 2
    2 -- "'http'" --> 2
    2 -- "'https'" --> 2
    2 -- "'ftp'" --> 2
    2 -- "'example'" --> 2
    2 -- "'com'" --> 2
    2 -- "'foo'" --> 2
    2 -- "'80'" --> 2
    2 -- "'12'" --> 2
    2 -- "':'" --> 2
    2 -- "'/'" --> 2
    2 -- "'.'" --> 2
    2 -- "'?'" --> 2
    2 -- "'='" --> 2
    2 -- "'&'" --> 2
    2 -- "'#'" --> 2
    2 -- "'@'" --> 2
    2 -- "'%'" --> 2
    3 -- "'http'" --> 3
    3 -- "'https'" --> 3
    3 -- "'ftp'" --> 3
    3 -- "'example'" --> 3
    3 -- "'com'" --> 3
    3 -- "'foo'" --> 3
    3 -- "'80'" --> 3
    3 -- "'12'" --> 3
    3 -- "':'" --> 3
    3 -- "'/'" --> 3
    3 -- "'.'" --> 3
    3 -- "'?'" --> 4
    3 -- "'='" --> 3
    3 -- "'&'" --> 3
    3 -- "'#'" --> 5
    3 -- "'@'" --> 3
    3 -- "'%'" --> 6
    4 -- "'http'" --> 4
    4 -- "'https'" --> 4
    4 -- "'ftp'" --> 4
    4 -- "'example'" --> 4
    4 -- "'com'" --> 4
    4 -- "'foo'" --> 4
    4 -- "'80'" --> 4
    4 -- "'12'" --> 4
    4 -- "':'" --> 4
    4 -- "'/'" --> 4
    4 -- "'.'" --> 4
    4 -- "'?'" --> 4
    4 -- "'='" --> 4
    4 -- "'&'" --> 4
    4 -- "'#'" --> 5
    4 -- "'@'" --> 4
    4 -- "'%'" --> 7
    5 -- "'http'" --> 5
    5 -- "'https'" --> 5
    5 -- "'ftp'" --> 5
    5 -- "'example'" --> 5
    5 -- "'com'" --> 5
    5 -- "'foo'" --> 5
    5 -- "'80'" --> 5
    5 -- "'12'" --> 5
    5 -- "':'" --> 5
    5 -- "'/'" --> 5
    5 -- "'.'" --> 5
    5 -- "'?'" --> 5
    5 -- "'='" --> 5
    5 -- "'&'" --> 5
    5 -- "'#'" --> 2
    5 -- "'@'" --> 5
    5 -- "'%'" --> 6
    6 -- "'http'" --> 2
    6 -- "'https'" --> 2
    6 -- "'ftp'" --> 2
    6 -- "'example'" --> 2
    6 -- "'com'" --> 2
    6 -- "'foo'" --> 2
    6 -- "'80'" --> 3
    6 -- "'12'" --> 3
    6 -- "':'" --> 2
    6 -- "'/'" --> 2
    6 -- "'.'" --> 2
    6 -- "'?'" --> 2
    6 -- "'='" --> 2
    6 -- "'&'" --> 2
    6 -- "'#'" --> 2
    6 -- "'@'" --> 2
    6 -- "'%'" --> 2
    7 -- "'http'" --> 2
    7 -- "'https'" --> 2
    7 -- "'ftp'" --> 4
    7 -- "'example'" --> 4
    7 -- "'com'" --> 4
    7 -- "'foo'" --> 4
    7 -- "'80'" --> 4
    7 -- "'12'" --> 4
    7 -- "':'" --> 3
    7 -- "'/'" --> 3
    7 -- "'.'" --> 3
    7 -- "'?'" --> 3
    7 -- "'='" --> 3
    7 -- "'&'" --> 3
    7 -- "'#'" --> 5
    7 -- "'@'" --> 3
    7 -- "'%'" --> 3
  ```

  #### `URI` regexp DFA

  ```mermaid
  flowchart TD
    0((0))
    1((1))
    2((2))
    3(((3)))
    4(((4)))

    0 -- "'http'" --> 1
    0 -- "'https'" --> 1
    0 -- "'ftp'" --> 2
    0 -- "'example'" --> 2
    0 -- "'com'" --> 2
    0 -- "'foo'" --> 2
    0 -- "'80'" --> 2
    0 -- "'12'" --> 2
    0 -- "':'" --> 2
    0 -- "'/'" --> 2
    0 -- "'.'" --> 2
    0 -- "'?'" --> 2
    0 -- "'='" --> 2
    0 -- "'&'" --> 2
    0 -- "'#'" --> 2
    0 -- "'@'" --> 2
    0 -- "'%'" --> 2
    1 -- "'http'" --> 2
    1 -- "'https'" --> 2
    1 -- "'ftp'" --> 2
    1 -- "'example'" --> 2
    1 -- "'com'" --> 2
    1 -- "'foo'" --> 2
    1 -- "'80'" --> 2
    1 -- "'12'" --> 2
    1 -- "':'" --> 3
    1 -- "'/'" --> 2
    1 -- "'.'" --> 2
    1 -- "'?'" --> 2
    1 -- "'='" --> 2
    1 -- "'&'" --> 2
    1 -- "'#'" --> 2
    1 -- "'@'" --> 2
    1 -- "'%'" --> 2
    2 -- "'http'" --> 2
    2 -- "'https'" --> 2
    2 -- "'ftp'" --> 2
    2 -- "'example'" --> 2
    2 -- "'com'" --> 2
    2 -- "'foo'" --> 2
    2 -- "'80'" --> 2
    2 -- "'12'" --> 2
    2 -- "':'" --> 2
    2 -- "'/'" --> 2
    2 -- "'.'" --> 2
    2 -- "'?'" --> 2
    2 -- "'='" --> 2
    2 -- "'&'" --> 2
    2 -- "'#'" --> 2
    2 -- "'@'" --> 2
    2 -- "'%'" --> 2
    3 -- "'http'" --> 3
    3 -- "'https'" --> 3
    3 -- "'ftp'" --> 3
    3 -- "'example'" --> 3
    3 -- "'com'" --> 3
    3 -- "'foo'" --> 3
    3 -- "'80'" --> 3
    3 -- "'12'" --> 3
    3 -- "':'" --> 3
    3 -- "'/'" --> 3
    3 -- "'.'" --> 3
    3 -- "'?'" --> 3
    3 -- "'='" --> 3
    3 -- "'&'" --> 3
    3 -- "'#'" --> 4
    3 -- "'@'" --> 3
    3 -- "'%'" --> 2
    4 -- "'http'" --> 4
    4 -- "'https'" --> 4
    4 -- "'ftp'" --> 4
    4 -- "'example'" --> 4
    4 -- "'com'" --> 4
    4 -- "'foo'" --> 4
    4 -- "'80'" --> 4
    4 -- "'12'" --> 4
    4 -- "':'" --> 4
    4 -- "'/'" --> 4
    4 -- "'.'" --> 4
    4 -- "'?'" --> 4
    4 -- "'='" --> 4
    4 -- "'&'" --> 4
    4 -- "'#'" --> 2
    4 -- "'@'" --> 4
    4 -- "'%'" --> 2
  ```

</details>

Next, we use `DFA.find_separating_word` to check equivalence between two automata.
This method finds a seperating word between two automata that is accepted by one automaton and rejected by another automaton.
This method returns `nil` if a separating word is not found, that is, two automata are equivalent.

```ruby
sep_word = Lernen::Automaton::DFA.find_separating_word(alphabet, uri_parse_dfa, uri_regexp_dfa)
sep_word&.join
# => "http:?%"
```

Then, we got `"http:?%"` as the separating word between the two automata.
It means that the two DFAs of `URI.parse` and `URI` regexp *obtained by `Lernen.learn`* are not equivalent.
Finally, we need to ensure that the separating word distinguish the actual implementations: `valid_and_http_url?` and `new_valid_and_http_url?`.

```ruby
valid_and_http_url?(sep_word.join)
# => true
new_valid_and_http_url?(sep_word.join)
# => false
```

Because of `valid_and_http_url?("http:?%") != new_valid_and_http_url?("http:?%")`, we can answer the first question:
*Validations with `URI.parse` and `URI` regexp are not the same because they behave differently with `"http:?%"`.*

### Case Study 2: Two Parsers for Ruby

Since 3.2, Ruby has two parser implementations: [`parse.y`](https://github.com/ruby/ruby/blob/master/parse.y) and [Prism](https://github.com/ruby/prism).
`parse.y` is a traditional LALR parser and Prism is a hand-written recursive descent parser.
Although Prism says highly compatibility to `parse.y`, we afraid whether they behave exactly the same or not.

This situation seems similar to the first case study, but there is a big difference here; that is, Ruby's grammar is not regular.
In other words, no DFA can recognize Ruby's grammar and learning a DFA for Ruby's grammar is impossible.

In this case, VPA (visibly pushdown automaton) works well.
VPA is a finite-state automaton extended with explicit nesting characters.
It can be thought of as pushdown automata, where characters that push or pop onto a stack are limited.
Although VPA is less powerful than pushdown automata, it can handle non-regular language such as nested parentheses.

VPA does not represent all Ruby's grammar, but it is good enough to find a bug in the parsers.
We infer automata of the Ripper (`parse.y`) and Prism parsers on alphabet with only parentheses (`(` and `)`), a string literal (`"a"`), and a colon (`:`).

```ruby
# `alphabet`, `call_alphabet`, and `return_alphabet` are arrays of pieces of words.
# The `alphabet` characters cause neither push nor pop,
# the `call_alphabet` characters cause push onto a stack, and
# the `return_alphabet` characters cause pop onto a stack.
alphabet = %w["a" :]
call_alphabet = %w[(]
return_alphabet = %w[)]

# `oracle` specifies a kind of an equivalence oracle using on learning,
# and `oracle_params` is a paremeter object to it.
oracle = :random_word
oracle_params = { max_words: 2000 }.freeze

# When `call_alphabet` and `return_alphabet` are specified to `Lernen.learn`,
# it infers a VPA instead of a automaton.

# Ripper (parse.y) VPA:
ripper_vpa = Lernen.learn(alphabet:, call_alphabet:, return_alphabet:, oracle:, oracle_params:, random:) do |word|
  !Ripper.sexp(word.join).nil?
end

# Prism VPA:
prism_vpa = Lernen.learn(alphabet:, call_alphabet:, return_alphabet:, oracle:, oracle_params:, random:) do |word|
  Prism.parse(word.join).success?
end
```

<details>
  <summary>Mermaid diagrams for Ripper and Prism VPAs</summary>

  #### Ripper VPA

  ```mermaid
  flowchart TD
    0(((0)))
    1(((1)))
    2(((2)))
    4((4))
    5((5))
    6((6))
    7((7))

    0 -- "'#34;a#34;'" --> 1
    0 -- "':'" --> 4
    1 -- "'#34;a#34;'" --> 1
    1 -- "':'" --> 5
    2 -- "':'" --> 5
    4 -- "'#34;a#34;'" --> 2
    5 -- "'#34;a#34;'" --> 6
    5 -- "':'" --> 7
    6 -- "'#34;a#34;'" --> 6

    0 -- "')'/(0,'(')" --> 2
    0 -- "')'/(5,'(')" --> 6
    0 -- "')'/(7,'(')" --> 2
    1 -- "')'/(0,'(')" --> 2
    1 -- "')'/(5,'(')" --> 6
    1 -- "')'/(7,'(')" --> 2
    2 -- "')'/(0,'(')" --> 2
    2 -- "')'/(5,'(')" --> 6
    2 -- "')'/(7,'(')" --> 2
    6 -- "')'/(7,'(')" --> 2
  ```

  #### Prism VPA

  ```mermaid
  flowchart TD
    0(((0)))
    1(((1)))
    2(((2)))
    4((4))
    5(((5)))
    6((6))
    7((7))
    8((8))

    0 -- "'#34;a#34;'" --> 1
    0 -- "':'" --> 4
    1 -- "'#34;a#34;'" --> 5
    1 -- "':'" --> 6
    2 -- "':'" --> 7
    4 -- "'#34;a#34;'" --> 2
    5 -- "'#34;a#34;'" --> 5
    5 -- "':'" --> 7
    6 -- "':'" --> 8
    7 -- "':'" --> 8

    0 -- "')'/(0,'(')" --> 2
    0 -- "')'/(8,'(')" --> 2
    1 -- "')'/(0,'(')" --> 2
    1 -- "')'/(8,'(')" --> 2
    2 -- "')'/(0,'(')" --> 2
    2 -- "')'/(8,'(')" --> 2
    5 -- "')'/(0,'(')" --> 2
    5 -- "')'/(8,'(')" --> 2
    6 -- "')'/(0,'(')" --> 2
  ```

</details>

As with DFAs, we can check whether two VPAs are equal by calling `find_separating_word`.

```ruby
sep_word = Lernen::Automaton::VPA.find_separating_word(alphabet, call_alphabet, return_alphabet, ripper_vpa, prism_vpa)
puts sep_word&.join
# => "(\"a\":)"
```

Then, we got `"(\"a\":)"` as the separating word between Ripper and Prism VPAs.
As of 2024/09/08 (Prism 1.0.0 and Ruby 3.3.5), this is indeed a counterexample of a string that behaves differently in Prism and `parse.y`.

```ruby
!Ripper.parse("(\"a\":)").nil?
# => false
Prism.parse("(\"a\":)").success?
# => true
```

This seems like a bug, since Prism parses this as a symbol literal surrounded by parentheses.

## Contributing

This library is under active development, and the API is subject to breaking changes.

If you find a bug or problem with the library, please create an issue or a pull request.

We can use `rake` during development.
These are tasks defined for this project.

- Run tests.

  ```console
  $ bundle exec rake test
  ```

- Run type checking using Steep.

  ```console
  $ bundle exec rake steep
  ```

- Run code formatting using Rubocop and `syntax_tree`.

  ```console
  $ bundle exec rake format
  ```

- Check code formatting.
  
  ```
  $ bundle exec rake lint
  ```

When you make a pull request, please make sure it pass `rake test && rake steep && rake lint`.

## License

[MIT](https://opensource.org/license/MIT)

2024 (C) Hiroya Fujinami
