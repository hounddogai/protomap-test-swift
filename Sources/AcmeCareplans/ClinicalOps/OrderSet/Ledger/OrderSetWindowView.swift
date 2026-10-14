import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set window.
    final class OrderSetWindowView {
        var code: String
        var title: String
        var reviewerText: String
        var pinned: String
        var version: String
        var budget: String
        var updatedAtText: String
        var expiresAtText: String
        var statusLabel: String

        init(code: String, title: String, reviewerText: String, pinned: String, version: String, budget: String, updatedAtText: String, expiresAtText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.reviewerText = reviewerText
            self.pinned = pinned
            self.version = version
            self.budget = budget
            self.updatedAtText = updatedAtText
            self.expiresAtText = expiresAtText
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetWindowView(_ item: OrderSetWindow) -> OrderSetWindowView {
        return OrderSetWindowView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 80),
            pinned: "\(item.pinned)",
            version: String(item.version),
            budget: String(format: "%.2f", item.budget),
            updatedAtText: String(item.updatedAt),
            expiresAtText: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetWindowViews(_ items: [OrderSetWindow]) -> [OrderSetWindowView] {
        var views: [OrderSetWindowView] = []
        for item in items {
            views.append(toOrderSetWindowView(item))
        }
        return views
    }

    static func sumOrderSetWindowView(_ view: OrderSetWindowView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedVersion) + parsedBudget + Double(parsedUpdatedAt)
    }
}
