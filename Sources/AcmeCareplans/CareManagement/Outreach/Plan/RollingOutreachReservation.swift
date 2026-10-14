import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a rolling outreach reservation is in its life cycle.
    enum RollingOutreachReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A rolling outreach reservation. Its code is unique within a tenant.
    final class RollingOutreachReservation {
        var code: String
        var label: String
        var graceDays: Int
        var retries: Int
        var updatedAt: Int
        var endsAt: Int
        var limit: Int
        var discount: Double
        var status: RollingOutreachReservationStatus

        init(code: String, label: String, graceDays: Int, retries: Int, updatedAt: Int, endsAt: Int, limit: Int, discount: Double, status: RollingOutreachReservationStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.retries = retries
            self.updatedAt = updatedAt
            self.endsAt = endsAt
            self.limit = limit
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

        func canMoveTo(_ next: RollingOutreachReservationStatus) -> Bool {
            switch status {
            case .requested:
                return next == RollingOutreachReservationStatus.granted
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: RollingOutreachReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling outreach reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netLoad() -> Double {
            return ((Double(graceDays) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> RollingOutreachReservation {
            return RollingOutreachReservation(
                code: code,
                label: label,
                graceDays: graceDays,
                retries: retries,
                updatedAt: updatedAt,
                endsAt: endsAt,
                limit: limit,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling outreach reservation in status requested.
    static func newRollingOutreachReservation(_ code: String, label: String) -> RollingOutreachReservation {
        return RollingOutreachReservation(
            code: code,
            label: label,
            graceDays: 0,
            retries: 0,
            updatedAt: 0,
            endsAt: 0,
            limit: 0,
            discount: 0.0,
            status: RollingOutreachReservationStatus.requested
        )
    }
}
