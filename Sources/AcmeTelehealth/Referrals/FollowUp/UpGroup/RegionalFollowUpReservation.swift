import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional follow up reservation is in its life cycle.
    enum RegionalFollowUpReservationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A regional follow up reservation as the follow up team keeps it.
    final class RegionalFollowUpReservation {
        var code: String
        var name: String
        var facility: String
        var externalRef: String
        var active: Bool
        var payer: String
        var createdAt: Int
        var status: RegionalFollowUpReservationStatus

        init(code: String, name: String, facility: String, externalRef: String, active: Bool, payer: String, createdAt: Int, status: RegionalFollowUpReservationStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.externalRef = externalRef
            self.active = active
            self.payer = payer
            self.createdAt = createdAt
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

        func canMoveTo(_ next: RegionalFollowUpReservationStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == RegionalFollowUpReservationStatus.rejected
            case .rejected:
                return next == RegionalFollowUpReservationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalFollowUpReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional follow up reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> RegionalFollowUpReservation {
            return RegionalFollowUpReservation(
                code: code,
                name: name,
                facility: facility,
                externalRef: externalRef,
                active: active,
                payer: payer,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a regional follow up reservation in status proposed.
    static func newRegionalFollowUpReservation(_ code: String, name: String) -> RegionalFollowUpReservation {
        return RegionalFollowUpReservation(
            code: code,
            name: name,
            facility: "",
            externalRef: "",
            active: false,
            payer: "",
            createdAt: 0,
            status: RegionalFollowUpReservationStatus.proposed
        )
    }
}
