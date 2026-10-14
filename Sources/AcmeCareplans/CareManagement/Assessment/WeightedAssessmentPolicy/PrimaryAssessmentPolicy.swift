import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a primary assessment policy is in its life cycle.
    enum PrimaryAssessmentPolicyStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A primary assessment policy. Its code is unique within a tenant.
    final class PrimaryAssessmentPolicy {
        var code: String
        var label: String
        var refills: Int
        var acuity: Int
        var notes: String
        var status: PrimaryAssessmentPolicyStatus

        init(code: String, label: String, refills: Int, acuity: Int, notes: String, status: PrimaryAssessmentPolicyStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.acuity = acuity
            self.notes = notes
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

        func canMoveTo(_ next: PrimaryAssessmentPolicyStatus) -> Bool {
            switch status {
            case .planned:
                return next == PrimaryAssessmentPolicyStatus.inProgress
            case .scheduled:
                return next == PrimaryAssessmentPolicyStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryAssessmentPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary assessment policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netValue() -> Double {
            return ((Double(refills) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryAssessmentPolicy {
            return PrimaryAssessmentPolicy(
                code: code,
                label: label,
                refills: refills,
                acuity: acuity,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary assessment policy in status planned.
    static func newPrimaryAssessmentPolicy(_ code: String, label: String) -> PrimaryAssessmentPolicy {
        return PrimaryAssessmentPolicy(
            code: code,
            label: label,
            refills: 0,
            acuity: 0,
            notes: "",
            status: PrimaryAssessmentPolicyStatus.planned
        )
    }
}
