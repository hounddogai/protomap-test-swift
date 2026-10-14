import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a scheduled proxy milestone.
    final class ScheduledProxyMilestoneView {
        var codeText: String
        var labelText: String
        var ward: String
        var refillsText: String
        var notesText: String
        var patientRefText: String
        var createdAt: String
        var statusLabel: String

        init(codeText: String, labelText: String, ward: String, refillsText: String, notesText: String, patientRefText: String, createdAt: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.ward = ward
            self.refillsText = refillsText
            self.notesText = notesText
            self.patientRefText = patientRefText
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledProxyMilestoneView(_ item: ScheduledProxyMilestone) -> ScheduledProxyMilestoneView {
        return ScheduledProxyMilestoneView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            labelText: item.label,
            ward: item.ward,
            refillsText: String(item.refills),
            notesText: Kit.Text.truncate(item.notes, limit: 120),
            patientRefText: item.patientRef,
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledProxyMilestoneViews(_ items: [ScheduledProxyMilestone]) -> [ScheduledProxyMilestoneView] {
        var views: [ScheduledProxyMilestoneView] = []
        for item in items {
            views.append(toScheduledProxyMilestoneView(item))
        }
        return views
    }

    static func sumScheduledProxyMilestoneView(_ view: ScheduledProxyMilestoneView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedRefills) + Double(parsedCreatedAt)
    }
}
