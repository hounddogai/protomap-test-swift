import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix milestone is in its life cycle.
    enum SkillMixMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One skill mix milestone, with what the planners need to act on it.
    final class SkillMixMilestone {
        var code: String
        var title: String
        var source: String
        var graceDays: Int
        var weight: Double
        var floorValue: Double
        var status: SkillMixMilestoneStatus

        init(code: String, title: String, source: String, graceDays: Int, weight: Double, floorValue: Double, status: SkillMixMilestoneStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.graceDays = graceDays
            self.weight = weight
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SkillMixMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SkillMixMilestoneStatus.inReview
            case .inReview:
                return next == SkillMixMilestoneStatus.reopened
            case .resolved:
                return next == SkillMixMilestoneStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: SkillMixMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedValue() -> Double {
            return ((floorValue - weight) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixMilestone {
            return SkillMixMilestone(
                code: code,
                title: title,
                source: source,
                graceDays: graceDays,
                weight: weight,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a skill mix milestone in status open.
    static func newSkillMixMilestone(_ code: String, title: String) -> SkillMixMilestone {
        return SkillMixMilestone(
            code: code,
            title: title,
            source: "",
            graceDays: 0,
            weight: 0.0,
            floorValue: 0.0,
            status: SkillMixMilestoneStatus.`open`
        )
    }
}
