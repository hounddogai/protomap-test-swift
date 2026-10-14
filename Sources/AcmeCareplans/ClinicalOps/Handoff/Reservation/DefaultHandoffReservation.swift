import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a default handoff reservation is in its life cycle.
    enum DefaultHandoffReservationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A default handoff reservation. Its code is unique within a tenant.
    final class DefaultHandoffReservation {
        var code: String
        var title: String
        var currency: String
        var active: Bool
        var budget: Double
        var durationMinutes: Int
        var encounterID: String
        var procedureCode: String
        var status: DefaultHandoffReservationStatus

        init(code: String, title: String, currency: String, active: Bool, budget: Double, durationMinutes: Int, encounterID: String, procedureCode: String, status: DefaultHandoffReservationStatus) {
            self.code = code
            self.title = title
            self.currency = currency
            self.active = active
            self.budget = budget
            self.durationMinutes = durationMinutes
            self.encounterID = encounterID
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: DefaultHandoffReservationStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == DefaultHandoffReservationStatus.suspended || next == DefaultHandoffReservationStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == DefaultHandoffReservationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultHandoffReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default handoff reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedValue() -> Double {
            return ((budget + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultHandoffReservation {
            return DefaultHandoffReservation(
                code: code,
                title: title,
                currency: currency,
                active: active,
                budget: budget,
                durationMinutes: durationMinutes,
                encounterID: encounterID,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default handoff reservation in status draft.
    static func newDefaultHandoffReservation(_ code: String, title: String) -> DefaultHandoffReservation {
        return DefaultHandoffReservation(
            code: code,
            title: title,
            currency: "",
            active: false,
            budget: 0.0,
            durationMinutes: 0,
            encounterID: "",
            procedureCode: "",
            status: DefaultHandoffReservationStatus.draft
        )
    }
}
