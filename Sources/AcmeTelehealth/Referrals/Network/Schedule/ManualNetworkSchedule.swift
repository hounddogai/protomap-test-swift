import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual network schedule is in its life cycle.
    enum ManualNetworkScheduleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a manual network schedule and its current status.
    final class ManualNetworkSchedule {
        var code: String
        var name: String
        var title: String
        var floorValue: Double
        var active: Bool
        var status: ManualNetworkScheduleStatus

        init(code: String, name: String, title: String, floorValue: Double, active: Bool, status: ManualNetworkScheduleStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.floorValue = floorValue
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualNetworkScheduleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ManualNetworkScheduleStatus.rejected || next == ManualNetworkScheduleStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ManualNetworkScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual network schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> ManualNetworkSchedule {
            return ManualNetworkSchedule(
                code: code,
                name: name,
                title: title,
                floorValue: floorValue,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual network schedule in status proposed.
    static func newManualNetworkSchedule(_ code: String, name: String) -> ManualNetworkSchedule {
        return ManualNetworkSchedule(
            code: code,
            name: name,
            title: "",
            floorValue: 0.0,
            active: false,
            status: ManualNetworkScheduleStatus.proposed
        )
    }
}
