// TracingService.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Foundation
import Vapor
import OpenTelemetryApi
import OpenTelemetrySdk
import OpenTelemetryProtocolExporterHttp

public enum TracingService {
    private enum Keys {
        static let endpoint = "GRAFANA_TEMPO_OTLP_ENDPOINT"
        static let instanceId = "GRAFANA_TEMPO_INSTANCE_ID"
        static let apiKey = "GRAFANA_TEMPO_API_KEY"
    }

    private static var registeredTracerProvider: TracerProvider?

    /// Configures an OpenTelemetry tracer provider that exports spans to Grafana Tempo.
    /// - Parameter serviceName: The service.name resource attribute that Tempo uses for grouping.
    /// - Returns: The provider that was registered with OpenTelemetry.
    public static func configureGrafanaTempoTracing(serviceName: String) throws -> TracerProvider {
        let endpointString = try Environment.getOrThrow(Keys.endpoint)
        guard let endpoint = URL(string: endpointString) else {
            throw AutomaGenericErrors.invalidURL(url: endpointString)
        }

        let headers: [(String, String)]?
        if let instanceId = Environment.get(Keys.instanceId),
           let apiKey = Environment.get(Keys.apiKey),
           !instanceId.isEmpty,
           !apiKey.isEmpty
        {
            let credentials = "\(instanceId):\(apiKey)"
            let authorization = "Basic \(Data(credentials.utf8).base64EncodedString())"
            headers = [("Authorization", authorization)]
        } else {
            headers = nil
        }

        let exporter = OtlpHttpTraceExporter(endpoint: endpoint, envVarHeaders: headers)

        let processor = BatchSpanProcessor(spanExporter: exporter)
        let resource = Resource(attributes: ["service.name": .string(serviceName)])

        let tracerProvider = TracerProviderBuilder()
            .add(spanProcessor: processor)
            .with(resource: resource)
            .build()

        OpenTelemetry.registerTracerProvider(tracerProvider: tracerProvider)
        registeredTracerProvider = tracerProvider
        return tracerProvider
    }

    /// Shuts down the configured tracer provider, giving exporters a chance to flush.
    /// Safe to call multiple times.
    public static func shutdownTracing(timeout: TimeInterval? = nil) {
        guard let provider = registeredTracerProvider ?? OpenTelemetry.instance.tracerProvider,
              let sdkProvider = provider as? TracerProviderSdk else {
            return
        }

        sdkProvider.forceFlush(timeout: timeout)
        sdkProvider.shutdown()
        registeredTracerProvider = nil
    }
}
