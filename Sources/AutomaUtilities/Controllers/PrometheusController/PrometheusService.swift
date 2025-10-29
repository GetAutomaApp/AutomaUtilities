// PrometheusService.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import FlyingFox
import Prometheus
import Vapor

public struct PrometheusService {
    public init() {}

    @discardableResult
    public func startServer(port: UInt16 = 6_834) async throws -> FlyingFox.HTTPServer {
        let metricsServerPort = UInt16(port)
        var server = HTTPServer(port: metricsServerPort)
        await registerServerRoutes(server: &server)
        Task {
            try await server.run()
        }
        try await server.waitUntilListening()
        return server
    }

    private func registerServerRoutes(server: inout FlyingFox.HTTPServer) async {
        await server.appendRoute("metrics") { _ in
            guard
                let metrics = String(data: MetricsService.global.emit(), encoding: .utf8)
            else {
                try MessageService().sendDiscordAlert(
                    alertTitle: "Could not convert metrics to string.",
                    error: PrometheusServiceError.couldNotConvertMetricsToData,
                    logger: Logger(label: "prometheus-service")
                )
                throw PrometheusServiceError.couldNotConvertMetricsToData
            }
            guard
                let data = metrics.data(using: .utf8)
            else {
                throw AutomaGenericErrors
                    .guardFailed(
                        message: "Could not convert metrics string '\(metrics)' to type `Data`."
                    )
            }
            return .init(
                statusCode: .ok,
                headers: [.contentType: "text/plain; version=0.0.4; charset=utf-8; escaping=underscores"],
                body: .init(data: data),
            )
        }
    }
}
