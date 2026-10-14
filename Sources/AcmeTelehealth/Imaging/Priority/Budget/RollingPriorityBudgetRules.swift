import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling priority budget must pass. Check returns its problems, or none.
    protocol RollingPriorityBudgetRule {
        func check(_ item: RollingPriorityBudget) -> [String]
    }

    final class RollingPriorityBudgetRequiredDiagnosisCodeRule: RollingPriorityBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingPriorityBudget) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingPriorityBudgetVisibleGuardRule: RollingPriorityBudgetRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RollingPriorityBudget) -> [String] {
            if item.visible && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class RollingPriorityBudgetScoreRangeRule: RollingPriorityBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingPriorityBudget) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingPriorityBudgetDiagnosisCodeLengthRule: RollingPriorityBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingPriorityBudget) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling priority budget.
    final class RollingPriorityBudgetValidator {
        var rules: [any RollingPriorityBudgetRule]

        init(rules: [any RollingPriorityBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingPriorityBudget) -> [String] {
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

        func requireValid(_ item: RollingPriorityBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingPriorityBudget]) -> [String: [String]] {
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

    static func defaultRollingPriorityBudgetValidator() -> RollingPriorityBudgetValidator {
        return RollingPriorityBudgetValidator(
            rules: [
                RollingPriorityBudgetRequiredDiagnosisCodeRule(message: "rolling priority budget needs a value"),
                RollingPriorityBudgetVisibleGuardRule(limit: 2.8),
                RollingPriorityBudgetScoreRangeRule(min: 7.7, max: 821.2),
                RollingPriorityBudgetDiagnosisCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
