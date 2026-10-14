import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a fallback recall policy is in its life cycle.
    enum FallbackRecallPolicyStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A fallback recall policy as the recall team keeps it.
    final class FallbackRecallPolicy {
        var code: String
        var label: String
        var specialty: String
        var priority: Int
        var checksum: String
        var maximum: Double
        var floorValue: Double
        var discount: Double
        var country: String
        var copay: Double
        var patientRef: String
        var status: FallbackRecallPolicyStatus

        init(code: String, label: String, specialty: String, priority: Int, checksum: String, maximum: Double, floorValue: Double, discount: Double, country: String, copay: Double, patientRef: String, status: FallbackRecallPolicyStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.priority = priority
            self.checksum = checksum
            self.maximum = maximum
            self.floorValue = floorValue
            self.discount = discount
            self.country = country
            self.copay = copay
            self.patientRef = patientRef
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

        func canMoveTo(_ next: FallbackRecallPolicyStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == FallbackRecallPolicyStatus.inProgress || next == FallbackRecallPolicyStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FallbackRecallPolicyStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackRecallPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback recall policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedValue() -> Double {
            return (discount * copay * 100).rounded() / 100
        }

        func copyValue() -> FallbackRecallPolicy {
            return FallbackRecallPolicy(
                code: code,
                label: label,
                specialty: specialty,
                priority: priority,
                checksum: checksum,
                maximum: maximum,
                floorValue: floorValue,
                discount: discount,
                country: country,
                copay: copay,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a fallback recall policy in status planned.
    static func newFallbackRecallPolicy(_ code: String, label: String) -> FallbackRecallPolicy {
        return FallbackRecallPolicy(
            code: code,
            label: label,
            specialty: "",
            priority: 0,
            checksum: "",
            maximum: 0.0,
            floorValue: 0.0,
            discount: 0.0,
            country: "",
            copay: 0.0,
            patientRef: "",
            status: FallbackRecallPolicyStatus.planned
        )
    }
}
