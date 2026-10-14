import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol reservation is in its life cycle.
    enum CareProtocolReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One care protocol reservation, with what the planners need to act on it.
    final class CareProtocolReservation {
        var code: String
        var title: String
        var updatedAt: Int
        var createdAt: Int
        var margin: Double
        var floorValue: Double
        var timezone: String
        var notes: String
        var amount: Double
        var name: String
        var status: CareProtocolReservationStatus

        init(code: String, title: String, updatedAt: Int, createdAt: Int, margin: Double, floorValue: Double, timezone: String, notes: String, amount: Double, name: String, status: CareProtocolReservationStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.createdAt = createdAt
            self.margin = margin
            self.floorValue = floorValue
            self.timezone = timezone
            self.notes = notes
            self.amount = amount
            self.name = name
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

        func canMoveTo(_ next: CareProtocolReservationStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == CareProtocolReservationStatus.revoked || next == CareProtocolReservationStatus.expired
            case .revoked:
                return next == CareProtocolReservationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netLoad() -> Double {
            return ((amount + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolReservation {
            return CareProtocolReservation(
                code: code,
                title: title,
                updatedAt: updatedAt,
                createdAt: createdAt,
                margin: margin,
                floorValue: floorValue,
                timezone: timezone,
                notes: notes,
                amount: amount,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care protocol reservation in status requested.
    static func newCareProtocolReservation(_ code: String, title: String) -> CareProtocolReservation {
        return CareProtocolReservation(
            code: code,
            title: title,
            updatedAt: 0,
            createdAt: 0,
            margin: 0.0,
            floorValue: 0.0,
            timezone: "",
            notes: "",
            amount: 0.0,
            name: "",
            status: CareProtocolReservationStatus.requested
        )
    }
}
