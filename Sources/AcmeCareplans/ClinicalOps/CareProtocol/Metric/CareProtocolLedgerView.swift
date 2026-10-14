import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol ledger.
    final class CareProtocolLedgerView {
        var codeText: String
        var name: String
        var retries: String
        var archived: String
        var startsAt: String
        var statusLabel: String

        init(codeText: String, name: String, retries: String, archived: String, startsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.retries = retries
            self.archived = archived
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolLedgerView(_ item: CareProtocolLedger) -> CareProtocolLedgerView {
        return CareProtocolLedgerView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            retries: String(item.retries),
            archived: "\(item.archived)",
            startsAt: String(item.startsAt),
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
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedRetries) + Double(parsedStartsAt)
    }
}
