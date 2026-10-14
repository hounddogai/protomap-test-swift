import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a scheduled bed board rule.
    final class ScheduledBedBoardRuleView {
        var codeText: String
        var nameText: String
        var encounterID: String
        var threshold: String
        var bedText: String
        var graceDays: String
        var checksum: String
        var revision: String
        var maximum: String
        var statusLabel: String

        init(codeText: String, nameText: String, encounterID: String, threshold: String, bedText: String, graceDays: String, checksum: String, revision: String, maximum: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.encounterID = encounterID
            self.threshold = threshold
            self.bedText = bedText
            self.graceDays = graceDays
            self.checksum = checksum
            self.revision = revision
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledBedBoardRuleView(_ item: ScheduledBedBoardRule) -> ScheduledBedBoardRuleView {
        return ScheduledBedBoardRuleView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            encounterID: item.encounterID,
            threshold: String(format: "%.2f", item.threshold),
            bedText: Kit.Text.truncate(item.bed, limit: 40),
            graceDays: String(item.graceDays),
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            revision: String(item.revision),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledBedBoardRuleViews(_ items: [ScheduledBedBoardRule]) -> [ScheduledBedBoardRuleView] {
        var views: [ScheduledBedBoardRuleView] = []
        for item in items {
            views.append(toScheduledBedBoardRuleView(item))
        }
        return views
    }

    static func sumScheduledBedBoardRuleView(_ view: ScheduledBedBoardRuleView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedThreshold + Double(parsedGraceDays) + Double(parsedRevision)
    }
}
