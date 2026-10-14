import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global worklist rule is in its life cycle.
    enum GlobalWorklistRuleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A global worklist rule. Its code is unique within a tenant.
    final class GlobalWorklistRule {
        var code: String
        var label: String
        var margin: Double
        var payer: String
        var version: Int
        var allergy: String
        var active: Bool
        var maximum: Double
        var status: GlobalWorklistRuleStatus

        init(code: String, label: String, margin: Double, payer: String, version: Int, allergy: String, active: Bool, maximum: Double, status: GlobalWorklistRuleStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.payer = payer
            self.version = version
            self.allergy = allergy
            self.active = active
            self.maximum = maximum
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

        func canMoveTo(_ next: GlobalWorklistRuleStatus) -> Bool {
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
                return next == GlobalWorklistRuleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalWorklistRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global worklist rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("global worklist rule") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((maximum + margin) * 100).rounded() / 100
        }

        func copyValue() -> GlobalWorklistRule {
            return GlobalWorklistRule(
                code: code,
                label: label,
                margin: margin,
                payer: payer,
                version: version,
                allergy: allergy,
                active: active,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global worklist rule in status proposed.
    static func newGlobalWorklistRule(_ code: String, label: String) -> GlobalWorklistRule {
        return GlobalWorklistRule(
            code: code,
            label: label,
            margin: 0.0,
            payer: "",
            version: 0,
            allergy: "",
            active: false,
            maximum: 0.0,
            status: GlobalWorklistRuleStatus.proposed
        )
    }
}
