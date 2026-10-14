import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral target is in its life cycle.
    enum ReferralTargetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One referral target, with what the planners need to act on it.
    final class ReferralTarget {
        var code: String
        var name: String
        var maximum: Double
        var minimum: Double
        var expiresAt: Int
        var status: ReferralTargetStatus

        init(code: String, name: String, maximum: Double, minimum: Double, expiresAt: Int, status: ReferralTargetStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.minimum = minimum
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferralTargetStatus) -> Bool {
            switch status {
            case .draft:
                return next == ReferralTargetStatus.active
            case .pending:
                return next == ReferralTargetStatus.suspended
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ReferralTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netExposure() -> Double {
            return ((Double(expiresAt) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> ReferralTarget {
            return ReferralTarget(
                code: code,
                name: name,
                maximum: maximum,
                minimum: minimum,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a referral target in status draft.
    static func newReferralTarget(_ code: String, name: String) -> ReferralTarget {
        return ReferralTarget(
            code: code,
            name: name,
            maximum: 0.0,
            minimum: 0.0,
            expiresAt: 0,
            status: ReferralTargetStatus.draft
        )
    }
}
