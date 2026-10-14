import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a strict credential bundle.
    final class StrictCredentialBundleView {
        var code: String
        var name: String
        var descriptionText: String
        var expiresAtText: String
        var cost: String
        var threshold: String
        var score: String
        var activeText: String
        var quantity: String
        var statusLabel: String

        init(code: String, name: String, descriptionText: String, expiresAtText: String, cost: String, threshold: String, score: String, activeText: String, quantity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.descriptionText = descriptionText
            self.expiresAtText = expiresAtText
            self.cost = cost
            self.threshold = threshold
            self.score = score
            self.activeText = activeText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toStrictCredentialBundleView(_ item: StrictCredentialBundle) -> StrictCredentialBundleView {
        return StrictCredentialBundleView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 80),
            descriptionText: item.description,
            expiresAtText: String(item.expiresAt),
            cost: String(format: "%.2f", item.cost),
            threshold: String(format: "%.2f", item.threshold),
            score: String(format: "%.2f", item.score),
            activeText: "\(item.active)",
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictCredentialBundleViews(_ items: [StrictCredentialBundle]) -> [StrictCredentialBundleView] {
        var views: [StrictCredentialBundleView] = []
        for item in items {
            views.append(toStrictCredentialBundleView(item))
        }
        return views
    }

    static func sumStrictCredentialBundleView(_ view: StrictCredentialBundleView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedExpiresAt) + parsedCost + parsedThreshold
    }
}
