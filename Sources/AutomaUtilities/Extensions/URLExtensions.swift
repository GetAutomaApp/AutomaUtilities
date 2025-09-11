// URLExtensions.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Foundation

/// Extend Foundation URL object with additional helper methods
public extension URL {
    /// Initialize a new `URL` object from a urlString with error handling
    /// - Parameters:
    ///   - urlString: String to convert to a `URL`, expected to be in the correct format
    ///   - asHttp: `Bool` = false - Set the scheme to 'http' if no scheme is provided in `urlString`
    ///   - onlyHttpOrHttpsScheme: `Bool` = true - If true, an error will be thrown if `urlString` scheme is not "http"
    /// or "https"
    ///
    /// - Throws: `AutomaGenericErrors.invalidURL` when the string cannot be converted to a `URL` or when scheme isn't
    /// 'http' or
    /// 'https' and `onlyHttpOrHttpsScheme` is true
    /// - Returns: `urlString` as `URL`
    static func fromString(payload: URLFromStringPayload) throws -> URL {
        return try URLFromStringCreator(payload: payload).create()
    }
}

internal struct URLFromStringCreator {
    private let payload: URLFromStringPayload

    /// Initialize `URLFromStringCreator`, used to create a URL from a string
    /// - Parameter payload:
    public init(payload: URLFromStringPayload) {
        self.payload = payload
    }

    /// Create URL from string
    /// - Throws: `AutomaGenericErrors.invalidURL` when url or scheme is invalid
    /// - Returns: The url string from payload as an initialized `URL`
    public func create() throws -> URL {
        let url = try getURL()
        try validateURLScheme(url: url)
        return url
    }

    private func validateURLScheme(url: URL) throws {
        let scheme = try unwrapSchemeFrom(url: url)
        try validateSchemeIsHttpOrHttps(url: url, scheme: scheme)
    }

    private func validateSchemeIsHttpOrHttps(url: URL, scheme: String) throws {
        if payload.onlyHttpOrHttpsScheme == false {
            return
        }

        if ["http", "https"].contains(scheme) == false {
            throw AutomaGenericErrors.invalidURL(
                url: url.absoluteString,
                reason: .invalidScheme(scheme: scheme, reason: "only http and https allowed")
            )
        }
    }

    private func unwrapSchemeFrom(url: URL) throws -> String {
        guard
            let scheme = url.scheme
        else {
            throw AutomaGenericErrors.invalidURL(url: url.absoluteString, reason: .noScheme)
        }
        return scheme
    }

    private func getURL() throws -> URL {
        let urlString = getURLString()
        return try urlStringToURL(urlString)
    }

    private func getURLString() -> String {
        var urlStringFinal: String = payload.urlString

        if payload.asHttp, urlStringFinal.contains("://") == false {
            urlStringFinal = "http://" + urlStringFinal
        }
        return urlStringFinal
    }

    private func urlStringToURL(_ urlString: String) throws -> URL {
        guard
            let url = URL(string: urlString)
        else {
            throw AutomaGenericErrors.invalidURL(url: urlString)
        }
        return url
    }
}

public struct URLFromStringPayload {
    /// URL as a string
    public let urlString: String

    /// Should set scheme as http if no scheme is provided
    public let asHttp: Bool

    /// When true, method that uses this data structure to create a URL will throw an error if scheme is not http or
    /// https
    public let onlyHttpOrHttpsScheme: Bool

    /// Initialize a new `URLFromStringPayload` data structure
    /// - Parameters:
    ///   - urlString: `String`, the url as a string
    ///   - asHttp: `Bool = false`, when true, will add "http" as the urlString scheme if no scheme is provided.
    ///   - onlyHttpOrHttpsScheme: `Bool = true`, will throw an error if true and `urlString` has a scheme other than
    /// http or https
    ///
    public init(string urlString: String, asHttp: Bool = false, onlyHttpOrHttpsScheme: Bool = true) {
        self.urlString = urlString
        self.asHttp = asHttp
        self.onlyHttpOrHttpsScheme = onlyHttpOrHttpsScheme
    }
}
