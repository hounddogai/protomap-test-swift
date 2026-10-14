import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan policy is in its life cycle.
    enum DischargePlanPolicyStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A discharge plan policy. Its code is unique within a tenant.
    final class DischargePlanPolicy {
        var code: String
        var label: String
        var patientRef: String
        var amount: Double
        var description: String
        var status: DischargePlanPolicyStatus

        init(code: String, label: String, patientRef: String, amount: Double, description: String, status: DischargePlanPolicyStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.amount = amount
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DischargePlanPolicyStatus) -> Bool {
            switch status {
            case .requested:
                return next == DischargePlanPolicyStatus.revoked
            case .granted:
                return next == DischargePlanPolicyStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: DischargePlanPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> DischargePlanPolicy {
            return DischargePlanPolicy(
                code: code,
                label: label,
                patientRef: patientRef,
                amount: amount,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a discharge plan policy in status requested.
    static func newDischargePlanPolicy(_ code: String, label: String) -> DischargePlanPolicy {
        return DischargePlanPolicy(
            code: code,
            label: label,
            patientRef: "",
            amount: 0.0,
            description: "",
            status: DischargePlanPolicyStatus.requested
        )
    }
}
