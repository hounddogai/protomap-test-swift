import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment budget is in its life cycle.
    enum AssessmentBudgetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A assessment budget as the assessment team keeps it.
    final class AssessmentBudget {
        var code: String
        var label: String
        var locale: String
        var budget: Double
        var allergy: String
        var status: AssessmentBudgetStatus

        init(code: String, label: String, locale: String, budget: Double, allergy: String, status: AssessmentBudgetStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.budget = budget
            self.allergy = allergy
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AssessmentBudgetStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AssessmentBudgetStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("assessment budget") \(code)"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> AssessmentBudget {
            return AssessmentBudget(
                code: code,
                label: label,
                locale: locale,
                budget: budget,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a assessment budget in status created.
    static func newAssessmentBudget(_ code: String, label: String) -> AssessmentBudget {
        return AssessmentBudget(
            code: code,
            label: label,
            locale: "",
            budget: 0.0,
            allergy: "",
            status: AssessmentBudgetStatus.created
        )
    }
}
