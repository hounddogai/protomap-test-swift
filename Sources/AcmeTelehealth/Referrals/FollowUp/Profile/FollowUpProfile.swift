import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up profile is in its life cycle.
    enum FollowUpProfileStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A follow up profile as the follow up team keeps it.
    final class FollowUpProfile {
        var code: String
        var title: String
        var limit: Int
        var updatedAt: Int
        var copay: Double
        var active: Bool
        var amount: Double
        var country: String
        var version: Int
        var channel: String
        var status: FollowUpProfileStatus

        init(code: String, title: String, limit: Int, updatedAt: Int, copay: Double, active: Bool, amount: Double, country: String, version: Int, channel: String, status: FollowUpProfileStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.updatedAt = updatedAt
            self.copay = copay
            self.active = active
            self.amount = amount
            self.country = country
            self.version = version
            self.channel = channel
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FollowUpProfileStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FollowUpProfileStatus.archived
            case .inReview:
                return next == FollowUpProfileStatus.archived
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == FollowUpProfileStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveTotal() -> Double {
            return (Double(version) * copay * 100).rounded() / 100
        }

        func copyValue() -> FollowUpProfile {
            return FollowUpProfile(
                code: code,
                title: title,
                limit: limit,
                updatedAt: updatedAt,
                copay: copay,
                active: active,
                amount: amount,
                country: country,
                version: version,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a follow up profile in status open.
    static func newFollowUpProfile(_ code: String, title: String) -> FollowUpProfile {
        return FollowUpProfile(
            code: code,
            title: title,
            limit: 0,
            updatedAt: 0,
            copay: 0.0,
            active: false,
            amount: 0.0,
            country: "",
            version: 0,
            channel: "",
            status: FollowUpProfileStatus.`open`
        )
    }
}
