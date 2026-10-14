import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert window is in its life cycle.
    enum AlertWindowStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One alert window, with what the planners need to act on it.
    final class AlertWindow {
        var code: String
        var title: String
        var graceDays: Int
        var summary: String
        var segment: String
        var facility: String
        var status: AlertWindowStatus

        init(code: String, title: String, graceDays: Int, summary: String, segment: String, facility: String, status: AlertWindowStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.summary = summary
            self.segment = segment
            self.facility = facility
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

        func canMoveTo(_ next: AlertWindowStatus) -> Bool {
            switch status {
            case .planned:
                return next == AlertWindowStatus.scheduled || next == AlertWindowStatus.completed
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == AlertWindowStatus.cancelled
            case .completed:
                return next == AlertWindowStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("alert window") \(code)"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> AlertWindow {
            return AlertWindow(
                code: code,
                title: title,
                graceDays: graceDays,
                summary: summary,
                segment: segment,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a alert window in status planned.
    static func newAlertWindow(_ code: String, title: String) -> AlertWindow {
        return AlertWindow(
            code: code,
            title: title,
            graceDays: 0,
            summary: "",
            segment: "",
            facility: "",
            status: AlertWindowStatus.planned
        )
    }
}
