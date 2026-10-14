import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal review is in its life cycle.
    enum GoalReviewStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a goal review and its current status.
    final class GoalReview {
        var code: String
        var title: String
        var segment: String
        var revision: Int
        var archived: Bool
        var allergy: String
        var status: GoalReviewStatus

        init(code: String, title: String, segment: String, revision: Int, archived: Bool, allergy: String, status: GoalReviewStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.revision = revision
            self.archived = archived
            self.allergy = allergy
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

        func canMoveTo(_ next: GoalReviewStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == GoalReviewStatus.completed
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GoalReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> GoalReview {
            return GoalReview(
                code: code,
                title: title,
                segment: segment,
                revision: revision,
                archived: archived,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a goal review in status planned.
    static func newGoalReview(_ code: String, title: String) -> GoalReview {
        return GoalReview(
            code: code,
            title: title,
            segment: "",
            revision: 0,
            archived: false,
            allergy: "",
            status: GoalReviewStatus.planned
        )
    }
}
