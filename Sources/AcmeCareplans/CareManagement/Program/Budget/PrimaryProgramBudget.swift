import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a primary program budget is in its life cycle.
    enum PrimaryProgramBudgetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A primary program budget as the program team keeps it.
    final class PrimaryProgramBudget {
        var code: String
        var label: String
        var payer: String
        var ceiling: Double
        var windowDays: Int
        var status: PrimaryProgramBudgetStatus

        init(code: String, label: String, payer: String, ceiling: Double, windowDays: Int, status: PrimaryProgramBudgetStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.ceiling = ceiling
            self.windowDays = windowDays
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

        func canMoveTo(_ next: PrimaryProgramBudgetStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PrimaryProgramBudgetStatus.archived
            case .inReview:
                return next == PrimaryProgramBudgetStatus.archived
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: PrimaryProgramBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary program budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("primary program budget") \(code)"
        }

        func projectedLoad() -> Double {
            return ((ceiling - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryProgramBudget {
            return PrimaryProgramBudget(
                code: code,
                label: label,
                payer: payer,
                ceiling: ceiling,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary program budget in status open.
    static func newPrimaryProgramBudget(_ code: String, label: String) -> PrimaryProgramBudget {
        return PrimaryProgramBudget(
            code: code,
            label: label,
            payer: "",
            ceiling: 0.0,
            windowDays: 0,
            status: PrimaryProgramBudgetStatus.`open`
        )
    }
}
