// AutomaWebCoreAPIEndpointPayload.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

public struct AutomaWebCoreAPIEndpointPayload: Content {
    public let url: URL
    public let scrollToBottom: Bool

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        url = try values.decode(URL.self, forKey: .url)
        guard
            let stb = try? values.decode(Bool.self, forKey: .url)
        else {
            scrollToBottom = false
            return
        }
        scrollToBottom = stb
    }

    public init(url: URL, scrollToBottom: Bool = false) {
        self.url = url
        self.scrollToBottom = scrollToBottom
    }

    // configuration options required to be implemented and handled in route handlers when
    // a service that needs to be able to make a request both with a browser (jsRender) and without a browser
    // (jsRender=false),
    //

    // let jsRender: Bool
    // let residentialProxy: Bool
    // let autoCaptchaSolving: Bool

    public enum CodingKeys: String, CodingKey {
        case url
        case scrollToBottom = "scroll_to_bottom"
        // case jsRender = "js_render"
        // case residentialProxy = "residential_proxy"
        // case autoCaptchaSolving = "auto_captcha_solving"
    }
}
