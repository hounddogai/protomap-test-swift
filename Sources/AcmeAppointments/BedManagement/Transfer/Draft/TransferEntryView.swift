import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer entry.
    final class TransferEntryView {
        var code: String
        var labelText: String
        var bed: String
        var priorityText: String
        var version: String
        var timezone: String
        var limit: String
        var channelText: String
        var statusLabel: String

        init(code: String, labelText: String, bed: String, priorityText: String, version: String, timezone: String, limit: String, channelText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.bed = bed
            self.priorityText = priorityText
            self.version = version
            self.timezone = timezone
            self.limit = limit
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toTransferEntryView(_ item: TransferEntry) -> TransferEntryView {
        return TransferEntryView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 120),
            bed: Kit.Text.truncate(item.bed, limit: 64),
            priorityText: String(item.priority),
            version: String(item.version),
            timezone: Kit.Text.truncate(item.timezone, limit: 80),
            limit: String(item.limit),
            channelText: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferEntryViews(_ items: [TransferEntry]) -> [TransferEntryView] {
        var views: [TransferEntryView] = []
        for item in items {
            views.append(toTransferEntryView(item))
        }
        return views
    }

    static func sumTransferEntryView(_ view: TransferEntryView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedPriority) + Double(parsedVersion) + Double(parsedLimit)
    }
}
