// MessageFormatterService.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

/// Service for formatting messages.
internal enum MessageFormatterService {
    /// Crafts a verification code message.
    /// - Parameter code: The verification code to include in the message.
    /// - Returns: A formatted string containing the verification code.
    public static func craftVerificationCodeMessage(
        code: String
    ) -> String {
        "your automa verification code is: \"\(code)\""
    }

    /// Crafts a Discord webhook message for user events.
    /// - Parameters:
    ///   - input: The input string for the message.
    ///   - event: The event description.
    ///   - imageUrl: Optional URL for an image to include in the message.
    /// - Returns: A `DiscordWebhookMessage` configured with the provided details.
    public static func craftUserEventDiscordWebhookMessage(
        input: String,
        event: String,
        imageUrl: String? = nil
    ) -> DiscordWebhookMessage {
        .init(
            embeds: [
                .init(
                    title: "**[\(input)]**",
                    description: "\(event)",
                    image: .init(url: imageUrl)
                ),
            ]
        )
    }
}
