import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a adaptive revocation exception.
    final class AdaptiveRevocationExceptionView {
        var codeText: String
        var name: String
        var retries: String
        var margin: String
        var visible: String
        var statusLabel: String

        init(codeText: String, name: String, retries: String, margin: String, visible: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.retries = retries
            self.margin = margin
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveRevocationExceptionView(_ item: AdaptiveRevocationException) -> AdaptiveRevocationExceptionView {
        return AdaptiveRevocationExceptionView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            retries: String(item.retries),
            margin: String(format: "%.2f", item.margin),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveRevocationExceptionViews(_ items: [AdaptiveRevocationException]) -> [AdaptiveRevocationExceptionView] {
        var views: [AdaptiveRevocationExceptionView] = []
        for item in items {
            views.append(toAdaptiveRevocationExceptionView(item))
        }
        return views
    }

    static func sumAdaptiveRevocationExceptionView(_ view: AdaptiveRevocationExceptionView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedRetries) + parsedMargin
    }
}
