import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance request is in its life cycle.
    enum RemittanceRequestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A remittance request. Its code is unique within a tenant.
    final class RemittanceRequest {
        var code: String
        var name: String
        var graceDays: Int
        var region: String
        var revision: Int
        var startsAt: Int
        var expiresAt: Int
        var pinned: Bool
        var attempts: Int
        var status: RemittanceRequestStatus

        init(code: String, name: String, graceDays: Int, region: String, revision: Int, startsAt: Int, expiresAt: Int, pinned: Bool, attempts: Int, status: RemittanceRequestStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.region = region
            self.revision = revision
            self.startsAt = startsAt
            self.expiresAt = expiresAt
            self.pinned = pinned
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

        func canMoveTo(_ next: RemittanceRequestStatus) -> Bool {
            switch status {
            case .requested:
                return next == RemittanceRequestStatus.revoked || next == RemittanceRequestStatus.expired
            case .granted:
                return next == RemittanceRequestStatus.revoked || next == RemittanceRequestStatus.expired
            case .revoked:
                return next == RemittanceRequestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveVolume() -> Double {
            return ((Double(expiresAt) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceRequest {
            return RemittanceRequest(
                code: code,
                name: name,
                graceDays: graceDays,
                region: region,
                revision: revision,
                startsAt: startsAt,
                expiresAt: expiresAt,
                pinned: pinned,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a remittance request in status requested.
    static func newRemittanceRequest(_ code: String, name: String) -> RemittanceRequest {
        return RemittanceRequest(
            code: code,
            name: name,
            graceDays: 0,
            region: "",
            revision: 0,
            startsAt: 0,
            expiresAt: 0,
            pinned: false,
            attempts: 0,
            status: RemittanceRequestStatus.requested
        )
    }
}
