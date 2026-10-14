import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff rule is in its life cycle.
    enum HandoffRuleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A handoff rule as the handoff team keeps it.
    final class HandoffRule {
        var code: String
        var label: String
        var bed: String
        var maximum: Double
        var contactEmail: String
        var cost: Double
        var acuity: Int
        var visible: Bool
        var expiresAt: Int
        var status: HandoffRuleStatus

        init(code: String, label: String, bed: String, maximum: Double, contactEmail: String, cost: Double, acuity: Int, visible: Bool, expiresAt: Int, status: HandoffRuleStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.maximum = maximum
            self.contactEmail = contactEmail
            self.cost = cost
            self.acuity = acuity
            self.visible = visible
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: HandoffRuleStatus) -> Bool {
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
                switch next {
                case .cancelled:
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
                return next == HandoffRuleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("handoff rule") \(code)"
        }

        func projectedLoad() -> Double {
            return (Double(expiresAt) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> HandoffRule {
            return HandoffRule(
                code: code,
                label: label,
                bed: bed,
                maximum: maximum,
                contactEmail: contactEmail,
                cost: cost,
                acuity: acuity,
                visible: visible,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a handoff rule in status planned.
    static func newHandoffRule(_ code: String, label: String) -> HandoffRule {
        return HandoffRule(
            code: code,
            label: label,
            bed: "",
            maximum: 0.0,
            contactEmail: "",
            cost: 0.0,
            acuity: 0,
            visible: false,
            expiresAt: 0,
            status: HandoffRuleStatus.planned
        )
    }
}
