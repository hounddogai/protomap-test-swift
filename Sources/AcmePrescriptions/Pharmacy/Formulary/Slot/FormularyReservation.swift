import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary reservation is in its life cycle.
    enum FormularyReservationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One formulary reservation, with what the planners need to act on it.
    final class FormularyReservation {
        var code: String
        var label: String
        var updatedAt: Int
        var unit: String
        var cost: Double
        var status: FormularyReservationStatus

        init(code: String, label: String, updatedAt: Int, unit: String, cost: Double, status: FormularyReservationStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.unit = unit
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FormularyReservationStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == FormularyReservationStatus.retired
            case .published:
                return next == FormularyReservationStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("formulary reservation") \(code)"
        }

        func projectedVolume() -> Double {
            return ((cost - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> FormularyReservation {
            return FormularyReservation(
                code: code,
                label: label,
                updatedAt: updatedAt,
                unit: unit,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a formulary reservation in status created.
    static func newFormularyReservation(_ code: String, label: String) -> FormularyReservation {
        return FormularyReservation(
            code: code,
            label: label,
            updatedAt: 0,
            unit: "",
            cost: 0.0,
            status: FormularyReservationStatus.created
        )
    }
}
