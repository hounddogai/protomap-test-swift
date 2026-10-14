import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched claim assignment is in its life cycle.
    enum BatchedClaimAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One batched claim assignment, with what the planners need to act on it.
    final class BatchedClaimAssignment {
        var code: String
        var title: String
        var windowDays: Int
        var ratio: Double
        var graceDays: Int
        var status: BatchedClaimAssignmentStatus

        init(code: String, title: String, windowDays: Int, ratio: Double, graceDays: Int, status: BatchedClaimAssignmentStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.ratio = ratio
            self.graceDays = graceDays
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

        func canMoveTo(_ next: BatchedClaimAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == BatchedClaimAssignmentStatus.inProgress
            case .scheduled:
                return next == BatchedClaimAssignmentStatus.inProgress || next == BatchedClaimAssignmentStatus.cancelled
            case .inProgress:
                return next == BatchedClaimAssignmentStatus.cancelled
            case .completed:
                return next == BatchedClaimAssignmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedClaimAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched claim assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedTotal() -> Double {
            return ((Double(windowDays) - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedClaimAssignment {
            return BatchedClaimAssignment(
                code: code,
                title: title,
                windowDays: windowDays,
                ratio: ratio,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched claim assignment in status planned.
    static func newBatchedClaimAssignment(_ code: String, title: String) -> BatchedClaimAssignment {
        return BatchedClaimAssignment(
            code: code,
            title: title,
            windowDays: 0,
            ratio: 0.0,
            graceDays: 0,
            status: BatchedClaimAssignmentStatus.planned
        )
    }
}
