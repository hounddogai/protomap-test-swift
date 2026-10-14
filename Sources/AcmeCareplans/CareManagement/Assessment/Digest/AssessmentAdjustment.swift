import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment adjustment is in its life cycle.
    enum AssessmentAdjustmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A assessment adjustment. Its code is unique within a tenant.
    final class AssessmentAdjustment {
        var code: String
        var label: String
        var encounterID: String
        var capacity: Int
        var segment: String
        var rate: Double
        var copay: Double
        var retries: Int
        var attempts: Int
        var status: AssessmentAdjustmentStatus

        init(code: String, label: String, encounterID: String, capacity: Int, segment: String, rate: Double, copay: Double, retries: Int, attempts: Int, status: AssessmentAdjustmentStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.capacity = capacity
            self.segment = segment
            self.rate = rate
            self.copay = copay
            self.retries = retries
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AssessmentAdjustmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AssessmentAdjustmentStatus.approved
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AssessmentAdjustmentStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedLoad() -> Double {
            return (Double(attempts) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentAdjustment {
            return AssessmentAdjustment(
                code: code,
                label: label,
                encounterID: encounterID,
                capacity: capacity,
                segment: segment,
                rate: rate,
                copay: copay,
                retries: retries,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a assessment adjustment in status proposed.
    static func newAssessmentAdjustment(_ code: String, label: String) -> AssessmentAdjustment {
        return AssessmentAdjustment(
            code: code,
            label: label,
            encounterID: "",
            capacity: 0,
            segment: "",
            rate: 0.0,
            copay: 0.0,
            retries: 0,
            attempts: 0,
            status: AssessmentAdjustmentStatus.proposed
        )
    }
}
