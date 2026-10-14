import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled float pool budget is in its life cycle.
    enum ScheduledFloatPoolBudgetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A scheduled float pool budget as the float pool team keeps it.
    final class ScheduledFloatPoolBudget {
        var code: String
        var title: String
        var region: String
        var category: String
        var windowDays: Int
        var score: Double
        var country: String
        var facility: String
        var status: ScheduledFloatPoolBudgetStatus

        init(code: String, title: String, region: String, category: String, windowDays: Int, score: Double, country: String, facility: String, status: ScheduledFloatPoolBudgetStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.category = category
            self.windowDays = windowDays
            self.score = score
            self.country = country
            self.facility = facility
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

        func canMoveTo(_ next: ScheduledFloatPoolBudgetStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ScheduledFloatPoolBudgetStatus.rejected || next == ScheduledFloatPoolBudgetStatus.withdrawn
            case .approved:
                return next == ScheduledFloatPoolBudgetStatus.rejected || next == ScheduledFloatPoolBudgetStatus.withdrawn
            case .rejected:
                return next == ScheduledFloatPoolBudgetStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledFloatPoolBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled float pool budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedLoad() -> Double {
            return ((score + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledFloatPoolBudget {
            return ScheduledFloatPoolBudget(
                code: code,
                title: title,
                region: region,
                category: category,
                windowDays: windowDays,
                score: score,
                country: country,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a scheduled float pool budget in status proposed.
    static func newScheduledFloatPoolBudget(_ code: String, title: String) -> ScheduledFloatPoolBudget {
        return ScheduledFloatPoolBudget(
            code: code,
            title: title,
            region: "",
            category: "",
            windowDays: 0,
            score: 0.0,
            country: "",
            facility: "",
            status: ScheduledFloatPoolBudgetStatus.proposed
        )
    }
}
