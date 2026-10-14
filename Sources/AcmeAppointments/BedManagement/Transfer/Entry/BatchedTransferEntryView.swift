import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a batched transfer entry.
    final class BatchedTransferEntryView {
        var code: String
        var name: String
        var thresholdText: String
        var description: String
        var clinicianID: String
        var limit: String
        var channel: String
        var statusLabel: String

        init(code: String, name: String, thresholdText: String, description: String, clinicianID: String, limit: String, channel: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.thresholdText = thresholdText
            self.description = description
            self.clinicianID = clinicianID
            self.limit = limit
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedTransferEntryView(_ item: BatchedTransferEntry) -> BatchedTransferEntryView {
        return BatchedTransferEntryView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            thresholdText: String(format: "%.2f", item.threshold),
            description: item.description,
            clinicianID: item.clinicianID,
            limit: String(item.limit),
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedTransferEntryViews(_ items: [BatchedTransferEntry]) -> [BatchedTransferEntryView] {
        var views: [BatchedTransferEntryView] = []
        for item in items {
            views.append(toBatchedTransferEntryView(item))
        }
        return views
    }

    static func sumBatchedTransferEntryView(_ view: BatchedTransferEntryView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedThreshold + Double(parsedLimit)
    }
}
