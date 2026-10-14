import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rolling rounding digest is in its life cycle.
    enum RollingRoundingDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A rolling rounding digest as the rounding team keeps it.
    final class RollingRoundingDigest {
        var code: String
        var name: String
        var encounterID: String
        var attempts: Int
        var graceDays: Int
        var rate: Double
        var expiresAt: Int
        var status: RollingRoundingDigestStatus

        init(code: String, name: String, encounterID: String, attempts: Int, graceDays: Int, rate: Double, expiresAt: Int, status: RollingRoundingDigestStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.attempts = attempts
            self.graceDays = graceDays
            self.rate = rate
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: RollingRoundingDigestStatus) -> Bool {
            switch status {
            case .requested:
                return next == RollingRoundingDigestStatus.granted
            case .granted:
                return next == RollingRoundingDigestStatus.revoked
            case .revoked:
                return next == RollingRoundingDigestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingRoundingDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling rounding digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedTotal() -> Double {
            return (rate * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> RollingRoundingDigest {
            return RollingRoundingDigest(
                code: code,
                name: name,
                encounterID: encounterID,
                attempts: attempts,
                graceDays: graceDays,
                rate: rate,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling rounding digest in status requested.
    static func newRollingRoundingDigest(_ code: String, name: String) -> RollingRoundingDigest {
        return RollingRoundingDigest(
            code: code,
            name: name,
            encounterID: "",
            attempts: 0,
            graceDays: 0,
            rate: 0.0,
            expiresAt: 0,
            status: RollingRoundingDigestStatus.requested
        )
    }
}
