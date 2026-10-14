import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal courier exception is in its life cycle.
    enum SeasonalCourierExceptionStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a seasonal courier exception and its current status.
    final class SeasonalCourierException {
        var code: String
        var title: String
        var contactEmail: String
        var durationMinutes: Int
        var bed: String
        var timezone: String
        var status: SeasonalCourierExceptionStatus

        init(code: String, title: String, contactEmail: String, durationMinutes: Int, bed: String, timezone: String, status: SeasonalCourierExceptionStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.durationMinutes = durationMinutes
            self.bed = bed
            self.timezone = timezone
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

        func canMoveTo(_ next: SeasonalCourierExceptionStatus) -> Bool {
            switch status {
            case .planned:
                return next == SeasonalCourierExceptionStatus.scheduled || next == SeasonalCourierExceptionStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .completed:
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
                return next == SeasonalCourierExceptionStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalCourierExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal courier exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal courier exception") \(code)"
        }

        func measuredValue() -> Double {
            return Double(durationMinutes)
        }

        func copyValue() -> SeasonalCourierException {
            return SeasonalCourierException(
                code: code,
                title: title,
                contactEmail: contactEmail,
                durationMinutes: durationMinutes,
                bed: bed,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal courier exception in status planned.
    static func newSeasonalCourierException(_ code: String, title: String) -> SeasonalCourierException {
        return SeasonalCourierException(
            code: code,
            title: title,
            contactEmail: "",
            durationMinutes: 0,
            bed: "",
            timezone: "",
            status: SeasonalCourierExceptionStatus.planned
        )
    }
}
