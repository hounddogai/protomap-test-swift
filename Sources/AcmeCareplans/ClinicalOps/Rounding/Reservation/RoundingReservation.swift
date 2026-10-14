import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding reservation is in its life cycle.
    enum RoundingReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A rounding reservation. Its code is unique within a tenant.
    final class RoundingReservation {
        var code: String
        var name: String
        var dosageMg: Double
        var priority: Int
        var description: String
        var graceDays: Int
        var patientRef: String
        var weight: Double
        var maximum: Double
        var acuity: Int
        var category: String
        var status: RoundingReservationStatus

        init(code: String, name: String, dosageMg: Double, priority: Int, description: String, graceDays: Int, patientRef: String, weight: Double, maximum: Double, acuity: Int, category: String, status: RoundingReservationStatus) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.priority = priority
            self.description = description
            self.graceDays = graceDays
            self.patientRef = patientRef
            self.weight = weight
            self.maximum = maximum
            self.acuity = acuity
            self.category = category
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

        func canMoveTo(_ next: RoundingReservationStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == RoundingReservationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedTotal() -> Double {
            return (Double(priority) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> RoundingReservation {
            return RoundingReservation(
                code: code,
                name: name,
                dosageMg: dosageMg,
                priority: priority,
                description: description,
                graceDays: graceDays,
                patientRef: patientRef,
                weight: weight,
                maximum: maximum,
                acuity: acuity,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a rounding reservation in status requested.
    static func newRoundingReservation(_ code: String, name: String) -> RoundingReservation {
        return RoundingReservation(
            code: code,
            name: name,
            dosageMg: 0.0,
            priority: 0,
            description: "",
            graceDays: 0,
            patientRef: "",
            weight: 0.0,
            maximum: 0.0,
            acuity: 0,
            category: "",
            status: RoundingReservationStatus.requested
        )
    }
}
