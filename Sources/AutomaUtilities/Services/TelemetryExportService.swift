// TelemetryExportService.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Foundation
import OTel
import OpenTelemetryApi
import OpenTelemetryProtocolExporterHttp
import OpenTelemetrySdk
import Vapor

public enum TelemetryExportService {

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
        static let exportIntervalMs = "OTEL_BSP_SCHEDULE_DELAY_MS"
        static let exportTimeoutMs = "OTEL_BSP_EXPORT_TIMEOUT_MS"
        static let maxQueueSize = "OTEL_BSP_MAX_QUEUE_SIZE"
        static let maxBatchSize = "OTEL_BSP_MAX_EXPORT_BATCH_SIZE"
    }

    private static let registeredTracerProvider = Locked<TracerProvider?>(nil)
    private static let observabilityTask = Locked<Task<Void, Error>?>(nil)
    private static let didBootstrapTracingBackend = Locked(false)

    public static func configureGrafanaTempoTracing(serviceName: String) throws -> TracerProvider {

        try bootstrapTracingBackendIfNeeded()

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

        let exporter = OtlpHttpTraceExporter(
            endpoint: endpoint,
            envVarHeaders: headers
        )

        let processor = BatchSpanProcessor(
            spanExporter: exporter,
            scheduleDelay: TimeInterval(parseInt(Keys.exportIntervalMs, defaultValue: 1000))
                / 1000.0,
            exportTimeout: TimeInterval(parseInt(Keys.exportTimeoutMs, defaultValue: 30000))
                / 1000.0,
            maxQueueSize: parseInt(Keys.maxQueueSize, defaultValue: 2048),
            maxExportBatchSize: parseInt(Keys.maxBatchSize, defaultValue: 512)
        )

        let resource = Resource(attributes: resourceAttributes(serviceName: serviceName))

        let tracerProvider = TracerProviderBuilder()
            .add(spanProcessor: processor)
            .with(resource: resource)
            .build()

        OpenTelemetry.registerTracerProvider(tracerProvider: tracerProvider)

        registeredTracerProvider.withLock { $0 = tracerProvider }

        return tracerProvider
    }

    private static func bootstrapTracingBackendIfNeeded() throws {

        let alreadyBootstrapped = didBootstrapTracingBackend.get()
        guard !alreadyBootstrapped else { return }

        var config = OTel.Configuration.default
        config.logs.enabled = false
        config.metrics.enabled = false

        let observability = try OTel.bootstrap(configuration: config)

        let task = Task(priority: .background) {
            try await observability.run()
        }

        observabilityTask.withLock { $0 = task }
        didBootstrapTracingBackend.withLock { $0 = true }
    }

    public static func shutdownTelemetry(timeout: TimeInterval? = nil) {

        observabilityTask.withLock {
            $0?.cancel()
            $0 = nil
        }

        didBootstrapTracingBackend.withLock { $0 = false }

        guard let provider = registeredTracerProvider.get(),
            let sdkProvider = provider as? TracerProviderSdk
        else {
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
        value > 0
    else {
        return defaultValue
    }
    return value
}

extension TelemetryExportService {

    fileprivate static func resourceAttributes(serviceName: String) -> [String: AttributeValue] {

        var attributes: [String: AttributeValue] = [
            "service.name": .string(serviceName)
        ]

        for (entry, value) in telemetryEnvEntries() {
            attributes[entry.attributeKey] = .string(value)
        }

        if let environmentValue = telemetryEnvironmentValue() {
            attributes[telemetryEnvironmentAttributeKey] = .string(environmentValue)
        }

        return attributes
    }

    fileprivate struct FlyEnvEntry {
        let envKey: String
        let attributeKey: String
    }

    fileprivate static let flyEnvEntries: [FlyEnvEntry] = [
        .init(envKey: "FLY_APP_NAME", attributeKey: "fly.app.name"),
        .init(envKey: "FLY_MACHINE_ID", attributeKey: "fly.machine.id"),
        .init(envKey: "FLY_ALLOC_ID", attributeKey: "fly.alloc.id"),
        .init(envKey: "FLY_REGION", attributeKey: "fly.region"),
        .init(envKey: "FLY_PUBLIC_IP", attributeKey: "fly.public.ip"),
        .init(envKey: "FLY_IMAGE_REF", attributeKey: "fly.image.ref"),
        .init(envKey: "FLY_MACHINE_VERSION", attributeKey: "fly.machine.version"),
        .init(envKey: "FLY_PRIVATE_IP", attributeKey: "fly.private.ip"),
        .init(envKey: "FLY_PROCESS_GROUP", attributeKey: "fly.process.group"),
        .init(envKey: "FLY_VM_MEMORY_MB", attributeKey: "fly.vm.memory.mb"),
        .init(envKey: "PRIMARY_REGION", attributeKey: "fly.primary.region"),
    ]

    fileprivate static let telemetryEnvironmentKeys = ["ENVIROMENT", "ENVIRONMENT"]
    fileprivate static let telemetryEnvironmentAttributeKey = "environment"

    fileprivate static func telemetryEnvironmentValue() -> String? {
        for key in telemetryEnvironmentKeys {
            if let raw = Environment.get(key),
                !raw.isEmpty
            {
                return raw
            }
        }
        return nil
    }

    fileprivate static func telemetryEnvEntries() -> [(entry: FlyEnvEntry, value: String)] {
        flyEnvEntries.compactMap { entry in
            guard let value = Environment.get(entry.envKey),
                !value.isEmpty
            else {
                return nil
            }
            return (entry, value)
        }
    }
}
