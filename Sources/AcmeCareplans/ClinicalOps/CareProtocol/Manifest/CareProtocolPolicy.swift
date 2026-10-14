import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol policy is in its life cycle.
    enum CareProtocolPolicyStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A care protocol policy as the care protocol team keeps it.
    final class CareProtocolPolicy {
        var code: String
        var label: String
        var windowDays: Int
        var maximum: Double
        var patientRef: String
        var externalRef: String
        var notes: String
        var sequence: Int
        var priority: Int
        var minimum: Double
        var status: CareProtocolPolicyStatus

        init(code: String, label: String, windowDays: Int, maximum: Double, patientRef: String, externalRef: String, notes: String, sequence: Int, priority: Int, minimum: Double, status: CareProtocolPolicyStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.maximum = maximum
            self.patientRef = patientRef
            self.externalRef = externalRef
            self.notes = notes
            self.sequence = sequence
            self.priority = priority
            self.minimum = minimum
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

        func canMoveTo(_ next: CareProtocolPolicyStatus) -> Bool {
            switch status {
            case .planned:
                return next == CareProtocolPolicyStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == CareProtocolPolicyStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netTotal() -> Double {
            return ((maximum - minimum) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolPolicy {
            return CareProtocolPolicy(
                code: code,
                label: label,
                windowDays: windowDays,
                maximum: maximum,
                patientRef: patientRef,
                externalRef: externalRef,
                notes: notes,
                sequence: sequence,
                priority: priority,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a care protocol policy in status planned.
    static func newCareProtocolPolicy(_ code: String, label: String) -> CareProtocolPolicy {
        return CareProtocolPolicy(
            code: code,
            label: label,
            windowDays: 0,
            maximum: 0.0,
            patientRef: "",
            externalRef: "",
            notes: "",
            sequence: 0,
            priority: 0,
            minimum: 0.0,
            status: CareProtocolPolicyStatus.planned
        )
    }
}
