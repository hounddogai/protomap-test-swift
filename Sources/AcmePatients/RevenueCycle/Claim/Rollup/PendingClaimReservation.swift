import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending claim reservation is in its life cycle.
    enum PendingClaimReservationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A pending claim reservation. Its code is unique within a tenant.
    final class PendingClaimReservation {
        var code: String
        var name: String
        var graceDays: Int
        var timezone: String
        var copay: Double
        var contactEmail: String
        var retries: Int
        var status: PendingClaimReservationStatus

        init(code: String, name: String, graceDays: Int, timezone: String, copay: Double, contactEmail: String, retries: Int, status: PendingClaimReservationStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.timezone = timezone
            self.copay = copay
            self.contactEmail = contactEmail
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingClaimReservationStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == PendingClaimReservationStatus.draining
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == PendingClaimReservationStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingClaimReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending claim reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending claim reservation") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(graceDays) - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> PendingClaimReservation {
            return PendingClaimReservation(
                code: code,
                name: name,
                graceDays: graceDays,
                timezone: timezone,
                copay: copay,
                contactEmail: contactEmail,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending claim reservation in status idle.
    static func newPendingClaimReservation(_ code: String, name: String) -> PendingClaimReservation {
        return PendingClaimReservation(
            code: code,
            name: name,
            graceDays: 0,
            timezone: "",
            copay: 0.0,
            contactEmail: "",
            retries: 0,
            status: PendingClaimReservationStatus.idle
        )
    }
}
