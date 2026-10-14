import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a pending census allocation.
    final class PendingCensusAllocationView {
        var codeText: String
        var title: String
        var dosageMg: String
        var quantityText: String
        var localeText: String
        var allergy: String
        var graceDaysText: String
        var statusLabel: String

        init(codeText: String, title: String, dosageMg: String, quantityText: String, localeText: String, allergy: String, graceDaysText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.dosageMg = dosageMg
            self.quantityText = quantityText
            self.localeText = localeText
            self.allergy = allergy
            self.graceDaysText = graceDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCensusAllocationView(_ item: PendingCensusAllocation) -> PendingCensusAllocationView {
        return PendingCensusAllocationView(
            codeText: item.code,
            title: item.title,
            dosageMg: String(format: "%.2f", item.dosageMg),
            quantityText: String(item.quantity),
            localeText: item.locale,
            allergy: item.allergy,
            graceDaysText: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCensusAllocationViews(_ items: [PendingCensusAllocation]) -> [PendingCensusAllocationView] {
        var views: [PendingCensusAllocationView] = []
        for item in items {
            views.append(toPendingCensusAllocationView(item))
        }
        return views
    }

    static func sumPendingCensusAllocationView(_ view: PendingCensusAllocationView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedDosageMg + Double(parsedQuantity) + Double(parsedGraceDays)
    }
}
