// TracingService.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Foundation
import Vapor
import Logging
import OpenTelemetryApi
import OpenTelemetrySdk
import OpenTelemetryProtocolExporterHttp

public enum TracingService {
    private final class Locked<Value>: @unchecked Sendable {
        private var value: Value
        private let lock = NSLock()

        init(_ value: Value) {
            self.value = value
        }

        func withLock<T>(_ body: (inout Value) -> T) -> T {
            lock.lock()
            defer { lock.unlock() }
            return body(&value)
        }

        func get() -> Value {
            withLock { $0 }
        }
    }

    private enum Keys {
        static let endpoint = "GRAFANA_TEMPO_OTLP_ENDPOINT"
        static let instanceId = "GRAFANA_TEMPO_INSTANCE_ID"
        static let apiKey = "GRAFANA_TEMPO_API_KEY"
        static let debugExporter = "OTEL_DEBUG_EXPORTER"
        static let exportIntervalMs = "OTEL_BSP_SCHEDULE_DELAY_MS"
        static let exportTimeoutMs = "OTEL_BSP_EXPORT_TIMEOUT_MS"
        static let maxQueueSize = "OTEL_BSP_MAX_QUEUE_SIZE"
        static let maxBatchSize = "OTEL_BSP_MAX_EXPORT_BATCH_SIZE"
    }

    private static let registeredTracerProvider = Locked<TracerProvider?>(nil)

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

        let baseExporter = OtlpHttpTraceExporter(endpoint: endpoint, envVarHeaders: headers)
        let exporter: SpanExporter
        if let debugFlag = Environment.get(Keys.debugExporter),
           debugFlag.lowercased() == "true" {
            let logger = Logger(label: "otel-exporter")
            exporter = DebugSpanExporter(baseExporter: baseExporter, logger: logger)
        } else {
            exporter = baseExporter
        }

        let processor = BatchSpanProcessor(
            spanExporter: exporter,
            scheduleDelay: .milliseconds(parseInt(Keys.exportIntervalMs, defaultValue: 1_000)),
            exportTimeout: .milliseconds(parseInt(Keys.exportTimeoutMs, defaultValue: 30_000)),
            maxQueueSize: parseInt(Keys.maxQueueSize, defaultValue: 2_048),
            maxExportBatchSize: parseInt(Keys.maxBatchSize, defaultValue: 512)
        )
        let resource = Resource(attributes: ["service.name": .string(serviceName)])

        let tracerProvider = TracerProviderBuilder()
            .add(spanProcessor: processor)
            .with(resource: resource)
            .build()

        OpenTelemetry.registerTracerProvider(tracerProvider: tracerProvider)
        registeredTracerProvider.withLock { $0 = tracerProvider }
        return tracerProvider
    }

    /// Shuts down the configured tracer provider, giving exporters a chance to flush.
    /// Safe to call multiple times.
    public static func shutdownTracing(timeout: TimeInterval? = nil) {
        guard let provider = registeredTracerProvider.get(),
              let sdkProvider = provider as? TracerProviderSdk else {
            return
        }

        sdkProvider.forceFlush(timeout: timeout)
        sdkProvider.shutdown()
        registeredTracerProvider.withLock { $0 = nil }
    }
}

private func parseInt(_ key: String, defaultValue: Int) -> Int {
    guard let raw = Environment.get(key),
          let value = Int(raw),
          value > 0 else {
        return defaultValue
    }
    return value
}

private final class DebugSpanExporter: SpanExporter {
    private let baseExporter: SpanExporter
    private var logger: Logger

    init(baseExporter: SpanExporter, logger: Logger) {
        self.baseExporter = baseExporter
        self.logger = logger
    }

    func export(spans: [SpanData], explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
        let result = baseExporter.export(spans: spans, explicitTimeout: explicitTimeout)
        if spans.isEmpty {
            logger.info("OTEL export skipped: empty batch")
        } else {
            logger.info("OTEL export batch", metadata: [
                "span_count": .string("\(spans.count)"),
                "result": .string("\(result)")
            ])
        }

        if result != .success {
            logger.error("OTEL export failed", metadata: [
                "span_count": .string("\(spans.count)"),
                "result": .string("\(result)")
            ])
        }
        return result
    }

    func flush(explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
        baseExporter.flush(explicitTimeout: explicitTimeout)
    }

    func shutdown(explicitTimeout: TimeInterval?) {
        baseExporter.shutdown(explicitTimeout: explicitTimeout)
    }
}
