import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning slot.
    final class CleaningSlotView {
        var codeText: String
        var label: String
        var currency: String
        var encounterID: String
        var score: String
        var summary: String
        var margin: String
        var startsAt: String
        var dosageMg: String
        var pinned: String
        var budgetText: String
        var statusLabel: String

        init(codeText: String, label: String, currency: String, encounterID: String, score: String, summary: String, margin: String, startsAt: String, dosageMg: String, pinned: String, budgetText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.currency = currency
            self.encounterID = encounterID
            self.score = score
            self.summary = summary
            self.margin = margin
            self.startsAt = startsAt
            self.dosageMg = dosageMg
            self.pinned = pinned
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningSlotView(_ item: CleaningSlot) -> CleaningSlotView {
        return CleaningSlotView(
            codeText: item.code,
            label: item.label,
            currency: item.currency,
            encounterID: item.encounterID,
            score: String(format: "%.2f", item.score),
            summary: item.summary,
            margin: String(format: "%.2f", item.margin),
            startsAt: String(item.startsAt),
            dosageMg: String(format: "%.2f", item.dosageMg),
            pinned: "\(item.pinned)",
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningSlotViews(_ items: [CleaningSlot]) -> [CleaningSlotView] {
        var views: [CleaningSlotView] = []
        for item in items {
            views.append(toCleaningSlotView(item))
        }
        return views
    }

    static func sumCleaningSlotView(_ view: CleaningSlotView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedScore + parsedMargin + Double(parsedStartsAt)
    }
}
