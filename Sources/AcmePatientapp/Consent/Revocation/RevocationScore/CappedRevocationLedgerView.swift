import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a capped revocation ledger.
    final class CappedRevocationLedgerView {
        var code: String
        var nameText: String
        var patientRefText: String
        var channelText: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, nameText: String, patientRefText: String, channelText: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.patientRefText = patientRefText
            self.channelText = channelText
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toCappedRevocationLedgerView(_ item: CappedRevocationLedger) -> CappedRevocationLedgerView {
        return CappedRevocationLedgerView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 120),
            channelText: item.channel,
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedRevocationLedgerViews(_ items: [CappedRevocationLedger]) -> [CappedRevocationLedgerView] {
        var views: [CappedRevocationLedgerView] = []
        for item in items {
            views.append(toCappedRevocationLedgerView(item))
        }
        return views
    }

    static func sumCappedRevocationLedgerView(_ view: CappedRevocationLedgerView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedExpiresAt)
    }
}
