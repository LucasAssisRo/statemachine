//
//  State.swift
//  State
//
//  Created by Lucas Assis Rodrigues on 13.10.20.
//

@frozen public enum State<Content, Error> {
    case loading(content: Content?)
    case error(error: Error, content: Content?)
    case content(content: Content)

    public init(content: Content?, error: Error?) {
        if let error = error { self = .error(error: error, content: content) }
        else if let content = content { self = .content(content: content) }
        else { self = .loading(content: nil) }
    }
}

// MARK: - Unwrapped

public extension State {
    var content: Content? {
        switch self {
        case let .loading(content?), let .error(_, content?), let .content(content): return content
        case .loading, .error: return nil
        }
    }

    var error: Error? {
        switch self {
        case .loading, .content: return nil
        case let .error(error, _): return error
        }
    }

    var isLoading: Bool {
        switch self {
        case .loading: return true
        case .error, .content: return false
        }
    }
}

// MARK: Mapping

public extension State {
    func map<TransformedContent>(_ transform: (Content) -> TransformedContent) -> State<TransformedContent, Error> {
        let newState: State<TransformedContent, Error>
        switch self {
        case let .loading(content): newState = .loading(content: content.map(transform))
        case let .error(error, content): newState = .error(error: error, content: content.map(transform))
        case let .content(content): newState = .content(content: transform(content))
        }
        return newState
    }

    func compactMap<TransformedContent>(_ transform: (Content?) -> TransformedContent) -> State<TransformedContent, Error> {
        let newState: State<TransformedContent, Error>
        switch self {
        case let .loading(content): newState = .loading(content: transform(content))
        case let .error(error, content): newState = .error(error: error, content: transform(content))
        case let .content(content): newState = .content(content: transform(content))
        }
        return newState
    }

    func mapError<TransformedError>(_ transform: (Error) -> TransformedError) -> State<Content, TransformedError> {
        let newState: State<Content, TransformedError>
        switch self {
        case let .loading(content): newState = .loading(content: content)
        case let .error(error, content): newState = .error(error: transform(error), content: content)
        case let .content(content): newState = .content(content: content)
        }
        return newState
    }
}

// MARK: - Switch Mutating

public extension State {
    mutating func receivedLoading() { self = .loading(content: content) }
    mutating func received(content: Content) { self = .content(content: content) }
    mutating func received(error: Error) { self = .error(error: error, content: content) }

    /// Completely drops current data and restarts the state on empty loading.
    mutating func purgeContentAndError() { self = .loading(content: nil) }
}

// MARK: - Switch Non-mutating

public extension State {
    func receivingLoading() -> Self { .loading(content: content) }
    func receiving(toContent newContent: Content) -> Self { .content(content: newContent) }
    func receiving(toError newError: Error) -> Self { .error(error: newError, content: content) }
    func purgingContentAndERror() -> Self { .loading(content: nil) }
}

// MARK: - Equatable

extension State: Equatable where Content: Equatable, Error: Equatable {}

// MARK: - Hashable

extension State: Hashable where Content: Hashable, Error: Hashable {}

// MARK: - State + Never

/// State that never fails.
public typealias SafeState<Content> = State<Content, Never>

public extension State where Content == Never {
    static var loading: Self { .loading(content: nil) }
    static func error(error: Error) -> Self { .error(error: error, content: nil) }
}

// MARK: - State + Result

public extension State where Error: Swift.Error {
    /// Helper method to bind a `Result`. Calls `receivedContent` on `success` and `receivedError` on `failure`.
    ///
    /// - Parameter result: `Result` value being bound.
    mutating func received(result: Result<Content, Error>) {
        switch result {
        case let .success(content): received(content: content)
        case let .failure(error): received(error: error)
        }
    }

    func switching(toContentOrErrorFrom result: Result<Content, Error>) -> Self {
        switch result {
        case let .success(content): return receiving(toContent: content)
        case let .failure(error): return receiving(toError: error)
        }
    }
}

// MARK: - State + Decoding

public extension State where Content: Decodable {
    mutating func received(data: Data, mapError: (Swift.Error) -> Error) {
        do { self = .content(content: try JSONDecoder().decode(Content.self, from: data)) }
        catch { self = .error(error: mapError(error), content: content) }
    }

    func recieving(data: Data, mapError: (Swift.Error) -> Error) -> Self {
        do { return .content(content: try JSONDecoder().decode(Content.self, from: data)) }
        catch { return .error(error: mapError(error), content: content) }
    }
}

public extension State where Content: Decodable, Error == Swift.Error {
    mutating func received(data: Data) { self.received(data: data, mapError: { $0 }) }

    func recieving(data: Data) -> Self { self.recieving(data: data, mapError: { $0 }) }
}

