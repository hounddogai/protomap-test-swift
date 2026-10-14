import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global discharge plan budget is in its life cycle.
    enum GlobalDischargePlanBudgetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One global discharge plan budget, with what the planners need to act on it.
    final class GlobalDischargePlanBudget {
        var code: String
        var label: String
        var phone: String
        var reviewer: String
        var quantity: Int
        var ceiling: Double
        var status: GlobalDischargePlanBudgetStatus

        init(code: String, label: String, phone: String, reviewer: String, quantity: Int, ceiling: Double, status: GlobalDischargePlanBudgetStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.reviewer = reviewer
            self.quantity = quantity
            self.ceiling = ceiling
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

        func canMoveTo(_ next: GlobalDischargePlanBudgetStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalDischargePlanBudgetStatus.queued
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == GlobalDischargePlanBudgetStatus.done || next == GlobalDischargePlanBudgetStatus.failed
            case .done:
                return next == GlobalDischargePlanBudgetStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalDischargePlanBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global discharge plan budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedTotal() -> Double {
            return (Double(quantity) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> GlobalDischargePlanBudget {
            return GlobalDischargePlanBudget(
                code: code,
                label: label,
                phone: phone,
                reviewer: reviewer,
                quantity: quantity,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global discharge plan budget in status new.
    static func newGlobalDischargePlanBudget(_ code: String, label: String) -> GlobalDischargePlanBudget {
        return GlobalDischargePlanBudget(
            code: code,
            label: label,
            phone: "",
            reviewer: "",
            quantity: 0,
            ceiling: 0.0,
            status: GlobalDischargePlanBudgetStatus.new
        )
    }
}
