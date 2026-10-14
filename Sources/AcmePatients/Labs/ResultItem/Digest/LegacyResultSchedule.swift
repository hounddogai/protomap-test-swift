import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy result schedule is in its life cycle.
    enum LegacyResultScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A legacy result schedule as the result team keeps it.
    final class LegacyResultSchedule {
        var code: String
        var title: String
        var visitMinutes: Int
        var phone: String
        var attempts: Int
        var maximum: Double
        var status: LegacyResultScheduleStatus

        init(code: String, title: String, visitMinutes: Int, phone: String, attempts: Int, maximum: Double, status: LegacyResultScheduleStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.phone = phone
            self.attempts = attempts
            self.maximum = maximum
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

        func canMoveTo(_ next: LegacyResultScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == LegacyResultScheduleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyResultScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy result schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy result schedule") \(code)"
        }

        func effectiveTotal() -> Double {
            return (Double(visitMinutes) * maximum * 100).rounded() / 100
        }

        func copyValue() -> LegacyResultSchedule {
            return LegacyResultSchedule(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                phone: phone,
                attempts: attempts,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy result schedule in status open.
    static func newLegacyResultSchedule(_ code: String, title: String) -> LegacyResultSchedule {
        return LegacyResultSchedule(
            code: code,
            title: title,
            visitMinutes: 0,
            phone: "",
            attempts: 0,
            maximum: 0.0,
            status: LegacyResultScheduleStatus.`open`
        )
    }
}
