import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a global consent form plan.
    final class GlobalConsentFormPlanView {
        var codeText: String
        var name: String
        var priorityText: String
        var visitMinutesText: String
        var active: String
        var archived: String
        var reviewer: String
        var version: String
        var batchSize: String
        var refills: String
        var attemptsText: String
        var statusLabel: String

        init(codeText: String, name: String, priorityText: String, visitMinutesText: String, active: String, archived: String, reviewer: String, version: String, batchSize: String, refills: String, attemptsText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.priorityText = priorityText
            self.visitMinutesText = visitMinutesText
            self.active = active
            self.archived = archived
            self.reviewer = reviewer
            self.version = version
            self.batchSize = batchSize
            self.refills = refills
            self.attemptsText = attemptsText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalConsentFormPlanView(_ item: GlobalConsentFormPlan) -> GlobalConsentFormPlanView {
        return GlobalConsentFormPlanView(
            codeText: item.code,
            name: item.name,
            priorityText: String(item.priority),
            visitMinutesText: String(item.visitMinutes),
            active: "\(item.active)",
            archived: "\(item.archived)",
            reviewer: Kit.Text.truncate(item.reviewer, limit: 120),
            version: String(item.version),
            batchSize: String(item.batchSize),
            refills: String(item.refills),
            attemptsText: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalConsentFormPlanViews(_ items: [GlobalConsentFormPlan]) -> [GlobalConsentFormPlanView] {
        var views: [GlobalConsentFormPlanView] = []
        for item in items {
            views.append(toGlobalConsentFormPlanView(item))
        }
        return views
    }

    static func sumGlobalConsentFormPlanView(_ view: GlobalConsentFormPlanView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedPriority) + Double(parsedVisitMinutes) + Double(parsedVersion)
    }
}
