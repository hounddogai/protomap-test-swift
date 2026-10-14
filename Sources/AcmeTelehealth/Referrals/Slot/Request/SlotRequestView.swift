import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot request.
    final class SlotRequestView {
        var codeText: String
        var nameText: String
        var budget: String
        var country: String
        var approvedText: String
        var summary: String
        var retries: String
        var weightText: String
        var margin: String
        var statusLabel: String

        init(codeText: String, nameText: String, budget: String, country: String, approvedText: String, summary: String, retries: String, weightText: String, margin: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.budget = budget
            self.country = country
            self.approvedText = approvedText
            self.summary = summary
            self.retries = retries
            self.weightText = weightText
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toSlotRequestView(_ item: SlotRequest) -> SlotRequestView {
        return SlotRequestView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            budget: String(format: "%.2f", item.budget),
            country: Kit.Text.truncate(item.country, limit: 120),
            approvedText: "\(item.approved)",
            summary: Kit.Text.truncate(item.summary, limit: 80),
            retries: String(item.retries),
            weightText: String(format: "%.2f", item.weight),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotRequestViews(_ items: [SlotRequest]) -> [SlotRequestView] {
        var views: [SlotRequestView] = []
        for item in items {
            views.append(toSlotRequestView(item))
        }
        return views
    }

    static func sumSlotRequestView(_ view: SlotRequestView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedBudget + Double(parsedRetries) + parsedWeight
    }
}
