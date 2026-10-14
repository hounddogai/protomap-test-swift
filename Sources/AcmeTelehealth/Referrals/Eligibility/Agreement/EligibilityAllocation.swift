import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility allocation is in its life cycle.
    enum EligibilityAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a eligibility allocation and its current status.
    final class EligibilityAllocation {
        var code: String
        var title: String
        var country: String
        var cost: Double
        var margin: Double
        var region: String
        var amount: Double
        var retries: Int
        var status: EligibilityAllocationStatus

        init(code: String, title: String, country: String, cost: Double, margin: Double, region: String, amount: Double, retries: Int, status: EligibilityAllocationStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.cost = cost
            self.margin = margin
            self.region = region
            self.amount = amount
            self.retries = retries
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

        func canMoveTo(_ next: EligibilityAllocationStatus) -> Bool {
            switch status {
            case .planned:
                return next == EligibilityAllocationStatus.scheduled
            case .scheduled:
                return next == EligibilityAllocationStatus.cancelled
            case .inProgress:
                return next == EligibilityAllocationStatus.cancelled
            case .completed:
                return next == EligibilityAllocationStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedExposure() -> Double {
            return (Double(retries) * margin * 100).rounded() / 100
        }

        func copyValue() -> EligibilityAllocation {
            return EligibilityAllocation(
                code: code,
                title: title,
                country: country,
                cost: cost,
                margin: margin,
                region: region,
                amount: amount,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a eligibility allocation in status planned.
    static func newEligibilityAllocation(_ code: String, title: String) -> EligibilityAllocation {
        return EligibilityAllocation(
            code: code,
            title: title,
            country: "",
            cost: 0.0,
            margin: 0.0,
            region: "",
            amount: 0.0,
            retries: 0,
            status: EligibilityAllocationStatus.planned
        )
    }
}
