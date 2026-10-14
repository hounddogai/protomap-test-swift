import AcmePlatform
import Foundation

extension Referrals {
    /// Where a rolling eligibility variance is in its life cycle.
    enum RollingEligibilityVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A rolling eligibility variance as the eligibility team keeps it.
    final class RollingEligibilityVariance {
        var code: String
        var title: String
        var endsAt: Int
        var ratio: Double
        var quantity: Int
        var weight: Double
        var status: RollingEligibilityVarianceStatus

        init(code: String, title: String, endsAt: Int, ratio: Double, quantity: Int, weight: Double, status: RollingEligibilityVarianceStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.ratio = ratio
            self.quantity = quantity
            self.weight = weight
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingEligibilityVarianceStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingEligibilityVarianceStatus.running || next == RollingEligibilityVarianceStatus.done
            case .queued:
                return next == RollingEligibilityVarianceStatus.running || next == RollingEligibilityVarianceStatus.done
            case .running:
                return next == RollingEligibilityVarianceStatus.done || next == RollingEligibilityVarianceStatus.failed
            case .done:
                return next == RollingEligibilityVarianceStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingEligibilityVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling eligibility variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedLoad() -> Double {
            return ((weight + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RollingEligibilityVariance {
            return RollingEligibilityVariance(
                code: code,
                title: title,
                endsAt: endsAt,
                ratio: ratio,
                quantity: quantity,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling eligibility variance in status new.
    static func newRollingEligibilityVariance(_ code: String, title: String) -> RollingEligibilityVariance {
        return RollingEligibilityVariance(
            code: code,
            title: title,
            endsAt: 0,
            ratio: 0.0,
            quantity: 0,
            weight: 0.0,
            status: RollingEligibilityVarianceStatus.new
        )
    }
}
