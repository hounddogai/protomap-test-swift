import AcmePlatform
import Foundation

extension Consent {
    /// Where a global proxy reservation is in its life cycle.
    enum GlobalProxyReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a global proxy reservation and its current status.
    final class GlobalProxyReservation {
        var code: String
        var label: String
        var revision: Int
        var approved: Bool
        var retries: Int
        var copay: Double
        var channel: String
        var region: String
        var ward: String
        var attempts: Int
        var status: GlobalProxyReservationStatus

        init(code: String, label: String, revision: Int, approved: Bool, retries: Int, copay: Double, channel: String, region: String, ward: String, attempts: Int, status: GlobalProxyReservationStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.approved = approved
            self.retries = retries
            self.copay = copay
            self.channel = channel
            self.region = region
            self.ward = ward
            self.attempts = attempts
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

        func canMoveTo(_ next: GlobalProxyReservationStatus) -> Bool {
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
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == GlobalProxyReservationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalProxyReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global proxy reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netValue() -> Double {
            return (Double(revision) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> GlobalProxyReservation {
            return GlobalProxyReservation(
                code: code,
                label: label,
                revision: revision,
                approved: approved,
                retries: retries,
                copay: copay,
                channel: channel,
                region: region,
                ward: ward,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a global proxy reservation in status requested.
    static func newGlobalProxyReservation(_ code: String, label: String) -> GlobalProxyReservation {
        return GlobalProxyReservation(
            code: code,
            label: label,
            revision: 0,
            approved: false,
            retries: 0,
            copay: 0.0,
            channel: "",
            region: "",
            ward: "",
            attempts: 0,
            status: GlobalProxyReservationStatus.requested
        )
    }
}
