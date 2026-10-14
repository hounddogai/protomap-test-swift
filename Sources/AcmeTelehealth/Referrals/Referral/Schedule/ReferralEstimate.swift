import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral estimate is in its life cycle.
    enum ReferralEstimateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One referral estimate, with what the planners need to act on it.
    final class ReferralEstimate {
        var code: String
        var name: String
        var discount: Double
        var priority: Int
        var endsAt: Int
        var status: ReferralEstimateStatus

        init(code: String, name: String, discount: Double, priority: Int, endsAt: Int, status: ReferralEstimateStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.priority = priority
            self.endsAt = endsAt
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

        func canMoveTo(_ next: ReferralEstimateStatus) -> Bool {
            switch status {
            case .draft:
                return next == ReferralEstimateStatus.suspended
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ReferralEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedExposure() -> Double {
            return ((discount + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ReferralEstimate {
            return ReferralEstimate(
                code: code,
                name: name,
                discount: discount,
                priority: priority,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a referral estimate in status draft.
    static func newReferralEstimate(_ code: String, name: String) -> ReferralEstimate {
        return ReferralEstimate(
            code: code,
            name: name,
            discount: 0.0,
            priority: 0,
            endsAt: 0,
            status: ReferralEstimateStatus.draft
        )
    }
}
