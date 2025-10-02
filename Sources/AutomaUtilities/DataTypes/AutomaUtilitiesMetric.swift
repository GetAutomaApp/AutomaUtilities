// AutomaUtilitiesMetric.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Foundation
import Prometheus

/// Enum for managing backend metrics.
internal enum AutomaUtilitiesMetric {
    /// Counter for Discord webhook messages sent.
    public static let totalDiscordWebhookMessagesSent = MetricsService.global.makeCounter(
        name: "total_discord_webhook_messages_sent",
        labels: [
            "status": MetricStatus.success.rawValue,
        ]
    )

    /// Enum representing the status of a metric.
}

public enum MetricStatus: String, Codable {
    /// Indicates that the metric already exists.
    case alreadyExists
    /// Indicates a failure status for the metric.
    case fail
    /// Indicates a start status for the metric.
    case start
    /// Indicates a success status for the metric.
    case success
}
