import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a default charge ledger.
    final class DefaultChargeLedgerView {
        var code: String
        var label: String
        var expiresAt: String
        var maximum: String
        var archived: String
        var checksum: String
        var title: String
        var ratioText: String
        var statusLabel: String

        init(code: String, label: String, expiresAt: String, maximum: String, archived: String, checksum: String, title: String, ratioText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.maximum = maximum
            self.archived = archived
            self.checksum = checksum
            self.title = title
            self.ratioText = ratioText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultChargeLedgerView(_ item: DefaultChargeLedger) -> DefaultChargeLedgerView {
        return DefaultChargeLedgerView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            expiresAt: String(item.expiresAt),
            maximum: String(format: "%.2f", item.maximum),
            archived: "\(item.archived)",
            checksum: item.checksum,
            title: Kit.Text.truncate(item.title, limit: 64),
            ratioText: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultChargeLedgerViews(_ items: [DefaultChargeLedger]) -> [DefaultChargeLedgerView] {
        var views: [DefaultChargeLedgerView] = []
        for item in items {
            views.append(toDefaultChargeLedgerView(item))
        }
        return views
    }

    static func sumDefaultChargeLedgerView(_ view: DefaultChargeLedgerView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedExpiresAt) + parsedMaximum + parsedRatio
    }
}
