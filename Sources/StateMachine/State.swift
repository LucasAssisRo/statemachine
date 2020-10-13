//
//  StateMachine.swift
//  StateMachine
//
//  Created by Lucas Assis Rodrigues on 13.10.20.
//

import Foundation

@frozen public enum StateMachine<Content, Error> {
    case loading(content: Content?)
    case error(error: Error, content: Content?)
    case content(content: Content)

    public init(content: Content? = nil, error: Error? = nil) {
        if let error = error { self = .error(error: error, content: content) }
        else if let content = content { self = .content(content: content) }
        else { self = .loading(content: nil) }
    }
}

// MARK: - Unwrapped

public extension StateMachine {
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

public extension StateMachine {
    func map<TransformedContent>(_ transform: (Content) -> TransformedContent) -> StateMachine<TransformedContent, Error> {
        let newState: StateMachine<TransformedContent, Error>
        switch self {
        case let .loading(content): newState = .loading(content: content.map(transform))
        case let .error(error, content): newState = .error(error: error, content: content.map(transform))
        case let .content(content): newState = .content(content: transform(content))
        }
        return newState
    }

    func compactMap<TransformedContent>(_ transform: (Content?) -> TransformedContent) -> StateMachine<TransformedContent, Error> {
        let newState: StateMachine<TransformedContent, Error>
        switch self {
        case let .loading(content): newState = .loading(content: transform(content))
        case let .error(error, content): newState = .error(error: error, content: transform(content))
        case let .content(content): newState = .content(content: transform(content))
        }
        return newState
    }

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
    mutating func receivedLoading() { self = .loading(content: content) }
    mutating func received(content: Content) { self = .content(content: content) }
    mutating func received(error: Error) { self = .error(error: error, content: content) }

    /// Completely drops current data and restarts the StateMachine on empty loading.
    mutating func purgeContentAndError() { self = .loading(content: nil) }
}

// MARK: - Switch Non-mutating

public extension StateMachine {
    func receivingLoading() -> Self { .loading(content: content) }
    func receiving(toContent newContent: Content) -> Self { .content(content: newContent) }
    func receiving(toError newError: Error) -> Self { .error(error: newError, content: content) }
    func purgingContentAndERror() -> Self { .loading(content: nil) }
}

// MARK: - Equatable

extension StateMachine: Equatable where Content: Equatable, Error: Equatable {}

// MARK: - Hashable

extension StateMachine: Hashable where Content: Hashable, Error: Hashable {}

// MARK: - StateMachine + Never

/// StateMachine that never fails.
public typealias SafeState<Content> = StateMachine<Content, Never>

public extension StateMachine where Content == Never {
    static var loading: Self { .loading(content: nil) }
    static func error(error: Error) -> Self { .error(error: error, content: nil) }
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

    func switching(toContentOrErrorFrom result: Result<Content, Error>) -> Self {
        switch result {
        case let .success(content): return receiving(toContent: content)
        case let .failure(error): return receiving(toError: error)
        }
    }
}

// MARK: - StateMachine + Decoding

public extension StateMachine where Content: Decodable {
    mutating func received(data: Data, mapError: (Swift.Error) -> Error) {
        do { self = .content(content: try JSONDecoder().decode(Content.self, from: data)) }
        catch { self = .error(error: mapError(error), content: content) }
    }

    func recieving(data: Data, mapError: (Swift.Error) -> Error) -> Self {
        do { return .content(content: try JSONDecoder().decode(Content.self, from: data)) }
        catch { return .error(error: mapError(error), content: content) }
    }
}

public extension StateMachine where Content: Decodable, Error == Swift.Error {
    mutating func received(data: Data) { self.received(data: data, mapError: { $0 }) }

    func recieving(data: Data) -> Self { self.recieving(data: data, mapError: { $0 }) }
}

