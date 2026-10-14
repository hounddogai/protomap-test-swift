import AcmePlatform
import Foundation

extension Staffing {
    /// Where a tiered skill mix milestone is in its life cycle.
    enum TieredSkillMixMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One tiered skill mix milestone, with what the planners need to act on it.
    final class TieredSkillMixMilestone {
        var code: String
        var title: String
        var facility: String
        var budget: Double
        var active: Bool
        var status: TieredSkillMixMilestoneStatus

        init(code: String, title: String, facility: String, budget: Double, active: Bool, status: TieredSkillMixMilestoneStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.budget = budget
            self.active = active
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

        func canMoveTo(_ next: TieredSkillMixMilestoneStatus) -> Bool {
            switch status {
            case .created:
                return next == TieredSkillMixMilestoneStatus.validated
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == TieredSkillMixMilestoneStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredSkillMixMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered skill mix milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered skill mix milestone") \(code)"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> TieredSkillMixMilestone {
            return TieredSkillMixMilestone(
                code: code,
                title: title,
                facility: facility,
                budget: budget,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a tiered skill mix milestone in status created.
    static func newTieredSkillMixMilestone(_ code: String, title: String) -> TieredSkillMixMilestone {
        return TieredSkillMixMilestone(
            code: code,
            title: title,
            facility: "",
            budget: 0.0,
            active: false,
            status: TieredSkillMixMilestoneStatus.created
        )
    }
}
