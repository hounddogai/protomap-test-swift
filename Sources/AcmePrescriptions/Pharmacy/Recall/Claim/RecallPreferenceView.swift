import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall preference.
    final class RecallPreferenceView {
        var code: String
        var label: String
        var limit: String
        var updatedAtText: String
        var budget: String
        var graceDays: String
        var createdAt: String
        var approved: String
        var refills: String
        var statusLabel: String

        init(code: String, label: String, limit: String, updatedAtText: String, budget: String, graceDays: String, createdAt: String, approved: String, refills: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.limit = limit
            self.updatedAtText = updatedAtText
            self.budget = budget
            self.graceDays = graceDays
            self.createdAt = createdAt
            self.approved = approved
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toRecallPreferenceView(_ item: RecallPreference) -> RecallPreferenceView {
        return RecallPreferenceView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            limit: String(item.limit),
            updatedAtText: String(item.updatedAt),
            budget: String(format: "%.2f", item.budget),
            graceDays: String(item.graceDays),
            createdAt: String(item.createdAt),
            approved: "\(item.approved)",
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallPreferenceViews(_ items: [RecallPreference]) -> [RecallPreferenceView] {
        var views: [RecallPreferenceView] = []
        for item in items {
            views.append(toRecallPreferenceView(item))
        }
        return views
    }

    static func sumRecallPreferenceView(_ view: RecallPreferenceView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedLimit) + Double(parsedUpdatedAt) + parsedBudget
    }
}
