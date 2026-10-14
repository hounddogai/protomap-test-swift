import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a fallback cleaning ledger.
    final class FallbackCleaningLedgerView {
        var code: String
        var label: String
        var facilityText: String
        var startsAt: String
        var ceiling: String
        var statusLabel: String

        init(code: String, label: String, facilityText: String, startsAt: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.facilityText = facilityText
            self.startsAt = startsAt
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackCleaningLedgerView(_ item: FallbackCleaningLedger) -> FallbackCleaningLedgerView {
        return FallbackCleaningLedgerView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            facilityText: item.facility,
            startsAt: String(item.startsAt),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackCleaningLedgerViews(_ items: [FallbackCleaningLedger]) -> [FallbackCleaningLedgerView] {
        var views: [FallbackCleaningLedgerView] = []
        for item in items {
            views.append(toFallbackCleaningLedgerView(item))
        }
        return views
    }

    static func sumFallbackCleaningLedgerView(_ view: FallbackCleaningLedgerView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedStartsAt) + parsedCeiling
    }
}
