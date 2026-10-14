import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled study policy is in its life cycle.
    enum ScheduledStudyPolicyStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A scheduled study policy. Its code is unique within a tenant.
    final class ScheduledStudyPolicy {
        var code: String
        var label: String
        var ownerID: String
        var diagnosisCode: String
        var revision: Int
        var discount: Double
        var cost: Double
        var graceDays: Int
        var status: ScheduledStudyPolicyStatus

        init(code: String, label: String, ownerID: String, diagnosisCode: String, revision: Int, discount: Double, cost: Double, graceDays: Int, status: ScheduledStudyPolicyStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.diagnosisCode = diagnosisCode
            self.revision = revision
            self.discount = discount
            self.cost = cost
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledStudyPolicyStatus) -> Bool {
            switch status {
            case .planned:
                return next == ScheduledStudyPolicyStatus.cancelled
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ScheduledStudyPolicyStatus.completed || next == ScheduledStudyPolicyStatus.cancelled
            case .completed:
                return next == ScheduledStudyPolicyStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledStudyPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled study policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("scheduled study policy") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((cost + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledStudyPolicy {
            return ScheduledStudyPolicy(
                code: code,
                label: label,
                ownerID: ownerID,
                diagnosisCode: diagnosisCode,
                revision: revision,
                discount: discount,
                cost: cost,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled study policy in status planned.
    static func newScheduledStudyPolicy(_ code: String, label: String) -> ScheduledStudyPolicy {
        return ScheduledStudyPolicy(
            code: code,
            label: label,
            ownerID: "",
            diagnosisCode: "",
            revision: 0,
            discount: 0.0,
            cost: 0.0,
            graceDays: 0,
            status: ScheduledStudyPolicyStatus.planned
        )
    }
}
