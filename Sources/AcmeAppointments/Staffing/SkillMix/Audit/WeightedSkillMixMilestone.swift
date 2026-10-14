import AcmePlatform
import Foundation

extension Staffing {
    /// Where a weighted skill mix milestone is in its life cycle.
    enum WeightedSkillMixMilestoneStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a weighted skill mix milestone and its current status.
    final class WeightedSkillMixMilestone {
        var code: String
        var name: String
        var visible: Bool
        var budget: Double
        var score: Double
        var status: WeightedSkillMixMilestoneStatus

        init(code: String, name: String, visible: Bool, budget: Double, score: Double, status: WeightedSkillMixMilestoneStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.budget = budget
            self.score = score
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

        func canMoveTo(_ next: WeightedSkillMixMilestoneStatus) -> Bool {
            switch status {
            case .planned:
                return next == WeightedSkillMixMilestoneStatus.scheduled || next == WeightedSkillMixMilestoneStatus.completed
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == WeightedSkillMixMilestoneStatus.completed || next == WeightedSkillMixMilestoneStatus.cancelled
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

        func moveTo(_ next: WeightedSkillMixMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted skill mix milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveValue() -> Double {
            return (score * budget * 100).rounded() / 100
        }

        func copyValue() -> WeightedSkillMixMilestone {
            return WeightedSkillMixMilestone(
                code: code,
                name: name,
                visible: visible,
                budget: budget,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted skill mix milestone in status planned.
    static func newWeightedSkillMixMilestone(_ code: String, name: String) -> WeightedSkillMixMilestone {
        return WeightedSkillMixMilestone(
            code: code,
            name: name,
            visible: false,
            budget: 0.0,
            score: 0.0,
            status: WeightedSkillMixMilestoneStatus.planned
        )
    }
}
