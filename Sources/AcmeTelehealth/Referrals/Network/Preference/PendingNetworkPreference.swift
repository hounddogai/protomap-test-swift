import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending network preference is in its life cycle.
    enum PendingNetworkPreferenceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One pending network preference, with what the planners need to act on it.
    final class PendingNetworkPreference {
        var code: String
        var title: String
        var capacity: Int
        var tags: [String]
        var cost: Double
        var attempts: Int
        var active: Bool
        var status: PendingNetworkPreferenceStatus

        init(code: String, title: String, capacity: Int, tags: [String], cost: Double, attempts: Int, active: Bool, status: PendingNetworkPreferenceStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.tags = tags
            self.cost = cost
            self.attempts = attempts
            self.active = active
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

        func canMoveTo(_ next: PendingNetworkPreferenceStatus) -> Bool {
            switch status {
            case .requested:
                return next == PendingNetworkPreferenceStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == PendingNetworkPreferenceStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingNetworkPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending network preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending network preference") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedVolume() -> Double {
            return ((Double(attempts) + cost) * 100).rounded() / 100
        }

        func copyValue() -> PendingNetworkPreference {
            return PendingNetworkPreference(
                code: code,
                title: title,
                capacity: capacity,
                tags: tags,
                cost: cost,
                attempts: attempts,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending network preference in status requested.
    static func newPendingNetworkPreference(_ code: String, title: String) -> PendingNetworkPreference {
        return PendingNetworkPreference(
            code: code,
            title: title,
            capacity: 0,
            tags: [],
            cost: 0.0,
            attempts: 0,
            active: false,
            status: PendingNetworkPreferenceStatus.requested
        )
    }
}
