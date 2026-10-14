import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a batched census budget must pass. Check returns its problems, or none.
    protocol BatchedCensusBudgetRule {
        func check(_ item: BatchedCensusBudget) -> [String]
    }

    final class BatchedCensusBudgetAllowedCodeRule: BatchedCensusBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedCensusBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class BatchedCensusBudgetRequiredTimezoneRule: BatchedCensusBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedCensusBudget) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedCensusBudgetUpdatedAtRangeRule: BatchedCensusBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCensusBudget) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched census budget.
    final class BatchedCensusBudgetValidator {
        var rules: [any BatchedCensusBudgetRule]

        init(rules: [any BatchedCensusBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedCensusBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedCensusBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedCensusBudget]) -> [String: [String]] {
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

    static func defaultBatchedCensusBudgetValidator() -> BatchedCensusBudgetValidator {
        return BatchedCensusBudgetValidator(
            rules: [
                BatchedCensusBudgetAllowedCodeRule(allowed: ["lenient", "adaptive"]),
                BatchedCensusBudgetRequiredTimezoneRule(message: "batched census budget needs an entry"),
                BatchedCensusBudgetUpdatedAtRangeRule(min: 32, max: 255),
            ]
        )
    }
}
