import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff reservation is in its life cycle.
    enum HandoffReservationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A handoff reservation as the handoff team keeps it.
    final class HandoffReservation {
        var code: String
        var title: String
        var externalRef: String
        var phone: String
        var weight: Double
        var description: String
        var status: HandoffReservationStatus

        init(code: String, title: String, externalRef: String, phone: String, weight: Double, description: String, status: HandoffReservationStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.phone = phone
            self.weight = weight
            self.description = description
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

        func canMoveTo(_ next: HandoffReservationStatus) -> Bool {
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
                return next == HandoffReservationStatus.rejected
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

        func moveTo(_ next: HandoffReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> HandoffReservation {
            return HandoffReservation(
                code: code,
                title: title,
                externalRef: externalRef,
                phone: phone,
                weight: weight,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a handoff reservation in status proposed.
    static func newHandoffReservation(_ code: String, title: String) -> HandoffReservation {
        return HandoffReservation(
            code: code,
            title: title,
            externalRef: "",
            phone: "",
            weight: 0.0,
            description: "",
            status: HandoffReservationStatus.proposed
        )
    }
}
