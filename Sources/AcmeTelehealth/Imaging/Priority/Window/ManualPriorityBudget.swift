import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual priority budget is in its life cycle.
    enum ManualPriorityBudgetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A manual priority budget as the priority team keeps it.
    final class ManualPriorityBudget {
        var code: String
        var title: String
        var visitMinutes: Int
        var amount: Double
        var revision: Int
        var region: String
        var reviewer: String
        var discount: Double
        var refills: Int
        var name: String
        var label: String
        var status: ManualPriorityBudgetStatus

        init(code: String, title: String, visitMinutes: Int, amount: Double, revision: Int, region: String, reviewer: String, discount: Double, refills: Int, name: String, label: String, status: ManualPriorityBudgetStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.amount = amount
            self.revision = revision
            self.region = region
            self.reviewer = reviewer
            self.discount = discount
            self.refills = refills
            self.name = name
            self.label = label
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

        func canMoveTo(_ next: ManualPriorityBudgetStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ManualPriorityBudgetStatus.completed || next == ManualPriorityBudgetStatus.cancelled
            case .completed:
                return next == ManualPriorityBudgetStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualPriorityBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual priority budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func netExposure() -> Double {
            return ((amount - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> ManualPriorityBudget {
            return ManualPriorityBudget(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                amount: amount,
                revision: revision,
                region: region,
                reviewer: reviewer,
                discount: discount,
                refills: refills,
                name: name,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a manual priority budget in status planned.
    static func newManualPriorityBudget(_ code: String, title: String) -> ManualPriorityBudget {
        return ManualPriorityBudget(
            code: code,
            title: title,
            visitMinutes: 0,
            amount: 0.0,
            revision: 0,
            region: "",
            reviewer: "",
            discount: 0.0,
            refills: 0,
            name: "",
            label: "",
            status: ManualPriorityBudgetStatus.planned
        )
    }
}
