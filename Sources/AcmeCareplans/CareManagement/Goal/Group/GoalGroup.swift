import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal group is in its life cycle.
    enum GoalGroupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A goal group. Its code is unique within a tenant.
    final class GoalGroup {
        var code: String
        var label: String
        var ownerID: String
        var capacity: Int
        var floorValue: Double
        var status: GoalGroupStatus

        init(code: String, label: String, ownerID: String, capacity: Int, floorValue: Double, status: GoalGroupStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.capacity = capacity
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

        func canMoveTo(_ next: GoalGroupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == GoalGroupStatus.resolved || next == GoalGroupStatus.archived
            case .resolved:
                return next == GoalGroupStatus.reopened || next == GoalGroupStatus.archived
            case .reopened:
                return next == GoalGroupStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("goal group") \(code)"
        }

        func adjustedTotal() -> Double {
            return (Double(capacity) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> GoalGroup {
            return GoalGroup(
                code: code,
                label: label,
                ownerID: ownerID,
                capacity: capacity,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a goal group in status open.
    static func newGoalGroup(_ code: String, label: String) -> GoalGroup {
        return GoalGroup(
            code: code,
            label: label,
            ownerID: "",
            capacity: 0,
            floorValue: 0.0,
            status: GoalGroupStatus.`open`
        )
    }
}
