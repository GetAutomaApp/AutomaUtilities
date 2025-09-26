// TaskExtensions.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

/// Extension on Task to start a detached task & log raw output
internal extension Task where Success == Void, Failure == any Error {
    /// Executes & logs success / error on end
    static func detachedLogOnError(
        destination: String,
        logger: Logger,
        onError: @escaping @Sendable (Error) async throws -> Void = { _ in },
        onSuccess: @escaping @Sendable () async throws -> Void = {},
        method: @escaping @Sendable () async throws -> Void
    ) {
        Task.detached {
            do {
                try await method()
            } catch {
                logger.critical(
                    "Error occurred while running detached task",
                    metadata: [
                        "destination": .array([
                            .string(destination),
                            .string("Task.detachedLogOnError"),
                            .string(error.localizedDescription),
                        ]),
                    ]
                )
                try await onError(error)
            }

            try await onSuccess()
        }
    }
}
