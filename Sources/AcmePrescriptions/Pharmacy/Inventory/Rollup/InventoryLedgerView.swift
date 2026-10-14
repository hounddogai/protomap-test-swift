import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory ledger.
    final class InventoryLedgerView {
        var code: String
        var label: String
        var createdAt: String
        var acuity: String
        var maximum: String
        var description: String
        var pinnedText: String
        var statusLabel: String

        init(code: String, label: String, createdAt: String, acuity: String, maximum: String, description: String, pinnedText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.acuity = acuity
            self.maximum = maximum
            self.description = description
            self.pinnedText = pinnedText
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryLedgerView(_ item: InventoryLedger) -> InventoryLedgerView {
        return InventoryLedgerView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            createdAt: String(item.createdAt),
            acuity: String(item.acuity),
            maximum: String(format: "%.2f", item.maximum),
            description: item.description,
            pinnedText: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryLedgerViews(_ items: [InventoryLedger]) -> [InventoryLedgerView] {
        var views: [InventoryLedgerView] = []
        for item in items {
            views.append(toInventoryLedgerView(item))
        }
        return views
    }

    static func sumInventoryLedgerView(_ view: InventoryLedgerView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedAcuity) + parsedMaximum
    }
}
