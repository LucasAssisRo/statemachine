# ``StateMachine``

Model loading, content and error as a single value.

## Overview

Asynchronous work usually produces three things a view cares about: whether it
is still running, what it produced, and how it failed. Tracking those as
separate properties lets them contradict each other — loading and failed at the
same time, or an error sitting next to content nobody cleared.

``StateMachine/StateMachine`` collapses them into one value with three cases,
so the invalid combinations cannot be represented:

```swift
var state = StateMachine<[Article], LoadError>.loading(content: nil)

state.received(content: articles)
state.received(error: .offline)
```

Loading and error both carry the previous content, so a refresh can keep the
old data on screen while it runs, and keep it after it fails:

```swift
if let articles = state.content {
    List(articles) { ArticleRow($0) }
}
if state.isLoading { ProgressView() }
```

Use ``SafeState`` for work that cannot fail.

## Topics

### States

- ``StateMachine/StateMachine``

### Work That Cannot Fail

- ``SafeState``
