import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment baseline is in its life cycle.
    enum AssessmentBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A assessment baseline. Its code is unique within a tenant.
    final class AssessmentBaseline {
        var code: String
        var name: String
        var notes: String
        var clinicianID: String
        var contactEmail: String
        var amount: Double
        var status: AssessmentBaselineStatus

        init(code: String, name: String, notes: String, clinicianID: String, contactEmail: String, amount: Double, status: AssessmentBaselineStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.clinicianID = clinicianID
            self.contactEmail = contactEmail
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AssessmentBaselineStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AssessmentBaselineStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> AssessmentBaseline {
            return AssessmentBaseline(
                code: code,
                name: name,
                notes: notes,
                clinicianID: clinicianID,
                contactEmail: contactEmail,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a assessment baseline in status created.
    static func newAssessmentBaseline(_ code: String, name: String) -> AssessmentBaseline {
        return AssessmentBaseline(
            code: code,
            name: name,
            notes: "",
            clinicianID: "",
            contactEmail: "",
            amount: 0.0,
            status: AssessmentBaselineStatus.created
        )
    }
}
