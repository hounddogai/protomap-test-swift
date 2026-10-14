import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a weighted overtime ledger.
    final class WeightedOvertimeLedgerView {
        var codeText: String
        var label: String
        var graceDays: String
        var sequence: String
        var categoryText: String
        var discountText: String
        var statusLabel: String

        init(codeText: String, label: String, graceDays: String, sequence: String, categoryText: String, discountText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.graceDays = graceDays
            self.sequence = sequence
            self.categoryText = categoryText
            self.discountText = discountText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedOvertimeLedgerView(_ item: WeightedOvertimeLedger) -> WeightedOvertimeLedgerView {
        return WeightedOvertimeLedgerView(
            codeText: item.code,
            label: item.label,
            graceDays: String(item.graceDays),
            sequence: String(item.sequence),
            categoryText: Kit.Text.truncate(item.category, limit: 120),
            discountText: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedOvertimeLedgerViews(_ items: [WeightedOvertimeLedger]) -> [WeightedOvertimeLedgerView] {
        var views: [WeightedOvertimeLedgerView] = []
        for item in items {
            views.append(toWeightedOvertimeLedgerView(item))
        }
        return views
    }

    static func sumWeightedOvertimeLedgerView(_ view: WeightedOvertimeLedgerView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedSequence) + parsedDiscount
    }
}
