import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a scheduled dispense reservation is in its life cycle.
    enum ScheduledDispenseReservationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A scheduled dispense reservation. Its code is unique within a tenant.
    final class ScheduledDispenseReservation {
        var code: String
        var name: String
        var externalRef: String
        var active: Bool
        var ownerID: String
        var retries: Int
        var category: String
        var status: ScheduledDispenseReservationStatus

        init(code: String, name: String, externalRef: String, active: Bool, ownerID: String, retries: Int, category: String, status: ScheduledDispenseReservationStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.active = active
            self.ownerID = ownerID
            self.retries = retries
            self.category = category
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

        func canMoveTo(_ next: ScheduledDispenseReservationStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ScheduledDispenseReservationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledDispenseReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled dispense reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> ScheduledDispenseReservation {
            return ScheduledDispenseReservation(
                code: code,
                name: name,
                externalRef: externalRef,
                active: active,
                ownerID: ownerID,
                retries: retries,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a scheduled dispense reservation in status proposed.
    static func newScheduledDispenseReservation(_ code: String, name: String) -> ScheduledDispenseReservation {
        return ScheduledDispenseReservation(
            code: code,
            name: name,
            externalRef: "",
            active: false,
            ownerID: "",
            retries: 0,
            category: "",
            status: ScheduledDispenseReservationStatus.proposed
        )
    }
}
