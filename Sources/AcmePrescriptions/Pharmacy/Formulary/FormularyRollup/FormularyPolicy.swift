import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary policy is in its life cycle.
    enum FormularyPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a formulary policy and its current status.
    final class FormularyPolicy {
        var code: String
        var label: String
        var budget: Double
        var retries: Int
        var payer: String
        var updatedAt: Int
        var status: FormularyPolicyStatus

        init(code: String, label: String, budget: Double, retries: Int, payer: String, updatedAt: Int, status: FormularyPolicyStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.retries = retries
            self.payer = payer
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: FormularyPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FormularyPolicyStatus.approved
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == FormularyPolicyStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netLoad() -> Double {
            return (Double(retries) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> FormularyPolicy {
            return FormularyPolicy(
                code: code,
                label: label,
                budget: budget,
                retries: retries,
                payer: payer,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a formulary policy in status proposed.
    static func newFormularyPolicy(_ code: String, label: String) -> FormularyPolicy {
        return FormularyPolicy(
            code: code,
            label: label,
            budget: 0.0,
            retries: 0,
            payer: "",
            updatedAt: 0,
            status: FormularyPolicyStatus.proposed
        )
    }
}
