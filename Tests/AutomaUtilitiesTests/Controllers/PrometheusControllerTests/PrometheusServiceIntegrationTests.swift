// PrometheusServiceIntegrationTests.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import AsyncHTTPClient
@testable import AutomaUtilities
import FlyingFox
import Testing

@Suite("PrometheusServiceIntegrationTests")
internal struct PrometheusServiceIntegrationTests {
    @Test("Test metrics route")
    public func metricsRoute() async throws {
        AutomaUtilitiesMetric.totalDiscordWebhookMessagesSent.increment()
        let service = PrometheusService()
        try await service.startServer()
        let client = HTTPClient()
        let res = try await client.get(url: "http://localhost:6834/metrics").get()
        guard
            let bodyBuffer = res.body
        else {
            #expect(Bool(false), "Response body is nil, should be a ByteBuffer")
            return
        }
        let body = String(buffer: bodyBuffer)
        #expect(body.isEmpty == false, "expect that metrics isn't empty")
        try await client.shutdown()
    }
}
