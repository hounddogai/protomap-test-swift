import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up group is in its life cycle.
    enum FollowUpGroupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A follow up group as the follow up team keeps it.
    final class FollowUpGroup {
        var code: String
        var name: String
        var ward: String
        var maximum: Double
        var expiresAt: Int
        var limit: Int
        var status: FollowUpGroupStatus

        init(code: String, name: String, ward: String, maximum: Double, expiresAt: Int, limit: Int, status: FollowUpGroupStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.maximum = maximum
            self.expiresAt = expiresAt
            self.limit = limit
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

        func canMoveTo(_ next: FollowUpGroupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == FollowUpGroupStatus.revoked || next == FollowUpGroupStatus.expired
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

        func moveTo(_ next: FollowUpGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("follow up group") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(limit) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpGroup {
            return FollowUpGroup(
                code: code,
                name: name,
                ward: ward,
                maximum: maximum,
                expiresAt: expiresAt,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a follow up group in status requested.
    static func newFollowUpGroup(_ code: String, name: String) -> FollowUpGroup {
        return FollowUpGroup(
            code: code,
            name: name,
            ward: "",
            maximum: 0.0,
            expiresAt: 0,
            limit: 0,
            status: FollowUpGroupStatus.requested
        )
    }
}
