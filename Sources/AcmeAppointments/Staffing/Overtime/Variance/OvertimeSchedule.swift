import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime schedule is in its life cycle.
    enum OvertimeScheduleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A overtime schedule. Its code is unique within a tenant.
    final class OvertimeSchedule {
        var code: String
        var title: String
        var durationMinutes: Int
        var floorValue: Double
        var margin: Double
        var status: OvertimeScheduleStatus

        init(code: String, title: String, durationMinutes: Int, floorValue: Double, margin: Double, status: OvertimeScheduleStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.floorValue = floorValue
            self.margin = margin
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OvertimeScheduleStatus) -> Bool {
            switch status {
            case .requested:
                return next == OvertimeScheduleStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: OvertimeScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("overtime schedule") \(code)"
        }

        func netLoad() -> Double {
            return ((margin - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeSchedule {
            return OvertimeSchedule(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                floorValue: floorValue,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a overtime schedule in status requested.
    static func newOvertimeSchedule(_ code: String, title: String) -> OvertimeSchedule {
        return OvertimeSchedule(
            code: code,
            title: title,
            durationMinutes: 0,
            floorValue: 0.0,
            margin: 0.0,
            status: OvertimeScheduleStatus.requested
        )
    }
}
