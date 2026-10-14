import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a primary remittance schedule is in its life cycle.
    enum PrimaryRemittanceScheduleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One primary remittance schedule, with what the planners need to act on it.
    final class PrimaryRemittanceSchedule {
        var code: String
        var name: String
        var margin: Double
        var visible: Bool
        var reviewer: String
        var title: String
        var currency: String
        var status: PrimaryRemittanceScheduleStatus

        init(code: String, name: String, margin: Double, visible: Bool, reviewer: String, title: String, currency: String, status: PrimaryRemittanceScheduleStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.visible = visible
            self.reviewer = reviewer
            self.title = title
            self.currency = currency
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryRemittanceScheduleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == PrimaryRemittanceScheduleStatus.ready
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == PrimaryRemittanceScheduleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryRemittanceScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary remittance schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary remittance schedule") \(code)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> PrimaryRemittanceSchedule {
            return PrimaryRemittanceSchedule(
                code: code,
                name: name,
                margin: margin,
                visible: visible,
                reviewer: reviewer,
                title: title,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary remittance schedule in status idle.
    static func newPrimaryRemittanceSchedule(_ code: String, name: String) -> PrimaryRemittanceSchedule {
        return PrimaryRemittanceSchedule(
            code: code,
            name: name,
            margin: 0.0,
            visible: false,
            reviewer: "",
            title: "",
            currency: "",
            status: PrimaryRemittanceScheduleStatus.idle
        )
    }
}
