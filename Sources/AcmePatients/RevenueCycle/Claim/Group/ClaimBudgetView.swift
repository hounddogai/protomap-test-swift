import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim budget.
    final class ClaimBudgetView {
        var code: String
        var title: String
        var notesText: String
        var startsAt: String
        var capacityText: String
        var score: String
        var updatedAtText: String
        var encounterIDText: String
        var externalRef: String
        var minimum: String
        var statusLabel: String

        init(code: String, title: String, notesText: String, startsAt: String, capacityText: String, score: String, updatedAtText: String, encounterIDText: String, externalRef: String, minimum: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.notesText = notesText
            self.startsAt = startsAt
            self.capacityText = capacityText
            self.score = score
            self.updatedAtText = updatedAtText
            self.encounterIDText = encounterIDText
            self.externalRef = externalRef
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toClaimBudgetView(_ item: ClaimBudget) -> ClaimBudgetView {
        return ClaimBudgetView(
            code: item.code,
            title: item.title,
            notesText: item.notes,
            startsAt: String(item.startsAt),
            capacityText: String(item.capacity),
            score: String(format: "%.2f", item.score),
            updatedAtText: String(item.updatedAt),
            encounterIDText: item.encounterID,
            externalRef: item.externalRef,
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimBudgetViews(_ items: [ClaimBudget]) -> [ClaimBudgetView] {
        var views: [ClaimBudgetView] = []
        for item in items {
            views.append(toClaimBudgetView(item))
        }
        return views
    }

    static func sumClaimBudgetView(_ view: ClaimBudgetView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedCapacity) + parsedScore
    }
}
