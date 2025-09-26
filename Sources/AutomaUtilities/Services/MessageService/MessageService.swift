// MessageService.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Foundation
import Vapor

public struct MessageService {
    public init() {}

    public static func sendWebhookMessage(
        webhookURL: URL,
        message: DiscordWebhookMessage,
        logger: Logger
    ) async throws {
        // TODO: make metric a backend metric and backendmetric in infracore infracorebackendmetric
        // BackendMetric.totalDiscordWebhookMessagesSent.increment()

        guard try Environment.getOrThrow("ENVIRONMENT") != "local" else { return }

        do {
            let request = try buildWebhookRequest(url: webhookURL, message: message)
            let (data, response) = try await URLSession.shared.data(for: request)

            try validateWebhookResponse(response, data: data)

            logger.info("Sent Discord webhook message successfully", metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "webhook": .string(webhookURL.absoluteString),
                "response": .string(String(data: data, encoding: .utf8) ?? "")
            ])
        } catch {
            logger.error("Failed to send Discord webhook message", metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "webhook": .string(webhookURL.absoluteString),
                "error": .string(error.localizedDescription)
            ])
            throw AutomaGenericErrors.discordWebHookMessageFailed
        }
    }

    private static func buildWebhookRequest(url: URL, message: DiscordWebhookMessage) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(message)
        return request
    }

    private static func validateWebhookResponse(_ response: URLResponse, data _: Data) throws {
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 204 {
            throw AutomaGenericErrors.discordWebHookMessageFailed
        }
    }

    public func sendDiscordWebhookAppEvent(
        input: String,
        event: String,
        imageUrl: String? = nil,
        logger: Logger,
        withUrl: URL? = nil
    ) throws {
        guard let url = try resolveWebhookURL(override: withUrl, logger: logger, input: input, event: event) else {
            return
        }

        Task.detachedLogOnError(destination: "MessageService.sendDiscordWebhookAppEvent", logger: logger) {
            try await MessageService.sendWebhookMessage(
                webhookURL: url,
                message: MessageFormatterService.craftUserEventDiscordWebhookMessage(
                    input: input,
                    event: event,
                    imageUrl: imageUrl
                ),
                logger: logger
            )
        }
    }

    private func resolveWebhookURL(
        override: URL?,
        logger: Logger,
        input: String,
        event: String
    ) throws -> URL? {
        if let url = override {
            return url
        }

        guard let fallbackUrl = try? URL(string: Environment.getOrThrow("DISCORD_APP_EVENTS_URL")) else {
            logger.error("Could not resolve Discord webhook URL", metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "event": .string(event),
                "input": .string(input)
            ])
            throw Abort(.internalServerError)
        }

        return fallbackUrl
    }

    public func sendDiscordAlert(
        alertTitle: String,
        error: Error,
        logger: Logger
    ) throws {
        guard
            let webhookUrl = try URL(string: Environment.getOrThrow("DISCORD_AUTOMA_ALERTS_WEBHOOK_URL"))
        else {
            throwWebhookURLError(logger: logger, title: alertTitle)
        }

        try sendDiscordWebhookAppEvent(
            input: "Critical Error Occurred - \(alertTitle)",
            event: "\(error) - \(error.localizedDescription)",
            logger: logger,
            withUrl: webhookUrl
        )
    }

    private func throwWebhookURLError(logger: Logger, title: String) -> Never {
        logger.error("Could not resolve Discord webhook URL", metadata: [
            "to": .string("\(String(describing: Self.self)).\(#function)"),
            "alert_title": .string(title)
        ])
        fatalError("Invalid webhook URL")
    }
}
