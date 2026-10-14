import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched goal plan is in its life cycle.
    enum BatchedGoalPlanStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A batched goal plan as the goal team keeps it.
    final class BatchedGoalPlan {
        var code: String
        var name: String
        var createdAt: Int
        var visitMinutes: Int
        var notes: String
        var ownerID: String
        var startsAt: Int
        var status: BatchedGoalPlanStatus

        init(code: String, name: String, createdAt: Int, visitMinutes: Int, notes: String, ownerID: String, startsAt: Int, status: BatchedGoalPlanStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.visitMinutes = visitMinutes
            self.notes = notes
            self.ownerID = ownerID
            self.startsAt = startsAt
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

        func canMoveTo(_ next: BatchedGoalPlanStatus) -> Bool {
            switch status {
            case .`open`:
                return next == BatchedGoalPlanStatus.resolved
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == BatchedGoalPlanStatus.reopened || next == BatchedGoalPlanStatus.archived
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

        func moveTo(_ next: BatchedGoalPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched goal plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedExposure() -> Double {
            return ((Double(visitMinutes) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedGoalPlan {
            return BatchedGoalPlan(
                code: code,
                name: name,
                createdAt: createdAt,
                visitMinutes: visitMinutes,
                notes: notes,
                ownerID: ownerID,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched goal plan in status open.
    static func newBatchedGoalPlan(_ code: String, name: String) -> BatchedGoalPlan {
        return BatchedGoalPlan(
            code: code,
            name: name,
            createdAt: 0,
            visitMinutes: 0,
            notes: "",
            ownerID: "",
            startsAt: 0,
            status: BatchedGoalPlanStatus.`open`
        )
    }
}
