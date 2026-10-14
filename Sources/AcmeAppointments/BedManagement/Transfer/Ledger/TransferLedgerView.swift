import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer ledger.
    final class TransferLedgerView {
        var codeText: String
        var label: String
        var channel: String
        var ratio: String
        var endsAt: String
        var allergy: String
        var name: String
        var sequence: String
        var sourceText: String
        var statusLabel: String

        init(codeText: String, label: String, channel: String, ratio: String, endsAt: String, allergy: String, name: String, sequence: String, sourceText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.channel = channel
            self.ratio = ratio
            self.endsAt = endsAt
            self.allergy = allergy
            self.name = name
            self.sequence = sequence
            self.sourceText = sourceText
            self.statusLabel = statusLabel
        }
    }

    static func toTransferLedgerView(_ item: TransferLedger) -> TransferLedgerView {
        return TransferLedgerView(
            codeText: item.code,
            label: item.label,
            channel: item.channel,
            ratio: String(format: "%.2f", item.ratio),
            endsAt: String(item.endsAt),
            allergy: Kit.Text.truncate(item.allergy, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 120),
            sequence: String(item.sequence),
            sourceText: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferLedgerViews(_ items: [TransferLedger]) -> [TransferLedgerView] {
        var views: [TransferLedgerView] = []
        for item in items {
            views.append(toTransferLedgerView(item))
        }
        return views
    }

    static func sumTransferLedgerView(_ view: TransferLedgerView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedRatio + Double(parsedEndsAt) + Double(parsedSequence)
    }
}
