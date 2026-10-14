import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient study rule is in its life cycle.
    enum LenientStudyRuleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One lenient study rule, with what the planners need to act on it.
    final class LenientStudyRule {
        var code: String
        var label: String
        var discount: Double
        var priority: Int
        var quantity: Int
        var status: LenientStudyRuleStatus

        init(code: String, label: String, discount: Double, priority: Int, quantity: Int, status: LenientStudyRuleStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.priority = priority
            self.quantity = quantity
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

        func canMoveTo(_ next: LenientStudyRuleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == LenientStudyRuleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientStudyRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient study rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("lenient study rule") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(priority) + discount) * 100).rounded() / 100
        }

        func copyValue() -> LenientStudyRule {
            return LenientStudyRule(
                code: code,
                label: label,
                discount: discount,
                priority: priority,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient study rule in status proposed.
    static func newLenientStudyRule(_ code: String, label: String) -> LenientStudyRule {
        return LenientStudyRule(
            code: code,
            label: label,
            discount: 0.0,
            priority: 0,
            quantity: 0,
            status: LenientStudyRuleStatus.proposed
        )
    }
}
