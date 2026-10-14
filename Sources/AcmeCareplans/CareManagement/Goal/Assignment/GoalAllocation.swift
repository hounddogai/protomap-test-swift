import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal allocation is in its life cycle.
    enum GoalAllocationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One goal allocation, with what the planners need to act on it.
    final class GoalAllocation {
        var code: String
        var label: String
        var amount: Double
        var threshold: Double
        var version: Int
        var procedureCode: String
        var country: String
        var status: GoalAllocationStatus

        init(code: String, label: String, amount: Double, threshold: Double, version: Int, procedureCode: String, country: String, status: GoalAllocationStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.threshold = threshold
            self.version = version
            self.procedureCode = procedureCode
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GoalAllocationStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == GoalAllocationStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedExposure() -> Double {
            return ((Double(version) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> GoalAllocation {
            return GoalAllocation(
                code: code,
                label: label,
                amount: amount,
                threshold: threshold,
                version: version,
                procedureCode: procedureCode,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a goal allocation in status open.
    static func newGoalAllocation(_ code: String, label: String) -> GoalAllocation {
        return GoalAllocation(
            code: code,
            label: label,
            amount: 0.0,
            threshold: 0.0,
            version: 0,
            procedureCode: "",
            country: "",
            status: GoalAllocationStatus.`open`
        )
    }
}
