import AcmePlatform
import Foundation

extension Staffing {
    /// Where a legacy acuity plan policy is in its life cycle.
    enum LegacyAcuityPlanPolicyStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A legacy acuity plan policy as the acuity plan team keeps it.
    final class LegacyAcuityPlanPolicy {
        var code: String
        var label: String
        var maximum: Double
        var quantity: Int
        var approved: Bool
        var locale: String
        var minimum: Double
        var discount: Double
        var status: LegacyAcuityPlanPolicyStatus

        init(code: String, label: String, maximum: Double, quantity: Int, approved: Bool, locale: String, minimum: Double, discount: Double, status: LegacyAcuityPlanPolicyStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.quantity = quantity
            self.approved = approved
            self.locale = locale
            self.minimum = minimum
            self.discount = discount
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

        func canMoveTo(_ next: LegacyAcuityPlanPolicyStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == LegacyAcuityPlanPolicyStatus.retired
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

        func moveTo(_ next: LegacyAcuityPlanPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy acuity plan policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netLoad() -> Double {
            return ((Double(quantity) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> LegacyAcuityPlanPolicy {
            return LegacyAcuityPlanPolicy(
                code: code,
                label: label,
                maximum: maximum,
                quantity: quantity,
                approved: approved,
                locale: locale,
                minimum: minimum,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a legacy acuity plan policy in status created.
    static func newLegacyAcuityPlanPolicy(_ code: String, label: String) -> LegacyAcuityPlanPolicy {
        return LegacyAcuityPlanPolicy(
            code: code,
            label: label,
            maximum: 0.0,
            quantity: 0,
            approved: false,
            locale: "",
            minimum: 0.0,
            discount: 0.0,
            status: LegacyAcuityPlanPolicyStatus.created
        )
    }
}
