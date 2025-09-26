// DiscordWebhookMessage.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Foundation

/// Represents a Discord webhook message.
internal struct DiscordWebhookMessage: Codable {
    /// The content of the message.
    public var content: String?
    /// The username to display for the message.
    public var username: String?
    /// The URL of the avatar to display for the message.
    public var avatarURL: String?
    /// The embeds to include in the message.
    public var embeds: [DiscordEmbed]?

    public enum CodingKeys: String, CodingKey {
        case avatarURL = "avatar_url"
    }
}

/// Represents an embed in a Discord webhook message.
internal struct DiscordEmbed: Codable {
    /// The title of the embed.
    public var title: String?
    /// The description of the embed.
    public var description: String?
    /// The URL associated with the embed.
    public var url: String?
    /// The timestamp of the embed.
    public var timestamp: String?
    /// The color of the embed.
    public var color: Int?
    /// The fields to include in the embed.
    public var fields: [DiscordEmbedField]?
    /// The footer of the embed.
    public var footer: DiscordEmbedFooter?
    /// The image to include in the embed.
    public var image: DiscordEmbedImage?
    /// The thumbnail to include in the embed.
    public var thumbnail: DiscordEmbedImage?
    /// The author of the embed.
    public var author: DiscordEmbedAuthor?
    /// The provider of the embed.
    public var provider: DiscordEmbedProvider?
    /// The video to include in the embed.
    public var video: DiscordEmbedVideo?
}

/// Represents a field in a Discord embed.
internal struct DiscordEmbedField: Codable {
    /// The name of the field.
    public var name: String
    /// The value of the field.
    public var value: String
    /// Whether the field should be displayed inline.
    public var inline: Bool
}

/// Represents the footer of a Discord embed.
internal struct DiscordEmbedFooter: Codable {
    /// The text of the footer.
    public var text: String
    /// The URL of the icon to display in the footer.
    public var iconURL: String?

    public enum CodingKeys: String, CodingKey {
        case iconURL = "icon_url"
        case text
    }
}

/// Represents an image in a Discord embed.
internal struct DiscordEmbedImage: Codable {
    /// The URL of the image.
    public var url: String?
}

/// Represents the author of a Discord embed.
internal struct DiscordEmbedAuthor: Codable {
    /// The name of the author.
    public var name: String
    /// The URL associated with the author.
    public var url: String?
    /// The URL of the icon to display for the author.
    public var iconURL: String?

    public enum CodingKeys: String, CodingKey {
        case iconURL = "icon_url"
        case url
        case name
    }
}

/// Represents the provider of a Discord embed.
internal struct DiscordEmbedProvider: Codable {
    /// The name of the provider.
    public var name: String
    /// The URL associated with the provider.
    public var url: String
}

/// Represents a video in a Discord embed.
internal struct DiscordEmbedVideo: Codable {
    /// The URL of the video.
    public var url: String
}
