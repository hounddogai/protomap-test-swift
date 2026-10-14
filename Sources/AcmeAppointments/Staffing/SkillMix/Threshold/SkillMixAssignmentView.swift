import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix assignment.
    final class SkillMixAssignmentView {
        var codeText: String
        var name: String
        var capacity: String
        var reviewer: String
        var ward: String
        var visitMinutesText: String
        var statusLabel: String

        init(codeText: String, name: String, capacity: String, reviewer: String, ward: String, visitMinutesText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.capacity = capacity
            self.reviewer = reviewer
            self.ward = ward
            self.visitMinutesText = visitMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixAssignmentView(_ item: SkillMixAssignment) -> SkillMixAssignmentView {
        return SkillMixAssignmentView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 120),
            capacity: String(item.capacity),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 80),
            ward: item.ward,
            visitMinutesText: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixAssignmentViews(_ items: [SkillMixAssignment]) -> [SkillMixAssignmentView] {
        var views: [SkillMixAssignmentView] = []
        for item in items {
            views.append(toSkillMixAssignmentView(item))
        }
        return views
    }

    static func sumSkillMixAssignmentView(_ view: SkillMixAssignmentView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedCapacity) + Double(parsedVisitMinutes)
    }
}
