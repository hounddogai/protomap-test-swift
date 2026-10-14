import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled slot record is in its life cycle.
    enum ScheduledSlotRecordStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A scheduled slot record as the slot team keeps it.
    final class ScheduledSlotRecord {
        var code: String
        var title: String
        var capacity: Int
        var reviewer: String
        var summary: String
        var pinned: Bool
        var attempts: Int
        var graceDays: Int
        var status: ScheduledSlotRecordStatus

        init(code: String, title: String, capacity: Int, reviewer: String, summary: String, pinned: Bool, attempts: Int, graceDays: Int, status: ScheduledSlotRecordStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.reviewer = reviewer
            self.summary = summary
            self.pinned = pinned
            self.attempts = attempts
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

        func canMoveTo(_ next: ScheduledSlotRecordStatus) -> Bool {
            switch status {
            case .planned:
                return next == ScheduledSlotRecordStatus.inProgress
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ScheduledSlotRecordStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledSlotRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled slot record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedLoad() -> Double {
            return ((Double(capacity) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledSlotRecord {
            return ScheduledSlotRecord(
                code: code,
                title: title,
                capacity: capacity,
                reviewer: reviewer,
                summary: summary,
                pinned: pinned,
                attempts: attempts,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled slot record in status planned.
    static func newScheduledSlotRecord(_ code: String, title: String) -> ScheduledSlotRecord {
        return ScheduledSlotRecord(
            code: code,
            title: title,
            capacity: 0,
            reviewer: "",
            summary: "",
            pinned: false,
            attempts: 0,
            graceDays: 0,
            status: ScheduledSlotRecordStatus.planned
        )
    }
}
