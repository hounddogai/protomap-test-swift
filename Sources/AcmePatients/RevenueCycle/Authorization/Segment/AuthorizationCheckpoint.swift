import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization checkpoint is in its life cycle.
    enum AuthorizationCheckpointStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A authorization checkpoint as the authorization team keeps it.
    final class AuthorizationCheckpoint {
        var code: String
        var title: String
        var payer: String
        var ward: String
        var score: Double
        var minimum: Double
        var checksum: String
        var status: AuthorizationCheckpointStatus

        init(code: String, title: String, payer: String, ward: String, score: Double, minimum: Double, checksum: String, status: AuthorizationCheckpointStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.ward = ward
            self.score = score
            self.minimum = minimum
            self.checksum = checksum
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

        func canMoveTo(_ next: AuthorizationCheckpointStatus) -> Bool {
            switch status {
            case .requested:
                return next == AuthorizationCheckpointStatus.revoked || next == AuthorizationCheckpointStatus.expired
            case .granted:
                return next == AuthorizationCheckpointStatus.revoked || next == AuthorizationCheckpointStatus.expired
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

        func moveTo(_ next: AuthorizationCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedLoad() -> Double {
            return ((score - minimum) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationCheckpoint {
            return AuthorizationCheckpoint(
                code: code,
                title: title,
                payer: payer,
                ward: ward,
                score: score,
                minimum: minimum,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a authorization checkpoint in status requested.
    static func newAuthorizationCheckpoint(_ code: String, title: String) -> AuthorizationCheckpoint {
        return AuthorizationCheckpoint(
            code: code,
            title: title,
            payer: "",
            ward: "",
            score: 0.0,
            minimum: 0.0,
            checksum: "",
            status: AuthorizationCheckpointStatus.requested
        )
    }
}
