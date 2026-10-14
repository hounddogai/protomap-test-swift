import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling disclosure reservation is in its life cycle.
    enum RollingDisclosureReservationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a rolling disclosure reservation and its current status.
    final class RollingDisclosureReservation {
        var code: String
        var name: String
        var bed: String
        var floorValue: Double
        var phone: String
        var budget: Double
        var status: RollingDisclosureReservationStatus

        init(code: String, name: String, bed: String, floorValue: Double, phone: String, budget: Double, status: RollingDisclosureReservationStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.floorValue = floorValue
            self.phone = phone
            self.budget = budget
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

        func canMoveTo(_ next: RollingDisclosureReservationStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RollingDisclosureReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling disclosure reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedValue() -> Double {
            return (budget * floorValue * 100).rounded() / 100
        }

        func copyValue() -> RollingDisclosureReservation {
            return RollingDisclosureReservation(
                code: code,
                name: name,
                bed: bed,
                floorValue: floorValue,
                phone: phone,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling disclosure reservation in status created.
    static func newRollingDisclosureReservation(_ code: String, name: String) -> RollingDisclosureReservation {
        return RollingDisclosureReservation(
            code: code,
            name: name,
            bed: "",
            floorValue: 0.0,
            phone: "",
            budget: 0.0,
            status: RollingDisclosureReservationStatus.created
        )
    }
}
