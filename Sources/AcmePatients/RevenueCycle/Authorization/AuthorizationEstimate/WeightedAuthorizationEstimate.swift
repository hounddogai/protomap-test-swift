import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a weighted authorization estimate is in its life cycle.
    enum WeightedAuthorizationEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One weighted authorization estimate, with what the planners need to act on it.
    final class WeightedAuthorizationEstimate {
        var code: String
        var title: String
        var payer: String
        var capacity: Int
        var locale: String
        var budget: Double
        var timezone: String
        var priority: Int
        var reviewer: String
        var margin: Double
        var status: WeightedAuthorizationEstimateStatus

        init(code: String, title: String, payer: String, capacity: Int, locale: String, budget: Double, timezone: String, priority: Int, reviewer: String, margin: Double, status: WeightedAuthorizationEstimateStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.capacity = capacity
            self.locale = locale
            self.budget = budget
            self.timezone = timezone
            self.priority = priority
            self.reviewer = reviewer
            self.margin = margin
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

        func canMoveTo(_ next: WeightedAuthorizationEstimateStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedAuthorizationEstimateStatus.granted || next == WeightedAuthorizationEstimateStatus.expired
            case .granted:
                return next == WeightedAuthorizationEstimateStatus.revoked
            case .revoked:
                return next == WeightedAuthorizationEstimateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedAuthorizationEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted authorization estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("weighted authorization estimate") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(priority) - margin) * 100).rounded() / 100
        }

        func copyValue() -> WeightedAuthorizationEstimate {
            return WeightedAuthorizationEstimate(
                code: code,
                title: title,
                payer: payer,
                capacity: capacity,
                locale: locale,
                budget: budget,
                timezone: timezone,
                priority: priority,
                reviewer: reviewer,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a weighted authorization estimate in status requested.
    static func newWeightedAuthorizationEstimate(_ code: String, title: String) -> WeightedAuthorizationEstimate {
        return WeightedAuthorizationEstimate(
            code: code,
            title: title,
            payer: "",
            capacity: 0,
            locale: "",
            budget: 0.0,
            timezone: "",
            priority: 0,
            reviewer: "",
            margin: 0.0,
            status: WeightedAuthorizationEstimateStatus.requested
        )
    }
}
