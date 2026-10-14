import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled language rule is in its life cycle.
    enum ScheduledLanguageRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One scheduled language rule, with what the planners need to act on it.
    final class ScheduledLanguageRule {
        var code: String
        var label: String
        var title: String
        var revision: Int
        var clinicianID: String
        var windowDays: Int
        var diagnosisCode: String
        var procedureCode: String
        var encounterID: String
        var approved: Bool
        var status: ScheduledLanguageRuleStatus

        init(code: String, label: String, title: String, revision: Int, clinicianID: String, windowDays: Int, diagnosisCode: String, procedureCode: String, encounterID: String, approved: Bool, status: ScheduledLanguageRuleStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.revision = revision
            self.clinicianID = clinicianID
            self.windowDays = windowDays
            self.diagnosisCode = diagnosisCode
            self.procedureCode = procedureCode
            self.encounterID = encounterID
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledLanguageRuleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ScheduledLanguageRuleStatus.resolved
            case .inReview:
                return next == ScheduledLanguageRuleStatus.resolved || next == ScheduledLanguageRuleStatus.reopened
            case .resolved:
                return next == ScheduledLanguageRuleStatus.reopened || next == ScheduledLanguageRuleStatus.archived
            case .reopened:
                return next == ScheduledLanguageRuleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledLanguageRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled language rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("scheduled language rule") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(windowDays) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledLanguageRule {
            return ScheduledLanguageRule(
                code: code,
                label: label,
                title: title,
                revision: revision,
                clinicianID: clinicianID,
                windowDays: windowDays,
                diagnosisCode: diagnosisCode,
                procedureCode: procedureCode,
                encounterID: encounterID,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled language rule in status open.
    static func newScheduledLanguageRule(_ code: String, label: String) -> ScheduledLanguageRule {
        return ScheduledLanguageRule(
            code: code,
            label: label,
            title: "",
            revision: 0,
            clinicianID: "",
            windowDays: 0,
            diagnosisCode: "",
            procedureCode: "",
            encounterID: "",
            approved: false,
            status: ScheduledLanguageRuleStatus.`open`
        )
    }
}
