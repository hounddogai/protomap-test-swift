import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted referral variance is in its life cycle.
    enum WeightedReferralVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A weighted referral variance as the referral team keeps it.
    final class WeightedReferralVariance {
        var code: String
        var name: String
        var durationMinutes: Int
        var copay: Double
        var minimum: Double
        var status: WeightedReferralVarianceStatus

        init(code: String, name: String, durationMinutes: Int, copay: Double, minimum: Double, status: WeightedReferralVarianceStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.copay = copay
            self.minimum = minimum
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

        func canMoveTo(_ next: WeightedReferralVarianceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WeightedReferralVarianceStatus.approved || next == WeightedReferralVarianceStatus.withdrawn
            case .approved:
                return next == WeightedReferralVarianceStatus.withdrawn
            case .rejected:
                return next == WeightedReferralVarianceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedReferralVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted referral variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("weighted referral variance") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(durationMinutes) - copay) * 100).rounded() / 100
        }

        func copyValue() -> WeightedReferralVariance {
            return WeightedReferralVariance(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                copay: copay,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted referral variance in status proposed.
    static func newWeightedReferralVariance(_ code: String, name: String) -> WeightedReferralVariance {
        return WeightedReferralVariance(
            code: code,
            name: name,
            durationMinutes: 0,
            copay: 0.0,
            minimum: 0.0,
            status: WeightedReferralVarianceStatus.proposed
        )
    }
}
