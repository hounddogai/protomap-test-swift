import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal assignment is in its life cycle.
    enum GoalAssignmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One goal assignment, with what the planners need to act on it.
    final class GoalAssignment {
        var code: String
        var title: String
        var margin: Double
        var updatedAt: Int
        var checksum: String
        var status: GoalAssignmentStatus

        init(code: String, title: String, margin: Double, updatedAt: Int, checksum: String, status: GoalAssignmentStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.updatedAt = updatedAt
            self.checksum = checksum
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

        func canMoveTo(_ next: GoalAssignmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == GoalAssignmentStatus.pending || next == GoalAssignmentStatus.closed
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GoalAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveExposure() -> Double {
            return (margin * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> GoalAssignment {
            return GoalAssignment(
                code: code,
                title: title,
                margin: margin,
                updatedAt: updatedAt,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a goal assignment in status draft.
    static func newGoalAssignment(_ code: String, title: String) -> GoalAssignment {
        return GoalAssignment(
            code: code,
            title: title,
            margin: 0.0,
            updatedAt: 0,
            checksum: "",
            status: GoalAssignmentStatus.draft
        )
    }
}
