import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal proposal is in its life cycle.
    enum GoalProposalStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a goal proposal and its current status.
    final class GoalProposal {
        var code: String
        var title: String
        var approved: Bool
        var category: String
        var floorValue: Double
        var status: GoalProposalStatus

        init(code: String, title: String, approved: Bool, category: String, floorValue: Double, status: GoalProposalStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.category = category
            self.floorValue = floorValue
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

        func canMoveTo(_ next: GoalProposalStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == GoalProposalStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> GoalProposal {
            return GoalProposal(
                code: code,
                title: title,
                approved: approved,
                category: category,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a goal proposal in status planned.
    static func newGoalProposal(_ code: String, title: String) -> GoalProposal {
        return GoalProposal(
            code: code,
            title: title,
            approved: false,
            category: "",
            floorValue: 0.0,
            status: GoalProposalStatus.planned
        )
    }
}
