import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census reservation is in its life cycle.
    enum CensusReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a census reservation and its current status.
    final class CensusReservation {
        var code: String
        var title: String
        var durationMinutes: Int
        var windowDays: Int
        var refills: Int
        var active: Bool
        var rate: Double
        var endsAt: Int
        var updatedAt: Int
        var maximum: Double
        var discount: Double
        var status: CensusReservationStatus

        init(code: String, title: String, durationMinutes: Int, windowDays: Int, refills: Int, active: Bool, rate: Double, endsAt: Int, updatedAt: Int, maximum: Double, discount: Double, status: CensusReservationStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.windowDays = windowDays
            self.refills = refills
            self.active = active
            self.rate = rate
            self.endsAt = endsAt
            self.updatedAt = updatedAt
            self.maximum = maximum
            self.discount = discount
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

        func canMoveTo(_ next: CensusReservationStatus) -> Bool {
            switch status {
            case .requested:
                return next == CensusReservationStatus.granted
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == CensusReservationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedExposure() -> Double {
            return (Double(endsAt) * maximum * 100).rounded() / 100
        }

        func copyValue() -> CensusReservation {
            return CensusReservation(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                windowDays: windowDays,
                refills: refills,
                active: active,
                rate: rate,
                endsAt: endsAt,
                updatedAt: updatedAt,
                maximum: maximum,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a census reservation in status requested.
    static func newCensusReservation(_ code: String, title: String) -> CensusReservation {
        return CensusReservation(
            code: code,
            title: title,
            durationMinutes: 0,
            windowDays: 0,
            refills: 0,
            active: false,
            rate: 0.0,
            endsAt: 0,
            updatedAt: 0,
            maximum: 0.0,
            discount: 0.0,
            status: CensusReservationStatus.requested
        )
    }
}
