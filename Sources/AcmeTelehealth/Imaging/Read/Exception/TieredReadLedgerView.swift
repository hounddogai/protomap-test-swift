import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a tiered read ledger.
    final class TieredReadLedgerView {
        var code: String
        var nameText: String
        var label: String
        var copay: String
        var sourceText: String
        var statusLabel: String

        init(code: String, nameText: String, label: String, copay: String, sourceText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.label = label
            self.copay = copay
            self.sourceText = sourceText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredReadLedgerView(_ item: TieredReadLedger) -> TieredReadLedgerView {
        return TieredReadLedgerView(
            code: item.code,
            nameText: item.name,
            label: item.label,
            copay: String(format: "%.2f", item.copay),
            sourceText: Kit.Text.truncate(item.source, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredReadLedgerViews(_ items: [TieredReadLedger]) -> [TieredReadLedgerView] {
        var views: [TieredReadLedgerView] = []
        for item in items {
            views.append(toTieredReadLedgerView(item))
        }
        return views
    }

    static func sumTieredReadLedgerView(_ view: TieredReadLedgerView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
