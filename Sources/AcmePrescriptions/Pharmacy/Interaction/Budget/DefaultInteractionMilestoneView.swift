import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a default interaction milestone.
    final class DefaultInteractionMilestoneView {
        var codeText: String
        var labelText: String
        var createdAtText: String
        var visitMinutesText: String
        var pinnedText: String
        var segment: String
        var priority: String
        var summary: String
        var batchSize: String
        var version: String
        var statusLabel: String

        init(codeText: String, labelText: String, createdAtText: String, visitMinutesText: String, pinnedText: String, segment: String, priority: String, summary: String, batchSize: String, version: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.createdAtText = createdAtText
            self.visitMinutesText = visitMinutesText
            self.pinnedText = pinnedText
            self.segment = segment
            self.priority = priority
            self.summary = summary
            self.batchSize = batchSize
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultInteractionMilestoneView(_ item: DefaultInteractionMilestone) -> DefaultInteractionMilestoneView {
        return DefaultInteractionMilestoneView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            createdAtText: String(item.createdAt),
            visitMinutesText: String(item.visitMinutes),
            pinnedText: "\(item.pinned)",
            segment: item.segment,
            priority: String(item.priority),
            summary: Kit.Text.truncate(item.summary, limit: 40),
            batchSize: String(item.batchSize),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultInteractionMilestoneViews(_ items: [DefaultInteractionMilestone]) -> [DefaultInteractionMilestoneView] {
        var views: [DefaultInteractionMilestoneView] = []
        for item in items {
            views.append(toDefaultInteractionMilestoneView(item))
        }
        return views
    }

    static func sumDefaultInteractionMilestoneView(_ view: DefaultInteractionMilestoneView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedVisitMinutes) + Double(parsedPriority)
    }
}
