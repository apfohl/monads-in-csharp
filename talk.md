%title: Maybe<T> - Monads in C#
%author: Andreas Pfohl (GitHub: @apfohl / Twitter: @andreaspfohl)
%date: 2022-05-18

    Maybe<Session> session = mdDevDays.NextSession();
    
    session.Match(
        just: s => s.StartSlides(),
        nothing: () => Console.WriteLine("No session available.")
    );

---

-> # Monads in C# <-

-> What is it and how can it be applied <-

---

> The monadic curse is that once someone learns
> what monads are and how to use them, they lose
> the ability to explain them to other people.

— Douglas Crockford

---

> … a monad … is just a monoid
> in the category of endofunctors …

— Saunders Mac Lane

---

# Example


    public interface IApi {
        Person FindPerson(string name);
        Lightsaber FindLightsaber(int id);
    }
     
    public sealed class Person {
        public string Name { get; }
        public string Species { get; }
        public int Lightsaber { get; }
    }
     
    public sealed class Lightsaber {
        public int Id { get; }
        public string Color { get; }
    }


---

# Example

    var person = FindPerson("Luke Skywalker");
     
    if (person != null)
    {
        var lightsaber =
            FindLightsaber(person.Lightsaber);
         
        Console.WriteLine(lightsaber != null
            ? lightsaber.Color
            : "Lightsaber not found!");
    }

---

# What problems are we trying to solve?

^
- Context
^
- Composition
^
- Side effects
^
- NULL

^
-> ## -> Monads <-

---

# What exactly is a monad?

^
- Generic Type (Monad<T>)
^
- Container for your values
^
- Immutable
^
- Easy to get in and hard to get out
^
- Always defined state
^
- Methods to work consistently and
safely with contained values

---

# Simplest definition

^
## Type

- Struct or Class

^
## Creating a monad instance

- Constructor

^
## Bind the value

- A method to map the contained
value to a new monad instance

---

# Introducing Monad<T>

    public readonly struct Monad<T> {
^
      
        private readonly T instance;
^
      
        public Monad(T instance)
            => this.instance = instance;
^
      
        public Monad<TResult> Bind<TResult>(Func<T, Monad<TResult>> f)
            => f(instance);
      
    }

---

# Using Monad<T>

^
    var monad = new Monad<string>("May the force be with you!");
^
      
    monad.Bind(s => new Monad<string>($"{s} Live long and prosper!"));

^
\-> Hey Andreas, this is totally useless!

^
\-> You're right! But it serves as the foundation:

- Generic Type ✓
- Container for your values ✓
- Immutable ✓
- Easy to get in and yet impossible to get out ✓
- Always defined state ✓
- Methods to work consistently and
safely with contained values ✓

---

# What problems are we trying to solve?

- Context ✓
- Composition ✓
- Side effects
- NULL

---

# Making monads useful with Maybe<T>

^
- `Maybe<T>` is a monad like `Monad<T>`
^
- Instance can only be in two states:
^
  - Just T value
^
  - Nothing
^
- Needs two constructors:
^
  - `Maybe<T> Just(T value);`
^
  - `Maybe<T> Nothing();`
^
- Supports `Bind()` for composition
  - `Maybe<TResult> Bind<TResult>(Func<T, Maybe<TResult>> f);`

^
\-> Hey Andreas, that's still not useful!

---

# Introducing Match() AKA getting out of the monad

^
\-> After construction the value is monadic.
^

- In context
- Immutable
- Always defined state
- Easy to get in and hard to get out <-
^
- Provide a method to work consistent and safe
with the contained value
^

    TResult Match<TResult>(
        Func<T, TResult> just,
        Func<TResult> nothing
    );

---

# Using Match()

^
`Person FindPerson(string name);`
^

↓

`Maybe<Person> FindPerson(string name);`
^

\-> Success: `Maybe<string>.Just(new Person(…));`
^

\-> Failure: `Maybe<string>.Nothing();`
^


    TResult Match<TResult>(Func<T, TResult> just, Func<TResult> nothing);
^


    FindPerson("Luke Skywalker")
^
        .Match(
^
            person => Console.WriteLine(person.Species),
^
            () => Console.WriteLine("Person not found!")
        );

---

# Using Match()

`Person FindPerson(string name);`

↓

`Maybe<Person> FindPerson(string name);`

\-> Success: `Maybe<string>.Just(new Person(…));`

\-> Failure: `Maybe<string>.Nothing();`


    TResult Match<TResult>(Func<T, TResult> just, Func<TResult> nothing);


    Console.WriteLine(FindPerson("Luke Skywalker")
        .Match(
            person => person.Species,
            () => "Person not found!"
        )
    );

---

# What problems are we trying to solve?

- Context ✓
- Composition ✓
- Side effects ✓
- NULL ✓

---

# Full Maybe<T> API Example

^
    public interface IApi {
        Maybe<Person> FindPerson(string name);
        Maybe<Lightsaber> FindLightsaber(int id);
    }
^

    Console.WriteLine(FindPerson("Luke Skywalker")
        .Match(
            person => FindLightsaber(person.Lightsaber)
                .Match(
                    lightsaber => lightsaber.Color,
                    () => "Lightsaber not found!"
                ),
            () => "Person not found!"
        )
    );
^

\-> Hey Andreas, that's pretty useful, but …
^

\-> … all this nesting becomes ugly very quickly!

---

# Unleash the power of Bind()

^
\-> As a monad `Maybe<T>` has to implement `bind()`.
^

`Maybe<TResult> Bind<TResult>(Func<T, Maybe<TResult>> f);`
^


    Console.WriteLine(FindPerson("Luke Skywalker")
^
        .Bind(
^
            p => FindLightsaber(p.Lightsaber)
        )
^
        .Match(
^
            lightsaber => lightsaber.Color,
^
            () => "Lightsaber not found!"
        )
    );
^

\-> Hey Andreas, that's what I'm looking for!

---

# Bind() with LINQ

^
- Other names for Bind() are SelectMany() or FlatMap()
^
- Provide a special extension for Maybe<T>, implemented with Bind()
^

    public static Maybe<TResult> SelectMany<T, TCollection, TResult>(
        this Maybe<T> maybe,
        Func<T, Maybe<TCollection>> collection,
        Func<T, TCollection, TResult> selector)
^

    var lightsaber =
        from person in FindPerson("Luke Skywalker")
        from lightsaber in FindLightSaber(person)
        select lightsaber;
^

    Console.WriteLine(
        lightsaber.Match(
            lightsaber => lightsaber.Color,
            () => "Lightsaber not found!"
        )
    )

---

# Maybe<T> inside

^
    public readonly struct Maybe<T> {
^
        private T Instance { get; init; }
^
        private bool IsJust { get; init; }
^
     
        public static Maybe<T> Just(T instance)
            => new() { Instance = instance, IsJust = true };
^
        public static Maybe<T> Nothing()
            => new() { IsJust = false };
^
     
        public Maybe<TResult> Bind<TResult>(Func<T, Maybe<TResult>> f)
            => IsJust ? func(Instance) : Maybe<TResult>.Nothing();
^
     
        public TResult Match<TResult>(Func<T, TResult> j, Func<TResult> n)
            => IsJust ? j(Instance) : n();
    }

---

# Other monads in C#

\-> Hey Andreas, this looks constructed. Is there more?
^

\-> Of cause ;).

---

# IEnumerable<T>, IQueryable<T> and IObservable<T>

^
- Context
^
- Immutable
^
- Easy in and hard out
^
- Methods
  - Select()
  - SelectMany() <- Bind()
  - First()
  - LINQ
  - …

---

# Task<T>

^
    public static Task<T> Return<T>(this T value) =>
        Task.FromResult(value);
^

    public static async Task<TResult> Bind<T, TResult>(
        this Task<T> task,
        Func<T, Task<TResult>> func
    ) => await func(await task);
^

    public static async Task<TResult> Map<T, TResult>(
        this Task<T> task,
        Func<T, TResult> func) =>
        await func(await task).Return();

---

# Task<T> with Bind()

^
    var task = 42.Return();
^
    var result = await task.Bind(ApiCall);
^    

    Console.WriteLine(result);

---

# Task<T> with LINQ

^
    public static Task<TR> SelectMany<TS, TC, TR>(
        this Task<TS> task,
        Func<TS, Task<TC>> collectionSelector,
        Func<TS, TC, TR> resultSelector) =>
        task.Bind(
            t => collectionSelector(t)
                    .Map(r => resultSelector(t, r)));
^

    var result =
^
        from i in 42.Return()
^
        from j in ApiCall(i)
^
        select j;
^

    Console.WriteLine(await result);

---

# Lazy<T>

^
    public static Lazy<T> LazyReturn<T>(this Func<T> factory) =>
        new(factory);
^

    public static Lazy<TResult> Map<T, TResult>(
        this Lazy<T> lazy,
        Func<T, TResult> func) =>
        new(() => func(lazy.Value));
^

    public static Lazy<TResult> Bind<T, TResult>(
        this Lazy<T> lazy,
        Func<T, Lazy<TResult>> func) =>
        lazy.Map(l => func(l).Value);

---

# Lazy<T> with Bind()

^
    public static Lazy<TR> SelectMany<TS, TC, TR>(
        this Lazy<TS> lazy,
        Func<TS, Lazy<TC>> collectionSelector,
        Func<TS, TC, TR> resultSelector) =>
        lazy.Bind(
            t => collectionSelector(t)
                    .Map(r => resultSelector(t, r)));
^

    var factory = () => 42;
^
    var lazy = factory.LazyReturn();
^

    var result = lazy.Bind(LazyApiCall);
^

    Console.WriteLine(result.Value);

---

# Lazy<T> with LINQ

^
    var result =
^
        from i in lazy
^
        from j in LazyApiCall(i)
^
        select j;
^

    Console.WriteLine(result.Value);

---

# Many, many possible monads

^
- Applicable for almost any generic type
^
- Same concept for all cases
^
- Abstraction of APIs
^
- Speaking and honest function prototypes
^
- If concept is understood, code and APIs become more clear
and easier to read
^

\-> Give it a try!

---

# Is there a real-world implementation?

\-> YES!

https://www.nuget.org/packages/bridgefield.MonadicBits/

https://www.nuget.org/packages/Optional/

## Differences

- `Maybe<T>` is called `Option<T>`
- `Bind()` is called `FlatMap()`
- Loads more methods to work with your contained values
- LINQ query syntax support
- Provides another monad `Either<TLeft, TRight>` / `Option<T, TException>`

---

-> # Thank you!


## References

https://github.com/nlkl/Optional
https://github.com/bridgefield/MonadicBits
http://learnyouahaskell.com/a-fistful-of-monads
https://en.wikipedia.org/wiki/Monad_(functional_programming)
https://mikhail.io/2018/07/monads-explained-in-csharp-again/
https://dev.to/niinpatel/
    what-does-the-phrase-monadic-bind-mean-in-haskell-ie7
https://adit.io/posts/
    2013-04-17-functors,_applicatives,_and_monads_in_pictures.html
http://hackage.haskell.org/
