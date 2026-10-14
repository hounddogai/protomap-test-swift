import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix cycle is in its life cycle.
    enum SkillMixCycleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A skill mix cycle. Its code is unique within a tenant.
    final class SkillMixCycle {
        var code: String
        var label: String
        var priority: Int
        var budget: Double
        var currency: String
        var discount: Double
        var status: SkillMixCycleStatus

        init(code: String, label: String, priority: Int, budget: Double, currency: String, discount: Double, status: SkillMixCycleStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.budget = budget
            self.currency = currency
            self.discount = discount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SkillMixCycleStatus) -> Bool {
            switch status {
            case .draft:
                return next == SkillMixCycleStatus.active || next == SkillMixCycleStatus.suspended
            case .pending:
                return next == SkillMixCycleStatus.active
            case .active:
                return next == SkillMixCycleStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: SkillMixCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("skill mix cycle") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((budget - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixCycle {
            return SkillMixCycle(
                code: code,
                label: label,
                priority: priority,
                budget: budget,
                currency: currency,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a skill mix cycle in status draft.
    static func newSkillMixCycle(_ code: String, label: String) -> SkillMixCycle {
        return SkillMixCycle(
            code: code,
            label: label,
            priority: 0,
            budget: 0.0,
            currency: "",
            discount: 0.0,
            status: SkillMixCycleStatus.draft
        )
    }
}
