import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential reservation is in its life cycle.
    enum CredentialReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One credential reservation, with what the planners need to act on it.
    final class CredentialReservation {
        var code: String
        var title: String
        var ownerID: String
        var active: Bool
        var allergy: String
        var floorValue: Double
        var endsAt: Int
        var capacity: Int
        var acuity: Int
        var startsAt: Int
        var durationMinutes: Int
        var status: CredentialReservationStatus

        init(code: String, title: String, ownerID: String, active: Bool, allergy: String, floorValue: Double, endsAt: Int, capacity: Int, acuity: Int, startsAt: Int, durationMinutes: Int, status: CredentialReservationStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.active = active
            self.allergy = allergy
            self.floorValue = floorValue
            self.endsAt = endsAt
            self.capacity = capacity
            self.acuity = acuity
            self.startsAt = startsAt
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: CredentialReservationStatus) -> Bool {
            switch status {
            case .requested:
                return next == CredentialReservationStatus.granted || next == CredentialReservationStatus.revoked
            case .granted:
                return next == CredentialReservationStatus.revoked || next == CredentialReservationStatus.expired
            case .revoked:
                return next == CredentialReservationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedValue() -> Double {
            return ((Double(durationMinutes) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> CredentialReservation {
            return CredentialReservation(
                code: code,
                title: title,
                ownerID: ownerID,
                active: active,
                allergy: allergy,
                floorValue: floorValue,
                endsAt: endsAt,
                capacity: capacity,
                acuity: acuity,
                startsAt: startsAt,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a credential reservation in status requested.
    static func newCredentialReservation(_ code: String, title: String) -> CredentialReservation {
        return CredentialReservation(
            code: code,
            title: title,
            ownerID: "",
            active: false,
            allergy: "",
            floorValue: 0.0,
            endsAt: 0,
            capacity: 0,
            acuity: 0,
            startsAt: 0,
            durationMinutes: 0,
            status: CredentialReservationStatus.requested
        )
    }
}
