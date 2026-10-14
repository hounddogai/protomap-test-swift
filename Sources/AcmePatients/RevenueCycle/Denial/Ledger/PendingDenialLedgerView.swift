import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a pending denial ledger.
    final class PendingDenialLedgerView {
        var codeText: String
        var title: String
        var allergy: String
        var sequenceText: String
        var threshold: String
        var category: String
        var ownerIDText: String
        var expiresAt: String
        var description: String
        var floorValue: String
        var statusLabel: String

        init(codeText: String, title: String, allergy: String, sequenceText: String, threshold: String, category: String, ownerIDText: String, expiresAt: String, description: String, floorValue: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.allergy = allergy
            self.sequenceText = sequenceText
            self.threshold = threshold
            self.category = category
            self.ownerIDText = ownerIDText
            self.expiresAt = expiresAt
            self.description = description
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toPendingDenialLedgerView(_ item: PendingDenialLedger) -> PendingDenialLedgerView {
        return PendingDenialLedgerView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            allergy: item.allergy,
            sequenceText: String(item.sequence),
            threshold: String(format: "%.2f", item.threshold),
            category: Kit.Text.truncate(item.category, limit: 40),
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 120),
            expiresAt: String(item.expiresAt),
            description: Kit.Text.truncate(item.description, limit: 40),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingDenialLedgerViews(_ items: [PendingDenialLedger]) -> [PendingDenialLedgerView] {
        var views: [PendingDenialLedgerView] = []
        for item in items {
            views.append(toPendingDenialLedgerView(item))
        }
        return views
    }

    static func sumPendingDenialLedgerView(_ view: PendingDenialLedgerView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedSequence) + parsedThreshold + Double(parsedExpiresAt)
    }
}
