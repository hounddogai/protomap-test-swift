import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network quota is in its life cycle.
    enum NetworkQuotaStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A network quota as the network team keeps it.
    final class NetworkQuota {
        var code: String
        var title: String
        var minimum: Double
        var notes: String
        var retries: Int
        var encounterID: String
        var limit: Int
        var pinned: Bool
        var source: String
        var status: NetworkQuotaStatus

        init(code: String, title: String, minimum: Double, notes: String, retries: Int, encounterID: String, limit: Int, pinned: Bool, source: String, status: NetworkQuotaStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.notes = notes
            self.retries = retries
            self.encounterID = encounterID
            self.limit = limit
            self.pinned = pinned
            self.source = source
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

        func canMoveTo(_ next: NetworkQuotaStatus) -> Bool {
            switch status {
            case .requested:
                return next == NetworkQuotaStatus.revoked || next == NetworkQuotaStatus.expired
            case .granted:
                return next == NetworkQuotaStatus.revoked
            case .revoked:
                return next == NetworkQuotaStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveTotal() -> Double {
            return (minimum * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> NetworkQuota {
            return NetworkQuota(
                code: code,
                title: title,
                minimum: minimum,
                notes: notes,
                retries: retries,
                encounterID: encounterID,
                limit: limit,
                pinned: pinned,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a network quota in status requested.
    static func newNetworkQuota(_ code: String, title: String) -> NetworkQuota {
        return NetworkQuota(
            code: code,
            title: title,
            minimum: 0.0,
            notes: "",
            retries: 0,
            encounterID: "",
            limit: 0,
            pinned: false,
            source: "",
            status: NetworkQuotaStatus.requested
        )
    }
}
