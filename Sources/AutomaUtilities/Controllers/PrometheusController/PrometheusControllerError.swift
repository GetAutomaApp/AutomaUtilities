// PrometheusControllerError.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

/// Represents errors that can occur in the Prometheus controller.
internal enum PrometheusControllerError: Error {
    /// Error indicating failure to convert metrics data to a string.
    case couldNotConvertMetricsToData

    /// Error indicating an invalid authentication token.
    case invalidAuthToken
}
