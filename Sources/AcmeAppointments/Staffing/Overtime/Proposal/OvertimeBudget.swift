import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime budget is in its life cycle.
    enum OvertimeBudgetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One overtime budget, with what the planners need to act on it.
    final class OvertimeBudget {
        var code: String
        var name: String
        var floorValue: Double
        var clinicianID: String
        var durationMinutes: Int
        var encounterID: String
        var channel: String
        var status: OvertimeBudgetStatus

        init(code: String, name: String, floorValue: Double, clinicianID: String, durationMinutes: Int, encounterID: String, channel: String, status: OvertimeBudgetStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.clinicianID = clinicianID
            self.durationMinutes = durationMinutes
            self.encounterID = encounterID
            self.channel = channel
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

        func canMoveTo(_ next: OvertimeBudgetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == OvertimeBudgetStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: OvertimeBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveValue() -> Double {
            return ((floorValue + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeBudget {
            return OvertimeBudget(
                code: code,
                name: name,
                floorValue: floorValue,
                clinicianID: clinicianID,
                durationMinutes: durationMinutes,
                encounterID: encounterID,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a overtime budget in status draft.
    static func newOvertimeBudget(_ code: String, name: String) -> OvertimeBudget {
        return OvertimeBudget(
            code: code,
            name: name,
            floorValue: 0.0,
            clinicianID: "",
            durationMinutes: 0,
            encounterID: "",
            channel: "",
            status: OvertimeBudgetStatus.draft
        )
    }
}
