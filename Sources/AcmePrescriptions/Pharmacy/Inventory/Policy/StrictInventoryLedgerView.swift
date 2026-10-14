import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a strict inventory ledger.
    final class StrictInventoryLedgerView {
        var code: String
        var title: String
        var discount: String
        var patientRef: String
        var batchSizeText: String
        var statusLabel: String

        init(code: String, title: String, discount: String, patientRef: String, batchSizeText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.discount = discount
            self.patientRef = patientRef
            self.batchSizeText = batchSizeText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictInventoryLedgerView(_ item: StrictInventoryLedger) -> StrictInventoryLedgerView {
        return StrictInventoryLedgerView(
            code: item.code,
            title: item.title,
            discount: String(format: "%.2f", item.discount),
            patientRef: item.patientRef,
            batchSizeText: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictInventoryLedgerViews(_ items: [StrictInventoryLedger]) -> [StrictInventoryLedgerView] {
        var views: [StrictInventoryLedgerView] = []
        for item in items {
            views.append(toStrictInventoryLedgerView(item))
        }
        return views
    }

    static func sumStrictInventoryLedgerView(_ view: StrictInventoryLedgerView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedDiscount + Double(parsedBatchSize)
    }
}
