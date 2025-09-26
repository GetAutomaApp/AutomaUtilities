// PrometheusControllerIntegrationTests.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

@testable import AutomaUtilities
import Testing
import VaporTesting

/// Integration tests for the `PrometheusController`.
/// These tests verify the controller's ability to handle requests and return metrics data.
@Suite("PrometheusControllerIntegrationTests")
internal struct PrometheusControllerIntegrationTests {
    /// Helper method to create a test application instance for each test.
    /// This method handles proper setup and teardown of the application.
    ///
    /// - Parameter test: A closure that takes an `Application` instance and performs test operations.
    /// - Throws: Any errors that occur during test execution or application setup/teardown.
    private func withApp(_ test: (Application) async throws -> Void) async throws {
        let app = try await Application.make(.testing)
        do {
            // Register the `PrometheusController` with the application
            try app.register(collection: PrometheusController())
            // Execute the test closure with the application instance
            try await test(app)
        } catch {
            // Shut down the application in case of errors
            try await app.asyncShutdown()
            throw error
        }
        // Ensure proper cleanup by shutting down the application
        try await app.asyncShutdown()
    }

    /// Tests the ability to request metrics data from the Prometheus controller.
    /// Verifies that the response status is OK and the metrics data is returned.
    ///
    /// - Throws: Any errors that occur during test execution or request handling.
    @Test("Test Request")
    public func request() async throws {
        try await withApp { app in
            // Retrieve the Fly metrics token from the environment
            let token = try Environment.getOrThrow("FLY_METRICS_TOKEN")
            // Send a GET request to the Prometheus metrics endpoint
            try await app.testing().test(.GET, "Prometheus/metrics?auth_token=\(token)") { res async in
                // Expect the response status to be OK
                #expect(res.status == .ok)
            }
        }
    }
}
