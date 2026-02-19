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
    public static func configureGrafanaTempoTracing(serviceName: String) throws -> TracerProvider {
        let endpointString = try Environment.getOrThrow("GRAFANA_TEMPO_OTLP_ENDPOINT")
        guard let endpoint = URL(string: endpointString) else {
            throw AutomaGenericErrors.invalidURL(url: endpointString)
        }

        let instanceId = try Environment.getOrThrow("GRAFANA_TEMPO_INSTANCE_ID")
        let apiKey = try Environment.getOrThrow("GRAFANA_TEMPO_API_KEY")
        let credentials = "\(instanceId):\(apiKey)"
        let authorization = "Basic \(Data(credentials.utf8).base64EncodedString())"

        let exporter = OtlpHttpTraceExporter(
            endpoint: endpoint,
            envVarHeaders: [
                ("Authorization", authorization)
            ]
        )
        let processor = BatchSpanProcessor(spanExporter: exporter)
        let resource = Resource(
            attributes: [
                "service.name": .string(serviceName)
            ]
        )

        let tracerProvider = TracerProviderBuilder()
            .add(spanProcessor: processor)
            .with(resource: resource)
            .build()

        OpenTelemetry.registerTracerProvider(tracerProvider: tracerProvider)
        return tracerProvider
    }
}
