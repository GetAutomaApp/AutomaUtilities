// PrometheusController.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Prometheus
import Vapor

/// Controller for handling Prometheus metrics requests.
public struct PrometheusController: RouteCollection, Sendable {
    public init() {}

    /// Registers routes for Prometheus operations.
    /// - Parameter routes: The routes builder to register routes on.
    public func boot(routes: RoutesBuilder) throws {
        let prometheusRoute = routes.grouped("Prometheus")

        prometheusRoute.get("metrics", use: metrics)
    }

    /// Retrieves Prometheus metrics.
    /// - Parameter req: The request object.
    /// - Returns: A string containing the metrics data.
    /// - Throws: An error if metrics retrieval or conversion fails.
    @Sendable
    public func metrics(req: Request) throws -> String {
        try validate(req: req)
        guard
            let metrics = String(data: MetricsService.global.emit(), encoding: .utf8)
        else {
            try MessageService().sendDiscordAlert(
                alertTitle: "Could not convert metrics to string.",
                error: PrometheusControllerError.couldNotConvertMetricsToData,
                logger: req.logger
            )
            throw PrometheusControllerError.couldNotConvertMetricsToData
        }
        return metrics
    }

    /// Validates the request for Prometheus metrics.
    /// - Parameter req: The request object.
    /// - Throws: An error if the authentication token is invalid.
    private func validate(req: Request) throws {
        let query = try req.query.decode(PrometheusRouteQuery.self)
        let token = try Environment.getOrThrow("FLY_METRICS_TOKEN")

        guard query.authToken == token else {
            throw PrometheusControllerError.invalidAuthToken
        }
    }
}

/// Represents the query parameters for Prometheus routes.
internal struct PrometheusRouteQuery: Content {
    /// The authentication token for accessing Prometheus metrics.
    public let authToken: String

    /// Coding keys to map the JSON keys to the struct properties.
    public enum CodingKeys: String, CodingKey {
        case authToken = "auth_token"
    }
}
