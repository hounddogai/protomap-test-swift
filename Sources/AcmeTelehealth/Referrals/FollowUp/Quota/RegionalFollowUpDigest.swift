import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional follow up digest is in its life cycle.
    enum RegionalFollowUpDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One regional follow up digest, with what the planners need to act on it.
    final class RegionalFollowUpDigest {
        var code: String
        var title: String
        var durationMinutes: Int
        var name: String
        var rate: Double
        var expiresAt: Int
        var status: RegionalFollowUpDigestStatus

        init(code: String, title: String, durationMinutes: Int, name: String, rate: Double, expiresAt: Int, status: RegionalFollowUpDigestStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.name = name
            self.rate = rate
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalFollowUpDigestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RegionalFollowUpDigestStatus.withdrawn
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RegionalFollowUpDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional follow up digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedLoad() -> Double {
            return (rate * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> RegionalFollowUpDigest {
            return RegionalFollowUpDigest(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                name: name,
                rate: rate,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional follow up digest in status proposed.
    static func newRegionalFollowUpDigest(_ code: String, title: String) -> RegionalFollowUpDigest {
        return RegionalFollowUpDigest(
            code: code,
            title: title,
            durationMinutes: 0,
            name: "",
            rate: 0.0,
            expiresAt: 0,
            status: RegionalFollowUpDigestStatus.proposed
        )
    }
}
