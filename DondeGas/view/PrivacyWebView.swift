//
//  PrivacyWebView.swift
//  DondeGas
//
//  Created by Sergio Frejo on 11/1/24.
//
import SwiftUI
import WebKit

struct PrivacyWebView: UIViewRepresentable {

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator

        webView.loadHTMLString(PrivacyPolicy.htmlText, baseURL: nil)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: PrivacyWebView

        init(_ parent: PrivacyWebView) {
            self.parent = parent
        }
    }
}

