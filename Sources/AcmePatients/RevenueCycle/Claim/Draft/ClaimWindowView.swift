import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim window.
    final class ClaimWindowView {
        var codeText: String
        var name: String
        var limit: String
        var windowDays: String
        var score: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, name: String, limit: String, windowDays: String, score: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.limit = limit
            self.windowDays = windowDays
            self.score = score
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toClaimWindowView(_ item: ClaimWindow) -> ClaimWindowView {
        return ClaimWindowView(
            codeText: item.code,
            name: item.name,
            limit: String(item.limit),
            windowDays: String(item.windowDays),
            score: String(format: "%.2f", item.score),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimWindowViews(_ items: [ClaimWindow]) -> [ClaimWindowView] {
        var views: [ClaimWindowView] = []
        for item in items {
            views.append(toClaimWindowView(item))
        }
        return views
    }

    static func sumClaimWindowView(_ view: ClaimWindowView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedLimit) + Double(parsedWindowDays) + parsedScore
    }
}
