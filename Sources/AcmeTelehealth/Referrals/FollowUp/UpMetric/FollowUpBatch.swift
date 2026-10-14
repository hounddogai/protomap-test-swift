import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up batch is in its life cycle.
    enum FollowUpBatchStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A follow up batch. Its code is unique within a tenant.
    final class FollowUpBatch {
        var code: String
        var name: String
        var notes: String
        var archived: Bool
        var limit: Int
        var attempts: Int
        var status: FollowUpBatchStatus

        init(code: String, name: String, notes: String, archived: Bool, limit: Int, attempts: Int, status: FollowUpBatchStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.archived = archived
            self.limit = limit
            self.attempts = attempts
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

        func canMoveTo(_ next: FollowUpBatchStatus) -> Bool {
            switch status {
            case .planned:
                return next == FollowUpBatchStatus.inProgress
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FollowUpBatchStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("follow up batch") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(limit) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpBatch {
            return FollowUpBatch(
                code: code,
                name: name,
                notes: notes,
                archived: archived,
                limit: limit,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a follow up batch in status planned.
    static func newFollowUpBatch(_ code: String, name: String) -> FollowUpBatch {
        return FollowUpBatch(
            code: code,
            name: name,
            notes: "",
            archived: false,
            limit: 0,
            attempts: 0,
            status: FollowUpBatchStatus.planned
        )
    }
}
