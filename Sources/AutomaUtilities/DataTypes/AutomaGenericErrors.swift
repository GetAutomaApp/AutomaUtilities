// AutomaGenericErrors.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

public enum AutomaGenericErrors: Error, Equatable {
    case invalidURL(url: String, reason: InvalidURLReason? = nil)

    public enum InvalidURLReason: Equatable, Sendable {
        case invalidScheme(scheme: String, reason: String)
        case noScheme
    }
}
