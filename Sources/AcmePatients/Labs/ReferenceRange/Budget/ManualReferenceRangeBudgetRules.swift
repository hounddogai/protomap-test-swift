import AcmePlatform
import Foundation

extension Labs {
    /// A rule a manual reference range budget must pass. Check returns its problems, or none.
    protocol ManualReferenceRangeBudgetRule {
        func check(_ item: ManualReferenceRangeBudget) -> [String]
    }

    final class ManualReferenceRangeBudgetDurationMinutesRangeRule: ManualReferenceRangeBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualReferenceRangeBudget) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualReferenceRangeBudgetRequiredPatientRefRule: ManualReferenceRangeBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualReferenceRangeBudget) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualReferenceRangeBudgetVersionRangeRule: ManualReferenceRangeBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualReferenceRangeBudget) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a manual reference range budget.
    final class ManualReferenceRangeBudgetValidator {
        var rules: [any ManualReferenceRangeBudgetRule]

        init(rules: [any ManualReferenceRangeBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualReferenceRangeBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: ManualReferenceRangeBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualReferenceRangeBudget]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultManualReferenceRangeBudgetValidator() -> ManualReferenceRangeBudgetValidator {
        return ManualReferenceRangeBudgetValidator(
            rules: [
                ManualReferenceRangeBudgetDurationMinutesRangeRule(min: 120, max: 255),
                ManualReferenceRangeBudgetRequiredPatientRefRule(
                    message: "manual reference range budget needs a value"
                ),
                ManualReferenceRangeBudgetVersionRangeRule(min: 32, max: 86400),
            ]
        )
    }
}
