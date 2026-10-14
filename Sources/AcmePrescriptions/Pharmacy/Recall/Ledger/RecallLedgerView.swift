import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall ledger.
    final class RecallLedgerView {
        var code: String
        var name: String
        var bed: String
        var weight: String
        var margin: String
        var acuity: String
        var statusLabel: String

        init(code: String, name: String, bed: String, weight: String, margin: String, acuity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.bed = bed
            self.weight = weight
            self.margin = margin
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toRecallLedgerView(_ item: RecallLedger) -> RecallLedgerView {
        return RecallLedgerView(
            code: item.code,
            name: item.name,
            bed: item.bed,
            weight: String(format: "%.2f", item.weight),
            margin: String(format: "%.2f", item.margin),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallLedgerViews(_ items: [RecallLedger]) -> [RecallLedgerView] {
        var views: [RecallLedgerView] = []
        for item in items {
            views.append(toRecallLedgerView(item))
        }
        return views
    }

    static func sumRecallLedgerView(_ view: RecallLedgerView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedWeight + parsedMargin + Double(parsedAcuity)
    }
}
