import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network schedule is in its life cycle.
    enum NetworkScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A network schedule as the network team keeps it.
    final class NetworkSchedule {
        var code: String
        var title: String
        var margin: Double
        var acuity: Int
        var windowDays: Int
        var currency: String
        var timezone: String
        var status: NetworkScheduleStatus

        init(code: String, title: String, margin: Double, acuity: Int, windowDays: Int, currency: String, timezone: String, status: NetworkScheduleStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.acuity = acuity
            self.windowDays = windowDays
            self.currency = currency
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

        func canMoveTo(_ next: NetworkScheduleStatus) -> Bool {
            switch status {
            case .planned:
                return next == NetworkScheduleStatus.completed
            case .scheduled:
                return next == NetworkScheduleStatus.cancelled
            case .inProgress:
                return next == NetworkScheduleStatus.completed || next == NetworkScheduleStatus.cancelled
            case .completed:
                return next == NetworkScheduleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedExposure() -> Double {
            return ((Double(windowDays) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> NetworkSchedule {
            return NetworkSchedule(
                code: code,
                title: title,
                margin: margin,
                acuity: acuity,
                windowDays: windowDays,
                currency: currency,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a network schedule in status planned.
    static func newNetworkSchedule(_ code: String, title: String) -> NetworkSchedule {
        return NetworkSchedule(
            code: code,
            title: title,
            margin: 0.0,
            acuity: 0,
            windowDays: 0,
            currency: "",
            timezone: "",
            status: NetworkScheduleStatus.planned
        )
    }
}
