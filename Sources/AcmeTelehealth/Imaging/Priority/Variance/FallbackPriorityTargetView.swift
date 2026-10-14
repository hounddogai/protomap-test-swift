import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a fallback priority target.
    final class FallbackPriorityTargetView {
        var code: String
        var titleText: String
        var maximumText: String
        var limit: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, titleText: String, maximumText: String, limit: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.maximumText = maximumText
            self.limit = limit
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackPriorityTargetView(_ item: FallbackPriorityTarget) -> FallbackPriorityTargetView {
        return FallbackPriorityTargetView(
            code: item.code,
            titleText: item.title,
            maximumText: String(format: "%.2f", item.maximum),
            limit: String(item.limit),
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackPriorityTargetViews(_ items: [FallbackPriorityTarget]) -> [FallbackPriorityTargetView] {
        var views: [FallbackPriorityTargetView] = []
        for item in items {
            views.append(toFallbackPriorityTargetView(item))
        }
        return views
    }

    static func sumFallbackPriorityTargetView(_ view: FallbackPriorityTargetView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedMaximum + Double(parsedLimit)
    }
}
