import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rolling task budget must pass. Check returns its problems, or none.
    protocol RollingTaskBudgetRule {
        func check(_ item: RollingTaskBudget) -> [String]
    }

    final class RollingTaskBudgetCreatedAtRangeRule: RollingTaskBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingTaskBudget) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingTaskBudgetRequiredLabelRule: RollingTaskBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingTaskBudget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingTaskBudgetRequiredNameRule: RollingTaskBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingTaskBudget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingTaskBudgetCountryLengthRule: RollingTaskBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingTaskBudget) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingTaskBudgetCostRangeRule: RollingTaskBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingTaskBudget) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingTaskBudgetAllowedCodeRule: RollingTaskBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingTaskBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling task budget.
    final class RollingTaskBudgetValidator {
        var rules: [any RollingTaskBudgetRule]

        init(rules: [any RollingTaskBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingTaskBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingTaskBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingTaskBudget]) -> [String: [String]] {
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

    static func defaultRollingTaskBudgetValidator() -> RollingTaskBudgetValidator {
        return RollingTaskBudgetValidator(
            rules: [
                RollingTaskBudgetCreatedAtRangeRule(min: 64, max: 80),
                RollingTaskBudgetRequiredLabelRule(message: "rolling task budget needs a value"),
                RollingTaskBudgetRequiredNameRule(message: "rolling task budget needs a value"),
                RollingTaskBudgetCountryLengthRule(maxLength: 86400),
                RollingTaskBudgetCostRangeRule(min: 0.8, max: 2126.6),
                RollingTaskBudgetAllowedCodeRule(allowed: ["pending"]),
            ]
        )
    }
}
