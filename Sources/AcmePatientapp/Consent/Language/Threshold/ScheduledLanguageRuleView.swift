import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a scheduled language rule.
    final class ScheduledLanguageRuleView {
        var codeText: String
        var label: String
        var title: String
        var revision: String
        var clinicianID: String
        var windowDaysText: String
        var diagnosisCode: String
        var procedureCodeText: String
        var encounterID: String
        var approvedText: String
        var statusLabel: String

        init(codeText: String, label: String, title: String, revision: String, clinicianID: String, windowDaysText: String, diagnosisCode: String, procedureCodeText: String, encounterID: String, approvedText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.title = title
            self.revision = revision
            self.clinicianID = clinicianID
            self.windowDaysText = windowDaysText
            self.diagnosisCode = diagnosisCode
            self.procedureCodeText = procedureCodeText
            self.encounterID = encounterID
            self.approvedText = approvedText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledLanguageRuleView(_ item: ScheduledLanguageRule) -> ScheduledLanguageRuleView {
        return ScheduledLanguageRuleView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            title: item.title,
            revision: String(item.revision),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 64),
            windowDaysText: String(item.windowDays),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            procedureCodeText: item.procedureCode,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 64),
            approvedText: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledLanguageRuleViews(_ items: [ScheduledLanguageRule]) -> [ScheduledLanguageRuleView] {
        var views: [ScheduledLanguageRuleView] = []
        for item in items {
            views.append(toScheduledLanguageRuleView(item))
        }
        return views
    }

    static func sumScheduledLanguageRuleView(_ view: ScheduledLanguageRuleView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedRevision) + Double(parsedWindowDays)
    }
}
