import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict modality policy is in its life cycle.
    enum StrictModalityPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A strict modality policy as the modality team keeps it.
    final class StrictModalityPolicy {
        var code: String
        var label: String
        var ceiling: Double
        var maximum: Double
        var cost: Double
        var status: StrictModalityPolicyStatus

        init(code: String, label: String, ceiling: Double, maximum: Double, cost: Double, status: StrictModalityPolicyStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.maximum = maximum
            self.cost = cost
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

        func canMoveTo(_ next: StrictModalityPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StrictModalityPolicyStatus.approved || next == StrictModalityPolicyStatus.withdrawn
            case .approved:
                return next == StrictModalityPolicyStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: StrictModalityPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict modality policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveLoad() -> Double {
            return (maximum * ceiling * 100).rounded() / 100
        }

        func copyValue() -> StrictModalityPolicy {
            return StrictModalityPolicy(
                code: code,
                label: label,
                ceiling: ceiling,
                maximum: maximum,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict modality policy in status proposed.
    static func newStrictModalityPolicy(_ code: String, label: String) -> StrictModalityPolicy {
        return StrictModalityPolicy(
            code: code,
            label: label,
            ceiling: 0.0,
            maximum: 0.0,
            cost: 0.0,
            status: StrictModalityPolicyStatus.proposed
        )
    }
}
