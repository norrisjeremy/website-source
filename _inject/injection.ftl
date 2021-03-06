<h2 id="injection">Injection</h2>

<h3 id="singleton">@Singleton</h3>
<p>
  Put <code>@Singleton</code> on beans that we want dependency injection on.
  These are beans that are created ("wired") by dependency injection and put into the context.
  They are then available to be injected into other beans.
</p>

<h3 id="inject">@Inject</h3>
<p>
  Put <code>@Inject</code> on the constructor that should be used for constructor dependency injection.
  Note that if there is <code>only one constructor</code> we don't need to put the <code>@Inject</code> on it.
</p>
<p>
  If we want to use field injection put the <code>@Inject</code> on the field. Note that the field must not
  be <code>private</code> and must not be <code>final</code> for field injection.
</p>

<h3 id="constructor">Constructor injection</h3>
<pre content="java">
@Singleton
public class CoffeeMaker {

  private final Pump pump;

  private final Grinder grinder;

  @Inject
  public CoffeeMaker(Pump pump, Grinder grinder) {
    this.pump = pump;
    this.grinder = grinder;
  }
  ...
</pre>
<p>
  The above CoffeeMaker is using constructor injection. Both a Pump and Ginder will be injected into the
  constructor when the DI creates (or "wires") the CoffeeMaker.
</p>
<p>
  Note that if there is only 1 constructor it is used for dependency injection and we don't need
  to specify <code>@Inject</code>.
</p>

<h4>Kotlin constructor</h4>
<p>
  With Kotlin we frequently will not specify <em>@Inject</em> with only one constructor.
  The CoffeeMaker constructor injection then looks like:
</p>
<pre content="kotlin">
@Singleton
class CoffeeMaker(private val pump: Pump , private val grinder: Grinder)  {

  fun makeCoffee() {
    ...
  }
}
</pre>

<h3 id="field">Field injection</h3>
<pre content="java">
@Singleton
public class CoffeeMaker {

  @Inject
  Pump pump;

  @Inject
  Grinder grinder;
  ...
</pre>
<p>
  With field injection the <code>@Inject</code> is placed on the field and the field must not be <code>private</code>
  and it must not be <code>final</code>.
</p>
<h4>Constructor injection preferred</h4>
<p>
  Generally there is a preference to use constructor injection over field injection as constructor
  injection:
</p>
<ul>
  <li>Promotes immutability / use of final fields / proper initialisation</li>
  <li>Communicates required dependencies at compile time. Helps when dependencies
    change to keep test code in line.</li>
  <li>Helps identify when there are too many dependencies. Too many constructor
    arguments is a more obvious code smell compared to field injection.
    Promotes single responsibility principal.</li>
</ul>

<h4>Field injection for circular dependencies</h4>
<p>
  We use field injection to handle <a href="#circular">circular dependencies</a>.
  See <a href="#circular">below</a> for more details.
</p>

<h4>Kotlin field injection</h4>
<p>
  For Kotlin we can consider using <em>lateinit</em> on the property with field injection.
</p>
<pre content="kotlin">
@Singleton
class Grinder {

  @Inject
  lateinit var pump: Pump

  fun grind(): String {
    ...
  }
}
</pre>

<h3 id="mixed">Mixed constructor and field injection</h3>
<p>
  We are allowed to mix constructor and field injection. In the below example the Grinder is injected into the constructor
  and the Pump is injected by field injection.
</p>

<pre content="java">
@Singleton
public class CoffeeMaker {

  @Inject
  Pump pump;

  private final Grinder grinder;

  public CoffeeMaker(Grinder grinder) {
    this.grinder = grinder;
  }
</pre>

<h3 id="circular">Circular dependencies</h3>
<p>
  When we have a circular dependency then we need to use <a href="#field">field injection</a>
  on one of the dependencies.
</p>
<p>
  For example, lets say we have A and B where A depends on B and B depends on A. In this case
  we can't use constructor injection for both A and B like:
</p>
<pre content="java">
// circular dependency with constructor injection, this will not work !!

@Singleton
class A {
  B b;
  A(B b) {       // constructor for A depends on B
    this.b = b;
  }
}

@Singleton
class B {
  A a;
  B(A a) {       // constructor for B depends on A
    this.a = a;
  }
}
</pre>
<p>
  With the above circular dependencies for A and B constructor injection <em>avaje-inject</em>
  can not determine the order in which to construct the beans. <em>avaje-inject</em> will
  detect this and product a compilation error outlining the beans involved and ask us
  to change to use field injection for one of the dependencies.
</p>
<p>
  We can not use constructor injection for both A and B and instead we must use
  field injection on either A or B like:
</p>
<pre content="java">
@Singleton
class A {
  @Inject   // use field injection
  B b;
}

@Singleton
class B {
  A a;
  B(A a) {
    this.a = a;
  }
}
</pre>
<p>
  The reason this works is that field injection occurs later after all the
  dependencies are constructed. <em>avaje-inject</em> uses 2 phases to
  "wire" the beans and then a 3rd phase to execute the <code>@PostConstruct</code>
  lifecycle methods:
</p>
<ul>
  <li>Phase 1: Construct all the beans in order based on constructor dependencies</li>
  <li>Phase 2: Apply field injection on all beans</li>
  <li>Phase 3: Execute all <code>@PostConstruct</code> lifecycle methods</li>
</ul>
<p>
  Circular dependencies more commonly occur with more than 2 beans. For example,
  lets say we have A, B and C where:
</p>
<ul>
  <li>A depends on B</li>
  <li>B depends on C</li>
  <li>C depends on A</li>
</ul>
<p>
  With A, B, C above they combine to create a circular dependency. To handle this
  we need to use <a href="#field">field injection</a> on one of the dependencies.
</p>

<h3 id="optional">Optional</h3>
<p>
  We can use <code>java.util.Optional&lt;T&gt;</code> to inject optional dependencies.
  These are dependencies that might not be provided / might not have an available implementation.
</p>
<pre content="java">
@Singleton
class Pump {

  private final Heater heater;

  private final Optional<|Widget> widget;

  @Inject
  Pump(Heater heater, Optional<|Widget> widget) {
    this.heater = heater;
    this.widget = widget;
  }

  public void pump() {
    if (widget.isPresent()) {
      widget.get().doStuff();
    }
    ...
  }
}
</pre>
<h5>Spring DI Note</h5>
<p>
  Spring users will be familiar with the use of <code>@Autowired(required=false)</code>
  for wiring optional dependencies. With <em>avaje-inject</em> we instead use <code>Optional</code>
  to inject optional dependencies.
</p>

<h3 id="list">List</h3>
<p>
  We can inject a <code>java.util.List&lt;T&gt;</code> of beans that implement an interface.
</p>
<pre content="java">
@Singleton
public class CombinedBars {

  private final List<|Bar> bars;

  @Inject
  public CombinedBars(List<|Bar> bars) {
    this.bars = bars;
  }
</pre>

<h3 id="set">Set</h3>
<p>
  We can inject a <code>java.util.Set&lt;T&gt;</code> of beans that implement an interface.
</p>
<pre content="java">
@Singleton
public class CombinedBars {

  private final Set<|Bar> bars;

  @Inject
  public CombinedBars(Set<|Bar> bars) {
    this.bars = bars;
  }
</pre>

<h3 id="provider">Provider</h3>
<p>
  A Singleton bean can implement <code>javax.inject.Provider&lt;T&gt;</code> to create a bean to
  be used in injection.
</p>
<pre content="java">
@Singleton
public class FooProvider implements Provider<|Foo> {

  private final Bazz bazz;

  FooProvider(Bazz bazz) {
    this.bazz = bazz;
  }

  @Override
  public Foo get() {
    // maybe do interesting logic, read environment variables ...
    return new BasicFoo(bazz);
  }
}
</pre>
<p>
  Note that the alternative to using the <code>javax.inject.Provider&lt;T&gt;</code> interface is
  to instead use <code><a href="#factory">@Factory</a></code> and <code><a href="#bean">@Bean</a></code>
  as it is more flexible and convenient than the the provider interface.
</p>
<h5>Spring DI Note</h5>
<p>
  The JSR 330 <code>javax.inject.Provider&lt;T&gt;</code> interface is functionally the same
  as Spring DI <code>FactoryBean&lt;T&gt;</code>.
</p>


<h3 id="factory">@Factory</h3>
<p>
  Factory beans allow logic to be used when creating a bean. Often this logic is based
  on environment variables or system properties (e.g. programmatically create a bean based on AWS region).
</p>
<p>
  We annotate a class with <code>@Factory</code> to tell us that it contains methods
  that create beans. The factory class can itself have dependencies.
</p>
<p>
  <em>@Factory</em> <em>@Bean</em> are equivalent to Spring DI <em>@Configuration</em> <em>@Bean</em>
  and Micronaut <em>@Factory</em> <em>@Bean</em>.
</p>

<h3 id="bean">@Bean</h3>
<p>
  We annotate methods on the factory class that create a bean with <code>@Bean</code>.
  These methods can have dependencies and will execute in the appropriate order
  depending on the dependencies they require.
</p>

<h4>Example</h4>
<pre content="java">
@Factory
class Configuration {

  private final StartConfig startConfig;

  /**
   * Factory can have dependencies.
   */
  @Inject
  Configuration(StartConfig startConfig) {
    this.startConfig = startConfig;
  }

  @Bean
  Pump buildPump() {
    // maybe read System properties or environment variables
    return new FastPump(...);
  }

  /**
   * Method with dependencies as method parameters.
   */
  @Bean
  CoffeeMaker buildBar(Pump pump, Grinder grinder) {
    // maybe read System properties or environment variables
    return new CoffeeMaker(...);
  }
}
</pre>

<h3 id="initMethod">@Bean initMethod & destroyMethod</h3>
<p>
  With <code>@Bean</code> we can specify an <code>initMethod</code>
  which will be executed on startup like <code>@PostConstruct</code>.
  Similarly a <code>destroyMethod</code> which execute on shutdown like <code>@PreDestroy</code>.
</p>


<h4>Example</h4>
<pre content="java">
@Factory
class Configuration {
  ...
  @Bean(initMethod = "init", destroyMethod = "close")
  CoffeeMaker buildCoffeeMaker(Pump pump) {
    return new CoffeeMaker(pump);
  }
}
</pre>
<p>
  The CoffeeMaker has the appropriate methods that are executed as part of the lifecycle.
</p>
<pre content="java">
class CoffeeMaker {

  void init() {
    // lifecycle executed on start/PostConstruct
  }
  void close() {
    // lifecycle executed on shutdown/PreDestroy
  }
  ...
}
</pre>


<h2 id="primary">@Primary</h2>
<p>
  A bean with <code>@Primary</code> is deemed to be highest priority and will be injected and used
  when it is available. This is functionally the same as Spring and Micronaut <em>@Primary</em>.
</p>
<p>
  There should only ever be <b>one</b> bean implementation marked as <em>@Primary</em> for
  a given dependency.
</p>

<h4>Example</h4>
<pre content="java">
// Highest priority EmailServer
// Used when available (e.g. module in the class path)
@Primary
@Singleton
public class PreferredEmailSender implements EmailServer {
  ...
</pre>

<h2 id="secondary">@Secondary</h2>
<p>
  A bean with <code>@Secondary</code> is deemed to be lowest priority and will only be injected
  if there are no other candidates to inject. We use <code>@Secondary</code> to indicate a
  "default" or "fallback" implementation that will be superseded by any other available implementation.
</p>
<p>
  This is functionally the same as Spring and Micronaut <em>@Secondary</em>.
</p>
<h4>Example</h4>
<pre content="java">
// Lowest priority EmailServer
// Only used if no other EmailServer is available
@Secondary
@Singleton
public class DefaultEmailSender implements EmailServer {
  ...
</pre>

<h3 id="primary-usage">Use of @Primary and @Secondary</h3>
<p>
  <code>@Primary</code> and <code>@Secondary</code> are used when there are
  multiple candidates to inject. They provide a "priority" to determine which dependency to
  inject and use when injecting a single implementation and multiple candidates are available
  to inject.
</p>
<p>
  We typically use <em>@Primary</em> and <em>@Secondary</em> when we are
  building multi-module applications. We have multiple modules (jars) that provide implementations.
  We use <em>@Secondary</em> to indicate a "default" or "fallback" implementation to use
  and we use <em>@Primary</em> to indicate the best implementation to use when it is available.
  <em>avaje-inject</em> DI will then wire depending on which modules (jars) are included in the classpath.
</p>
