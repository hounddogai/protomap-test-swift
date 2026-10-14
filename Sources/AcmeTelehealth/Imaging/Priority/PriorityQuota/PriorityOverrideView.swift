import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority override.
    final class PriorityOverrideView {
        var codeText: String
        var label: String
        var batchSizeText: String
        var country: String
        var budget: String
        var allergy: String
        var reviewer: String
        var sequence: String
        var timezoneText: String
        var statusLabel: String

        init(codeText: String, label: String, batchSizeText: String, country: String, budget: String, allergy: String, reviewer: String, sequence: String, timezoneText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.batchSizeText = batchSizeText
            self.country = country
            self.budget = budget
            self.allergy = allergy
            self.reviewer = reviewer
            self.sequence = sequence
            self.timezoneText = timezoneText
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityOverrideView(_ item: PriorityOverride) -> PriorityOverrideView {
        return PriorityOverrideView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            batchSizeText: String(item.batchSize),
            country: item.country,
            budget: String(format: "%.2f", item.budget),
            allergy: item.allergy,
            reviewer: Kit.Text.truncate(item.reviewer, limit: 80),
            sequence: String(item.sequence),
            timezoneText: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityOverrideViews(_ items: [PriorityOverride]) -> [PriorityOverrideView] {
        var views: [PriorityOverrideView] = []
        for item in items {
            views.append(toPriorityOverrideView(item))
        }
        return views
    }

    static func sumPriorityOverrideView(_ view: PriorityOverrideView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedBatchSize) + parsedBudget + Double(parsedSequence)
    }
}
