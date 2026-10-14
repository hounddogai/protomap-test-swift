import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study quota is in its life cycle.
    enum StudyQuotaStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A study quota as the study team keeps it.
    final class StudyQuota {
        var code: String
        var name: String
        var procedureCode: String
        var priority: Int
        var externalRef: String
        var attempts: Int
        var graceDays: Int
        var sequence: Int
        var status: StudyQuotaStatus

        init(code: String, name: String, procedureCode: String, priority: Int, externalRef: String, attempts: Int, graceDays: Int, sequence: Int, status: StudyQuotaStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.priority = priority
            self.externalRef = externalRef
            self.attempts = attempts
            self.graceDays = graceDays
            self.sequence = sequence
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

        func canMoveTo(_ next: StudyQuotaStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == StudyQuotaStatus.reopened || next == StudyQuotaStatus.archived
            case .resolved:
                return next == StudyQuotaStatus.reopened
            case .reopened:
                return next == StudyQuotaStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveVolume() -> Double {
            return ((Double(sequence) - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> StudyQuota {
            return StudyQuota(
                code: code,
                name: name,
                procedureCode: procedureCode,
                priority: priority,
                externalRef: externalRef,
                attempts: attempts,
                graceDays: graceDays,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a study quota in status open.
    static func newStudyQuota(_ code: String, name: String) -> StudyQuota {
        return StudyQuota(
            code: code,
            name: name,
            procedureCode: "",
            priority: 0,
            externalRef: "",
            attempts: 0,
            graceDays: 0,
            sequence: 0,
            status: StudyQuotaStatus.`open`
        )
    }
}
