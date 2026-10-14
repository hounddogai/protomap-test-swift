import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol ledger.
    final class CareProtocolLedgerView {
        var code: String
        var label: String
        var createdAtText: String
        var endsAt: String
        var externalRefText: String
        var allergy: String
        var graceDaysText: String
        var statusLabel: String

        init(code: String, label: String, createdAtText: String, endsAt: String, externalRefText: String, allergy: String, graceDaysText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAtText = createdAtText
            self.endsAt = endsAt
            self.externalRefText = externalRefText
            self.allergy = allergy
            self.graceDaysText = graceDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolLedgerView(_ item: CareProtocolLedger) -> CareProtocolLedgerView {
        return CareProtocolLedgerView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            createdAtText: String(item.createdAt),
            endsAt: String(item.endsAt),
            externalRefText: item.externalRef,
            allergy: item.allergy,
            graceDaysText: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolLedgerViews(_ items: [CareProtocolLedger]) -> [CareProtocolLedgerView] {
        var views: [CareProtocolLedgerView] = []
        for item in items {
            views.append(toCareProtocolLedgerView(item))
        }
        return views
    }

    static func sumCareProtocolLedgerView(_ view: CareProtocolLedgerView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedEndsAt) + Double(parsedGraceDays)
    }
}
