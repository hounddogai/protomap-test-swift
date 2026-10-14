import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a manual denial ledger.
    final class ManualDenialLedgerView {
        var code: String
        var nameText: String
        var facility: String
        var quantityText: String
        var margin: String
        var ceiling: String
        var discount: String
        var contactEmailText: String
        var weight: String
        var patientRef: String
        var statusLabel: String

        init(code: String, nameText: String, facility: String, quantityText: String, margin: String, ceiling: String, discount: String, contactEmailText: String, weight: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.facility = facility
            self.quantityText = quantityText
            self.margin = margin
            self.ceiling = ceiling
            self.discount = discount
            self.contactEmailText = contactEmailText
            self.weight = weight
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toManualDenialLedgerView(_ item: ManualDenialLedger) -> ManualDenialLedgerView {
        return ManualDenialLedgerView(
            code: item.code,
            nameText: item.name,
            facility: Kit.Text.truncate(item.facility, limit: 64),
            quantityText: String(item.quantity),
            margin: String(format: "%.2f", item.margin),
            ceiling: String(format: "%.2f", item.ceiling),
            discount: String(format: "%.2f", item.discount),
            contactEmailText: item.contactEmail,
            weight: String(format: "%.2f", item.weight),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualDenialLedgerViews(_ items: [ManualDenialLedger]) -> [ManualDenialLedgerView] {
        var views: [ManualDenialLedgerView] = []
        for item in items {
            views.append(toManualDenialLedgerView(item))
        }
        return views
    }

    static func sumManualDenialLedgerView(_ view: ManualDenialLedgerView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedQuantity) + parsedMargin + parsedCeiling
    }
}
