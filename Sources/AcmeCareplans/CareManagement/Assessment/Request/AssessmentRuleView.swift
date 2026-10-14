import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment rule.
    final class AssessmentRuleView {
        var code: String
        var label: String
        var version: String
        var title: String
        var ratio: String
        var wardText: String
        var visitMinutesText: String
        var createdAt: String
        var ownerID: String
        var active: String
        var statusLabel: String

        init(code: String, label: String, version: String, title: String, ratio: String, wardText: String, visitMinutesText: String, createdAt: String, ownerID: String, active: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.version = version
            self.title = title
            self.ratio = ratio
            self.wardText = wardText
            self.visitMinutesText = visitMinutesText
            self.createdAt = createdAt
            self.ownerID = ownerID
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentRuleView(_ item: AssessmentRule) -> AssessmentRuleView {
        return AssessmentRuleView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            version: String(item.version),
            title: item.title,
            ratio: String(format: "%.2f", item.ratio),
            wardText: item.ward,
            visitMinutesText: String(item.visitMinutes),
            createdAt: String(item.createdAt),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentRuleViews(_ items: [AssessmentRule]) -> [AssessmentRuleView] {
        var views: [AssessmentRuleView] = []
        for item in items {
            views.append(toAssessmentRuleView(item))
        }
        return views
    }

    static func sumAssessmentRuleView(_ view: AssessmentRuleView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedVersion) + parsedRatio + Double(parsedVisitMinutes)
    }
}
