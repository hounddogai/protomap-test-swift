import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge rule is in its life cycle.
    enum ChargeRuleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A charge rule. Its code is unique within a tenant.
    final class ChargeRule {
        var code: String
        var title: String
        var encounterID: String
        var category: String
        var visitMinutes: Int
        var unit: String
        var timezone: String
        var status: ChargeRuleStatus

        init(code: String, title: String, encounterID: String, category: String, visitMinutes: Int, unit: String, timezone: String, status: ChargeRuleStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.category = category
            self.visitMinutes = visitMinutes
            self.unit = unit
            self.timezone = timezone
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

        func canMoveTo(_ next: ChargeRuleStatus) -> Bool {
            switch status {
            case .planned:
                return next == ChargeRuleStatus.scheduled || next == ChargeRuleStatus.completed
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ChargeRuleStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ChargeRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> ChargeRule {
            return ChargeRule(
                code: code,
                title: title,
                encounterID: encounterID,
                category: category,
                visitMinutes: visitMinutes,
                unit: unit,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a charge rule in status planned.
    static func newChargeRule(_ code: String, title: String) -> ChargeRule {
        return ChargeRule(
            code: code,
            title: title,
            encounterID: "",
            category: "",
            visitMinutes: 0,
            unit: "",
            timezone: "",
            status: ChargeRuleStatus.planned
        )
    }
}
