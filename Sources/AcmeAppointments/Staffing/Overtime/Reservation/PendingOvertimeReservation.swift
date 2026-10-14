import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending overtime reservation is in its life cycle.
    enum PendingOvertimeReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A pending overtime reservation as the overtime team keeps it.
    final class PendingOvertimeReservation {
        var code: String
        var title: String
        var ward: String
        var createdAt: Int
        var limit: Int
        var currency: String
        var dosageMg: Double
        var ratio: Double
        var status: PendingOvertimeReservationStatus

        init(code: String, title: String, ward: String, createdAt: Int, limit: Int, currency: String, dosageMg: Double, ratio: Double, status: PendingOvertimeReservationStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.createdAt = createdAt
            self.limit = limit
            self.currency = currency
            self.dosageMg = dosageMg
            self.ratio = ratio
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

        func canMoveTo(_ next: PendingOvertimeReservationStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == PendingOvertimeReservationStatus.revoked
            case .revoked:
                return next == PendingOvertimeReservationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingOvertimeReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending overtime reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("pending overtime reservation") \(code)"
        }

        func effectiveTotal() -> Double {
            return (dosageMg * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> PendingOvertimeReservation {
            return PendingOvertimeReservation(
                code: code,
                title: title,
                ward: ward,
                createdAt: createdAt,
                limit: limit,
                currency: currency,
                dosageMg: dosageMg,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a pending overtime reservation in status requested.
    static func newPendingOvertimeReservation(_ code: String, title: String) -> PendingOvertimeReservation {
        return PendingOvertimeReservation(
            code: code,
            title: title,
            ward: "",
            createdAt: 0,
            limit: 0,
            currency: "",
            dosageMg: 0.0,
            ratio: 0.0,
            status: PendingOvertimeReservationStatus.requested
        )
    }
}
