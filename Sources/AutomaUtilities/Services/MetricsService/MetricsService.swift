// MetricsService.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Foundation
import Metrics
import Prometheus

/// Service for managing and emitting metrics.
public struct MetricsService: Sendable {
    /// Global instance of the `MetricsService`.
    public static let global = Self()

    /// Prometheus collector registry for managing metrics.
    private var prometheus: PrometheusCollectorRegistry

    /// Initializes a new instance of `MetricsService`.
    private init() {
        let prometheusRegistry = PrometheusCollectorRegistry()
        let myProm = PrometheusMetricsFactory(registry: prometheusRegistry)
        MetricsSystem.bootstrap(myProm)

        prometheus = prometheusRegistry
    }

    /// Emits metrics into a buffer and returns the data.
    /// - Returns: A `Data` object containing the emitted metrics.
    public func emit() -> Data {
        var buffer = [UInt8]()
        prometheus.emit(into: &buffer)
        let data = String(decoding: buffer, as: Unicode.UTF8.self)
        return Data(data.utf8)
    }

    /// Creates a counter type metric.
    /// - Parameters:
    ///   - name: The name of the counter.
    ///   - labels: Optional labels for the counter.
    /// - Returns: A `Prometheus.Counter` object.
    public func makeCounter(name: String, labels: [String: String] = [:]) -> Prometheus.Counter {
        prometheus
            .makeCounter(
                name: name,
                labels: convertStringDictionaryToStringMap(labels)
            )
    }

    /// Converts a dictionary of strings to a tuple array.
    /// - Parameter dictionary: The dictionary to convert.
    /// - Returns: An array of tuples representing the dictionary.
    private func convertStringDictionaryToStringMap(_ dictionary: [String: String]) -> [(String, String)] {
        zip(dictionary.keys, dictionary.values).map { ($0.0, $0.1) }
    }
}
