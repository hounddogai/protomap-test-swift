import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a legacy census entry.
    final class LegacyCensusEntryView {
        var codeText: String
        var label: String
        var marginText: String
        var encounterID: String
        var reviewer: String
        var statusLabel: String

        init(codeText: String, label: String, marginText: String, encounterID: String, reviewer: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.marginText = marginText
            self.encounterID = encounterID
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyCensusEntryView(_ item: LegacyCensusEntry) -> LegacyCensusEntryView {
        return LegacyCensusEntryView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            marginText: String(format: "%.2f", item.margin),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyCensusEntryViews(_ items: [LegacyCensusEntry]) -> [LegacyCensusEntryView] {
        var views: [LegacyCensusEntryView] = []
        for item in items {
            views.append(toLegacyCensusEntryView(item))
        }
        return views
    }

    static func sumLegacyCensusEntryView(_ view: LegacyCensusEntryView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
