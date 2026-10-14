import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a adaptive read ledger.
    final class AdaptiveReadLedgerView {
        var code: String
        var label: String
        var updatedAt: String
        var ceiling: String
        var facilityText: String
        var statusLabel: String

        init(code: String, label: String, updatedAt: String, ceiling: String, facilityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.ceiling = ceiling
            self.facilityText = facilityText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveReadLedgerView(_ item: AdaptiveReadLedger) -> AdaptiveReadLedgerView {
        return AdaptiveReadLedgerView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            updatedAt: String(item.updatedAt),
            ceiling: String(format: "%.2f", item.ceiling),
            facilityText: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveReadLedgerViews(_ items: [AdaptiveReadLedger]) -> [AdaptiveReadLedgerView] {
        var views: [AdaptiveReadLedgerView] = []
        for item in items {
            views.append(toAdaptiveReadLedgerView(item))
        }
        return views
    }

    static func sumAdaptiveReadLedgerView(_ view: AdaptiveReadLedgerView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedUpdatedAt) + parsedCeiling
    }
}
