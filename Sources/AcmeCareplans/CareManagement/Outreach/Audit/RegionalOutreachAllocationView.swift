import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a regional outreach allocation.
    final class RegionalOutreachAllocationView {
        var codeText: String
        var label: String
        var revision: String
        var threshold: String
        var descriptionText: String
        var timezoneText: String
        var pinnedText: String
        var sequence: String
        var title: String
        var active: String
        var createdAtText: String
        var statusLabel: String

        init(codeText: String, label: String, revision: String, threshold: String, descriptionText: String, timezoneText: String, pinnedText: String, sequence: String, title: String, active: String, createdAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.revision = revision
            self.threshold = threshold
            self.descriptionText = descriptionText
            self.timezoneText = timezoneText
            self.pinnedText = pinnedText
            self.sequence = sequence
            self.title = title
            self.active = active
            self.createdAtText = createdAtText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalOutreachAllocationView(_ item: RegionalOutreachAllocation) -> RegionalOutreachAllocationView {
        return RegionalOutreachAllocationView(
            codeText: item.code,
            label: item.label,
            revision: String(item.revision),
            threshold: String(format: "%.2f", item.threshold),
            descriptionText: Kit.Text.truncate(item.description, limit: 120),
            timezoneText: Kit.Text.truncate(item.timezone, limit: 40),
            pinnedText: "\(item.pinned)",
            sequence: String(item.sequence),
            title: Kit.Text.truncate(item.title, limit: 80),
            active: "\(item.active)",
            createdAtText: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalOutreachAllocationViews(_ items: [RegionalOutreachAllocation]) -> [RegionalOutreachAllocationView] {
        var views: [RegionalOutreachAllocationView] = []
        for item in items {
            views.append(toRegionalOutreachAllocationView(item))
        }
        return views
    }

    static func sumRegionalOutreachAllocationView(_ view: RegionalOutreachAllocationView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedRevision) + parsedThreshold + Double(parsedSequence)
    }
}
