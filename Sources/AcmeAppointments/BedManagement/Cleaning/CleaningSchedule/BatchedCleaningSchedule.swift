import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched cleaning schedule is in its life cycle.
    enum BatchedCleaningScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a batched cleaning schedule and its current status.
    final class BatchedCleaningSchedule {
        var code: String
        var label: String
        var startsAt: Int
        var pinned: Bool
        var retries: Int
        var status: BatchedCleaningScheduleStatus

        init(code: String, label: String, startsAt: Int, pinned: Bool, retries: Int, status: BatchedCleaningScheduleStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.pinned = pinned
            self.retries = retries
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

        func canMoveTo(_ next: BatchedCleaningScheduleStatus) -> Bool {
            switch status {
            case .planned:
                return next == BatchedCleaningScheduleStatus.completed
            case .scheduled:
                return next == BatchedCleaningScheduleStatus.inProgress || next == BatchedCleaningScheduleStatus.completed
            case .inProgress:
                return next == BatchedCleaningScheduleStatus.completed || next == BatchedCleaningScheduleStatus.cancelled
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

        func moveTo(_ next: BatchedCleaningScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched cleaning schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("batched cleaning schedule") \(code)"
        }

        func effectiveExposure() -> Double {
            return (Double(startsAt) * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> BatchedCleaningSchedule {
            return BatchedCleaningSchedule(
                code: code,
                label: label,
                startsAt: startsAt,
                pinned: pinned,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched cleaning schedule in status planned.
    static func newBatchedCleaningSchedule(_ code: String, label: String) -> BatchedCleaningSchedule {
        return BatchedCleaningSchedule(
            code: code,
            label: label,
            startsAt: 0,
            pinned: false,
            retries: 0,
            status: BatchedCleaningScheduleStatus.planned
        )
    }
}
