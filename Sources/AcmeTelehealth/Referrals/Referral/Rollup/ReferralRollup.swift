import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral rollup is in its life cycle.
    enum ReferralRollupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One referral rollup, with what the planners need to act on it.
    final class ReferralRollup {
        var code: String
        var label: String
        var copay: Double
        var locale: String
        var updatedAt: Int
        var cost: Double
        var archived: Bool
        var budget: Double
        var rate: Double
        var phone: String
        var status: ReferralRollupStatus

        init(code: String, label: String, copay: Double, locale: String, updatedAt: Int, cost: Double, archived: Bool, budget: Double, rate: Double, phone: String, status: ReferralRollupStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.locale = locale
            self.updatedAt = updatedAt
            self.cost = cost
            self.archived = archived
            self.budget = budget
            self.rate = rate
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferralRollupStatus) -> Bool {
            switch status {
            case .idle:
                return next == ReferralRollupStatus.warming
            case .warming:
                return next == ReferralRollupStatus.stopped
            case .ready:
                return next == ReferralRollupStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ReferralRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netValue() -> Double {
            return (cost * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> ReferralRollup {
            return ReferralRollup(
                code: code,
                label: label,
                copay: copay,
                locale: locale,
                updatedAt: updatedAt,
                cost: cost,
                archived: archived,
                budget: budget,
                rate: rate,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a referral rollup in status idle.
    static func newReferralRollup(_ code: String, label: String) -> ReferralRollup {
        return ReferralRollup(
            code: code,
            label: label,
            copay: 0.0,
            locale: "",
            updatedAt: 0,
            cost: 0.0,
            archived: false,
            budget: 0.0,
            rate: 0.0,
            phone: "",
            status: ReferralRollupStatus.idle
        )
    }
}
