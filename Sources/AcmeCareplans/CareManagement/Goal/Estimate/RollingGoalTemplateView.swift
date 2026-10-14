import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a rolling goal template.
    final class RollingGoalTemplateView {
        var codeText: String
        var label: String
        var ownerID: String
        var unit: String
        var version: String
        var archivedText: String
        var visitMinutesText: String
        var description: String
        var statusLabel: String

        init(codeText: String, label: String, ownerID: String, unit: String, version: String, archivedText: String, visitMinutesText: String, description: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.ownerID = ownerID
            self.unit = unit
            self.version = version
            self.archivedText = archivedText
            self.visitMinutesText = visitMinutesText
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toRollingGoalTemplateView(_ item: RollingGoalTemplate) -> RollingGoalTemplateView {
        return RollingGoalTemplateView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            ownerID: item.ownerID,
            unit: item.unit,
            version: String(item.version),
            archivedText: "\(item.archived)",
            visitMinutesText: String(item.visitMinutes),
            description: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingGoalTemplateViews(_ items: [RollingGoalTemplate]) -> [RollingGoalTemplateView] {
        var views: [RollingGoalTemplateView] = []
        for item in items {
            views.append(toRollingGoalTemplateView(item))
        }
        return views
    }

    static func sumRollingGoalTemplateView(_ view: RollingGoalTemplateView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedVersion) + Double(parsedVisitMinutes)
    }
}
