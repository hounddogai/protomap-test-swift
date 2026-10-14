import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict result window is in its life cycle.
    enum StrictResultWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict result window as the result team keeps it.
    final class StrictResultWindow {
        var code: String
        var name: String
        var floorValue: Double
        var graceDays: Int
        var clinicianID: String
        var approved: Bool
        var active: Bool
        var status: StrictResultWindowStatus

        init(code: String, name: String, floorValue: Double, graceDays: Int, clinicianID: String, approved: Bool, active: Bool, status: StrictResultWindowStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.graceDays = graceDays
            self.clinicianID = clinicianID
            self.approved = approved
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictResultWindowStatus) -> Bool {
            switch status {
            case .draft:
                return next == StrictResultWindowStatus.closed
            case .pending:
                return next == StrictResultWindowStatus.active || next == StrictResultWindowStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == StrictResultWindowStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictResultWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict result window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netVolume() -> Double {
            return ((floorValue + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> StrictResultWindow {
            return StrictResultWindow(
                code: code,
                name: name,
                floorValue: floorValue,
                graceDays: graceDays,
                clinicianID: clinicianID,
                approved: approved,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict result window in status draft.
    static func newStrictResultWindow(_ code: String, name: String) -> StrictResultWindow {
        return StrictResultWindow(
            code: code,
            name: name,
            floorValue: 0.0,
            graceDays: 0,
            clinicianID: "",
            approved: false,
            active: false,
            status: StrictResultWindowStatus.draft
        )
    }
}
