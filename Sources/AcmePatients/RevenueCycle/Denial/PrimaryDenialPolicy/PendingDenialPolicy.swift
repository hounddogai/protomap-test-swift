import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending denial policy is in its life cycle.
    enum PendingDenialPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One pending denial policy, with what the planners need to act on it.
    final class PendingDenialPolicy {
        var code: String
        var label: String
        var graceDays: Int
        var copay: Double
        var currency: String
        var status: PendingDenialPolicyStatus

        init(code: String, label: String, graceDays: Int, copay: Double, currency: String, status: PendingDenialPolicyStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.copay = copay
            self.currency = currency
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

        func canMoveTo(_ next: PendingDenialPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PendingDenialPolicyStatus.rejected || next == PendingDenialPolicyStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PendingDenialPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending denial policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedLoad() -> Double {
            return ((copay - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> PendingDenialPolicy {
            return PendingDenialPolicy(
                code: code,
                label: label,
                graceDays: graceDays,
                copay: copay,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending denial policy in status proposed.
    static func newPendingDenialPolicy(_ code: String, label: String) -> PendingDenialPolicy {
        return PendingDenialPolicy(
            code: code,
            label: label,
            graceDays: 0,
            copay: 0.0,
            currency: "",
            status: PendingDenialPolicyStatus.proposed
        )
    }
}
