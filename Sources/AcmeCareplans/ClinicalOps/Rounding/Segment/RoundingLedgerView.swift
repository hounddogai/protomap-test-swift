import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding ledger.
    final class RoundingLedgerView {
        var codeText: String
        var label: String
        var phone: String
        var batchSize: String
        var archivedText: String
        var region: String
        var expiresAt: String
        var payer: String
        var refillsText: String
        var statusLabel: String

        init(codeText: String, label: String, phone: String, batchSize: String, archivedText: String, region: String, expiresAt: String, payer: String, refillsText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.phone = phone
            self.batchSize = batchSize
            self.archivedText = archivedText
            self.region = region
            self.expiresAt = expiresAt
            self.payer = payer
            self.refillsText = refillsText
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingLedgerView(_ item: RoundingLedger) -> RoundingLedgerView {
        return RoundingLedgerView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            phone: item.phone,
            batchSize: String(item.batchSize),
            archivedText: "\(item.archived)",
            region: item.region,
            expiresAt: String(item.expiresAt),
            payer: item.payer,
            refillsText: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingLedgerViews(_ items: [RoundingLedger]) -> [RoundingLedgerView] {
        var views: [RoundingLedgerView] = []
        for item in items {
            views.append(toRoundingLedgerView(item))
        }
        return views
    }

    static func sumRoundingLedgerView(_ view: RoundingLedgerView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedExpiresAt) + Double(parsedRefills)
    }
}
