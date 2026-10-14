import AcmePlatform
import Foundation

extension Referrals {
    /// Where a legacy eligibility budget is in its life cycle.
    enum LegacyEligibilityBudgetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A legacy eligibility budget as the eligibility team keeps it.
    final class LegacyEligibilityBudget {
        var code: String
        var label: String
        var encounterID: String
        var endsAt: Int
        var phone: String
        var limit: Int
        var segment: String
        var cost: Double
        var status: LegacyEligibilityBudgetStatus

        init(code: String, label: String, encounterID: String, endsAt: Int, phone: String, limit: Int, segment: String, cost: Double, status: LegacyEligibilityBudgetStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.endsAt = endsAt
            self.phone = phone
            self.limit = limit
            self.segment = segment
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyEligibilityBudgetStatus) -> Bool {
            switch status {
            case .planned:
                return next == LegacyEligibilityBudgetStatus.inProgress
            case .scheduled:
                return next == LegacyEligibilityBudgetStatus.inProgress || next == LegacyEligibilityBudgetStatus.cancelled
            case .inProgress:
                return next == LegacyEligibilityBudgetStatus.completed || next == LegacyEligibilityBudgetStatus.cancelled
            case .completed:
                return next == LegacyEligibilityBudgetStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyEligibilityBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy eligibility budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedLoad() -> Double {
            return (Double(endsAt) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> LegacyEligibilityBudget {
            return LegacyEligibilityBudget(
                code: code,
                label: label,
                encounterID: encounterID,
                endsAt: endsAt,
                phone: phone,
                limit: limit,
                segment: segment,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a legacy eligibility budget in status planned.
    static func newLegacyEligibilityBudget(_ code: String, label: String) -> LegacyEligibilityBudget {
        return LegacyEligibilityBudget(
            code: code,
            label: label,
            encounterID: "",
            endsAt: 0,
            phone: "",
            limit: 0,
            segment: "",
            cost: 0.0,
            status: LegacyEligibilityBudgetStatus.planned
        )
    }
}
