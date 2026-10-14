import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched authorization snapshot is in its life cycle.
    enum BatchedAuthorizationSnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A batched authorization snapshot. Its code is unique within a tenant.
    final class BatchedAuthorizationSnapshot {
        var code: String
        var title: String
        var contactEmail: String
        var reviewer: String
        var bed: String
        var score: Double
        var status: BatchedAuthorizationSnapshotStatus

        init(code: String, title: String, contactEmail: String, reviewer: String, bed: String, score: Double, status: BatchedAuthorizationSnapshotStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.reviewer = reviewer
            self.bed = bed
            self.score = score
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

        func canMoveTo(_ next: BatchedAuthorizationSnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == BatchedAuthorizationSnapshotStatus.reopened
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

        func moveTo(_ next: BatchedAuthorizationSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched authorization snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> BatchedAuthorizationSnapshot {
            return BatchedAuthorizationSnapshot(
                code: code,
                title: title,
                contactEmail: contactEmail,
                reviewer: reviewer,
                bed: bed,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched authorization snapshot in status open.
    static func newBatchedAuthorizationSnapshot(_ code: String, title: String) -> BatchedAuthorizationSnapshot {
        return BatchedAuthorizationSnapshot(
            code: code,
            title: title,
            contactEmail: "",
            reviewer: "",
            bed: "",
            score: 0.0,
            status: BatchedAuthorizationSnapshotStatus.`open`
        )
    }
}
