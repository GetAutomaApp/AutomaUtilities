// ClientResponseExensions.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

public extension ClientResponse {
    func unwrapBodyOrThrow(errorMessage: String) throws -> ByteBuffer {
        guard
            let body = body
        else {
            throw AutomaGenericErrors.guardFailed(message: errorMessage)
        }
        return body
    }
}
