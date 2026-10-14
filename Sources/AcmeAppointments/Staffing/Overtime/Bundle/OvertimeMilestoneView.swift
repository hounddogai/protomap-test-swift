import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime milestone.
    final class OvertimeMilestoneView {
        var codeText: String
        var name: String
        var unit: String
        var endsAt: String
        var labelText: String
        var createdAt: String
        var archivedText: String
        var statusLabel: String

        init(codeText: String, name: String, unit: String, endsAt: String, labelText: String, createdAt: String, archivedText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.unit = unit
            self.endsAt = endsAt
            self.labelText = labelText
            self.createdAt = createdAt
            self.archivedText = archivedText
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeMilestoneView(_ item: OvertimeMilestone) -> OvertimeMilestoneView {
        return OvertimeMilestoneView(
            codeText: item.code,
            name: item.name,
            unit: item.unit,
            endsAt: String(item.endsAt),
            labelText: item.label,
            createdAt: String(item.createdAt),
            archivedText: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeMilestoneViews(_ items: [OvertimeMilestone]) -> [OvertimeMilestoneView] {
        var views: [OvertimeMilestoneView] = []
        for item in items {
            views.append(toOvertimeMilestoneView(item))
        }
        return views
    }

    static func sumOvertimeMilestoneView(_ view: OvertimeMilestoneView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedCreatedAt)
    }
}
