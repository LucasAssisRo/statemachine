import Foundation

// MARK: - StateMachine

/// A value that is either loading, holding content, or holding an error.
///
/// Loading and error states can each carry the content from a previous
/// success, so a view can keep showing stale data while a refresh is in
/// flight or after it fails.
@frozen public enum StateMachine<Content, Error> {
  /// Content is being produced, optionally alongside the previous content.
  case loading(content: Content?)
  /// Producing content failed, optionally alongside the previous content.
  case error(error: Error, content: Content?)
  /// Content is available.
  case content(content: Content)

  /// Creates a state from an optional content and an optional error.
  ///
  /// The error wins when both are given, and the state falls back to
  /// `loading` when neither is.
  ///
  /// - Parameters:
  ///   - content: Content to start in the `content` state with.
  ///   - error: Error to start in the `error` state with.
  public init(content: Content? = nil, error: Error? = nil) {
    if let error = error { self = .error(error: error, content: content) }
    else if let content = content { self = .content(content: content) }
    else { self = .loading(content: nil) }
  }
}

// MARK: - Unwrapped

public extension StateMachine {
  /// The content carried by any state, or `nil` when none has been received yet.
  var content: Content? {
    switch self {
    case let .content(content), let .error(_, content?), let .loading(content?): return content
    case .error, .loading: return nil
    }
  }

  /// The error, or `nil` unless the state is `error`.
  var error: Error? {
    switch self {
    case .content, .loading: return nil
    case let .error(error, _): return error
    }
  }

  /// Whether the state is `loading`, regardless of any content it carries.
  var isLoading: Bool {
    switch self {
    case .loading: return true
    case .content, .error: return false
    }
  }

  /// Whether the state is `error`.
  var isError: Bool { error != nil }

  /// Whether any content is available, in any state.
  var isContent: Bool { content != nil }

  /// Runs `block` with the content, and does nothing when there is none.
  ///
  /// - Parameter block: Closure receiving the available content.
  func contentIfPresent(_ block: (_ content: Content) -> Void) {
    content.map(block)
  }
}

// MARK: Mapping

public extension StateMachine {
  /// Transforms the content, keeping the current state and error.
  ///
  /// - Parameter transform: Closure converting the content.
  /// - Returns: A state over the transformed content.
  func map<TransformedContent>(_ transform: (Content) -> TransformedContent) -> StateMachine<TransformedContent, Error> {
    let newState: StateMachine<TransformedContent, Error>
    switch self {
    case let .loading(content): newState = .loading(content: content.map(transform))
    case let .error(error, content): newState = .error(error: error, content: content.map(transform))
    case let .content(content): newState = .content(content: transform(content))
    }
    return newState
  }

  /// Transforms the content, calling `transform` even when there is none.
  ///
  /// Use this to supply a placeholder for states that have not produced
  /// content yet, where ``map(_:)`` would leave them empty.
  ///
  /// - Parameter transform: Closure converting the optional content.
  /// - Returns: A state over the transformed content.
  func compactMap<TransformedContent>(_ transform: (Content?) -> TransformedContent) -> StateMachine<TransformedContent, Error> {
    let newState: StateMachine<TransformedContent, Error>
    switch self {
    case let .loading(content): newState = .loading(content: transform(content))
    case let .error(error, content): newState = .error(error: error, content: transform(content))
    case let .content(content): newState = .content(content: transform(content))
    }
    return newState
  }

  /// Transforms the error, keeping the current state and content.
  ///
  /// - Parameter transform: Closure converting the error.
  /// - Returns: A state over the transformed error.
  func mapError<TransformedError>(_ transform: (Error) -> TransformedError) -> StateMachine<Content, TransformedError> {
    let newState: StateMachine<Content, TransformedError>
    switch self {
    case let .loading(content): newState = .loading(content: content)
    case let .error(error, content): newState = .error(error: transform(error), content: content)
    case let .content(content): newState = .content(content: content)
    }
    return newState
  }
}

// MARK: - Switch Mutating

public extension StateMachine {
  /// Moves to `loading`, keeping any content already received.
  mutating func receivedLoading() {
    self = .loading(content: content)
  }

  /// Moves to `content`, replacing any content already received.
  ///
  /// - Parameter content: Newly received content.
  mutating func received(content: Content) {
    self = .content(content: content)
  }

  /// Moves to `error`, keeping any content already received.
  ///
  /// - Parameter error: Error that interrupted the work.
  mutating func received(error: Error) {
    self = .error(error: error, content: content)
  }

  /// Completely drops current data and restarts the StateMachine on empty loading.
  mutating func purgeContentAndError() {
    self = .loading(content: nil)
  }
}

// MARK: - Switch Non-mutating

public extension StateMachine {
  /// Returns the state moved to `loading`, keeping any content already received.
  func receivingLoading() -> Self {
    .loading(content: content)
  }

  /// Returns the state moved to `content`.
  ///
  /// - Parameter newContent: Newly received content.
  func receiving(content newContent: Content) -> Self {
    .content(content: newContent)
  }

  /// Returns the state moved to `error`, keeping any content already received.
  ///
  /// - Parameter newError: Error that interrupted the work.
  func receiving(error newError: Error) -> Self {
    .error(error: newError, content: content)
  }

  /// Returns an empty `loading` state, dropping the current content and error.
  func purgingContentAndError() -> Self {
    .loading(content: nil)
  }
}

// MARK: Equatable

extension StateMachine: Equatable where Content: Equatable, Error: Equatable {}

// MARK: Hashable

extension StateMachine: Hashable where Content: Hashable, Error: Hashable {}

// MARK: - StateMachine + Never

/// StateMachine that never fails.
public typealias SafeState<Content> = StateMachine<Content, Never>

public extension StateMachine where Content == Never {
  /// An empty loading state, for a machine that carries no content.
  static var loading: Self { .loading(content: nil) }

  /// An error state, for a machine that carries no content.
  ///
  /// - Parameter error: Error that interrupted the work.
  static func error(error: Error) -> Self {
    .error(error: error, content: nil)
  }
}

// MARK: - StateMachine + Result

public extension StateMachine where Error: Swift.Error {
  /// Helper method to bind a `Result`. Calls `receivedContent` on `success` and `receivedError` on `failure`.
  ///
  /// - Parameter result: `Result` value being bound.
  mutating func received(result: Result<Content, Error>) {
    switch result {
    case let .success(content): received(content: content)
    case let .failure(error): received(error: error)
    }
  }

  /// Returns the state moved to the case matching `result`.
  ///
  /// - Parameter result: `Result` value being bound.
  func receiving(result: Result<Content, Error>) -> Self {
    switch result {
    case let .success(content): return receiving(content: content)
    case let .failure(error): return receiving(error: error)
    }
  }
}

// MARK: - StateMachine + Decoding

public extension StateMachine where Content: Decodable {
  /// Decodes `data` into the content, moving to `error` when decoding fails.
  ///
  /// - Parameters:
  ///   - data: JSON payload to decode.
  ///   - mapError: Closure converting a decoding failure into the state's error.
  mutating func received(data: Data, mapError: (Swift.Error) -> Error) {
    do { self = try .content(content: JSONDecoder().decode(Content.self, from: data)) }
    catch { self = .error(error: mapError(error), content: content) }
  }

  /// Returns the state with `data` decoded into the content.
  ///
  /// - Parameters:
  ///   - data: JSON payload to decode.
  ///   - mapError: Closure converting a decoding failure into the state's error.
  /// - Returns: The `content` state on success, otherwise the `error` state.
  func receiving(data: Data, mapError: (Swift.Error) -> Error) -> Self {
    do { return try .content(content: JSONDecoder().decode(Content.self, from: data)) }
    catch { return .error(error: mapError(error), content: content) }
  }
}

public extension StateMachine where Content: Decodable, Error == Swift.Error {
  /// Decodes `data` into the content, keeping the decoding failure as the error.
  ///
  /// - Parameter data: JSON payload to decode.
  mutating func received(data: Data) {
    received(data: data, mapError: { $0 })
  }

  /// Returns the state with `data` decoded into the content.
  ///
  /// - Parameter data: JSON payload to decode.
  /// - Returns: The `content` state on success, otherwise the `error` state.
  func receiving(data: Data) -> Self {
    receiving(data: data, mapError: { $0 })
  }
}
