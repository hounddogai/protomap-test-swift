import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual follow up rule is in its life cycle.
    enum ManualFollowUpRuleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One manual follow up rule, with what the planners need to act on it.
    final class ManualFollowUpRule {
        var code: String
        var name: String
        var archived: Bool
        var allergy: String
        var dosageMg: Double
        var approved: Bool
        var contactEmail: String
        var attempts: Int
        var clinicianID: String
        var status: ManualFollowUpRuleStatus

        init(code: String, name: String, archived: Bool, allergy: String, dosageMg: Double, approved: Bool, contactEmail: String, attempts: Int, clinicianID: String, status: ManualFollowUpRuleStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.allergy = allergy
            self.dosageMg = dosageMg
            self.approved = approved
            self.contactEmail = contactEmail
            self.attempts = attempts
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualFollowUpRuleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ManualFollowUpRuleStatus.suspended
            case .active:
                return next == ManualFollowUpRuleStatus.suspended
            case .suspended:
                return next == ManualFollowUpRuleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualFollowUpRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual follow up rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual follow up rule") \(code)"
        }

        func projectedValue() -> Double {
            return ((dosageMg + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> ManualFollowUpRule {
            return ManualFollowUpRule(
                code: code,
                name: name,
                archived: archived,
                allergy: allergy,
                dosageMg: dosageMg,
                approved: approved,
                contactEmail: contactEmail,
                attempts: attempts,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual follow up rule in status draft.
    static func newManualFollowUpRule(_ code: String, name: String) -> ManualFollowUpRule {
        return ManualFollowUpRule(
            code: code,
            name: name,
            archived: false,
            allergy: "",
            dosageMg: 0.0,
            approved: false,
            contactEmail: "",
            attempts: 0,
            clinicianID: "",
            status: ManualFollowUpRuleStatus.draft
        )
    }
}
