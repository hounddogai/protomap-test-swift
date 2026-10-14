import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning schedule is in its life cycle.
    enum CleaningScheduleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A cleaning schedule as the cleaning team keeps it.
    final class CleaningSchedule {
        var code: String
        var name: String
        var clinicianID: String
        var active: Bool
        var quantity: Int
        var status: CleaningScheduleStatus

        init(code: String, name: String, clinicianID: String, active: Bool, quantity: Int, status: CleaningScheduleStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.active = active
            self.quantity = quantity
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

        func canMoveTo(_ next: CleaningScheduleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == CleaningScheduleStatus.rejected || next == CleaningScheduleStatus.withdrawn
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

        func moveTo(_ next: CleaningScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> CleaningSchedule {
            return CleaningSchedule(
                code: code,
                name: name,
                clinicianID: clinicianID,
                active: active,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a cleaning schedule in status proposed.
    static func newCleaningSchedule(_ code: String, name: String) -> CleaningSchedule {
        return CleaningSchedule(
            code: code,
            name: name,
            clinicianID: "",
            active: false,
            quantity: 0,
            status: CleaningScheduleStatus.proposed
        )
    }
}
