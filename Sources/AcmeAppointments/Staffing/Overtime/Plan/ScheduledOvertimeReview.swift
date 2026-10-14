import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled overtime review is in its life cycle.
    enum ScheduledOvertimeReviewStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A scheduled overtime review as the overtime team keeps it.
    final class ScheduledOvertimeReview {
        var code: String
        var title: String
        var updatedAt: Int
        var discount: Double
        var reviewer: String
        var durationMinutes: Int
        var ownerID: String
        var priority: Int
        var currency: String
        var status: ScheduledOvertimeReviewStatus

        init(code: String, title: String, updatedAt: Int, discount: Double, reviewer: String, durationMinutes: Int, ownerID: String, priority: Int, currency: String, status: ScheduledOvertimeReviewStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.discount = discount
            self.reviewer = reviewer
            self.durationMinutes = durationMinutes
            self.ownerID = ownerID
            self.priority = priority
            self.currency = currency
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

        func canMoveTo(_ next: ScheduledOvertimeReviewStatus) -> Bool {
            switch status {
            case .planned:
                return next == ScheduledOvertimeReviewStatus.inProgress || next == ScheduledOvertimeReviewStatus.completed
            case .scheduled:
                return next == ScheduledOvertimeReviewStatus.completed
            case .inProgress:
                return next == ScheduledOvertimeReviewStatus.completed || next == ScheduledOvertimeReviewStatus.cancelled
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

        func moveTo(_ next: ScheduledOvertimeReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled overtime review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netTotal() -> Double {
            return ((Double(updatedAt) + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledOvertimeReview {
            return ScheduledOvertimeReview(
                code: code,
                title: title,
                updatedAt: updatedAt,
                discount: discount,
                reviewer: reviewer,
                durationMinutes: durationMinutes,
                ownerID: ownerID,
                priority: priority,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled overtime review in status planned.
    static func newScheduledOvertimeReview(_ code: String, title: String) -> ScheduledOvertimeReview {
        return ScheduledOvertimeReview(
            code: code,
            title: title,
            updatedAt: 0,
            discount: 0.0,
            reviewer: "",
            durationMinutes: 0,
            ownerID: "",
            priority: 0,
            currency: "",
            status: ScheduledOvertimeReviewStatus.planned
        )
    }
}
