import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a primary bed board ledger.
    final class PrimaryBedBoardLedgerView {
        var code: String
        var label: String
        var minimum: String
        var allergy: String
        var priority: String
        var statusLabel: String

        init(code: String, label: String, minimum: String, allergy: String, priority: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.allergy = allergy
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryBedBoardLedgerView(_ item: PrimaryBedBoardLedger) -> PrimaryBedBoardLedgerView {
        return PrimaryBedBoardLedgerView(
            code: item.code,
            label: item.label,
            minimum: String(format: "%.2f", item.minimum),
            allergy: Kit.Text.truncate(item.allergy, limit: 64),
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryBedBoardLedgerViews(_ items: [PrimaryBedBoardLedger]) -> [PrimaryBedBoardLedgerView] {
        var views: [PrimaryBedBoardLedgerView] = []
        for item in items {
            views.append(toPrimaryBedBoardLedgerView(item))
        }
        return views
    }

    static func sumPrimaryBedBoardLedgerView(_ view: PrimaryBedBoardLedgerView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedMinimum + Double(parsedPriority)
    }
}
