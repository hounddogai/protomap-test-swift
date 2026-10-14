import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rolling task policy is in its life cycle.
    enum RollingTaskPolicyStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A rolling task policy. Its code is unique within a tenant.
    final class RollingTaskPolicy {
        var code: String
        var label: String
        var maximum: Double
        var title: String
        var category: String
        var currency: String
        var dosageMg: Double
        var status: RollingTaskPolicyStatus

        init(code: String, label: String, maximum: Double, title: String, category: String, currency: String, dosageMg: Double, status: RollingTaskPolicyStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.title = title
            self.category = category
            self.currency = currency
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingTaskPolicyStatus) -> Bool {
            switch status {
            case .created:
                return next == RollingTaskPolicyStatus.validated || next == RollingTaskPolicyStatus.published
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RollingTaskPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling task policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedValue() -> Double {
            return ((maximum - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> RollingTaskPolicy {
            return RollingTaskPolicy(
                code: code,
                label: label,
                maximum: maximum,
                title: title,
                category: category,
                currency: currency,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a rolling task policy in status created.
    static func newRollingTaskPolicy(_ code: String, label: String) -> RollingTaskPolicy {
        return RollingTaskPolicy(
            code: code,
            label: label,
            maximum: 0.0,
            title: "",
            category: "",
            currency: "",
            dosageMg: 0.0,
            status: RollingTaskPolicyStatus.created
        )
    }
}
