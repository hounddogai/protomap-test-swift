import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority checkpoint.
    final class PriorityCheckpointView {
        var code: String
        var label: String
        var title: String
        var unit: String
        var encounterID: String
        var score: String
        var currency: String
        var refills: String
        var specialty: String
        var quantity: String
        var cost: String
        var statusLabel: String

        init(code: String, label: String, title: String, unit: String, encounterID: String, score: String, currency: String, refills: String, specialty: String, quantity: String, cost: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.title = title
            self.unit = unit
            self.encounterID = encounterID
            self.score = score
            self.currency = currency
            self.refills = refills
            self.specialty = specialty
            self.quantity = quantity
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityCheckpointView(_ item: PriorityCheckpoint) -> PriorityCheckpointView {
        return PriorityCheckpointView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: Kit.Text.truncate(item.label, limit: 120),
            title: item.title,
            unit: item.unit,
            encounterID: item.encounterID,
            score: String(format: "%.2f", item.score),
            currency: item.currency,
            refills: String(item.refills),
            specialty: item.specialty,
            quantity: String(item.quantity),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityCheckpointViews(_ items: [PriorityCheckpoint]) -> [PriorityCheckpointView] {
        var views: [PriorityCheckpointView] = []
        for item in items {
            views.append(toPriorityCheckpointView(item))
        }
        return views
    }

    static func sumPriorityCheckpointView(_ view: PriorityCheckpointView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedScore + Double(parsedRefills) + Double(parsedQuantity)
    }
}
