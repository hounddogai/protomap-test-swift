import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a batched task plan must pass. Check returns its problems, or none.
    protocol BatchedTaskPlanRule {
        func check(_ item: BatchedTaskPlan) -> [String]
    }

    final class BatchedTaskPlanRequiredCodeRule: BatchedTaskPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedTaskPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedTaskPlanWeightRangeRule: BatchedTaskPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedTaskPlan) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedTaskPlanRequiredLabelRule: BatchedTaskPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedTaskPlan) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedTaskPlanAllowedCodeRule: BatchedTaskPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedTaskPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class BatchedTaskPlanLabelLengthRule: BatchedTaskPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedTaskPlan) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched task plan.
    final class BatchedTaskPlanValidator {
        var rules: [any BatchedTaskPlanRule]

        init(rules: [any BatchedTaskPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedTaskPlan) -> [String] {
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

        func requireValid(_ item: BatchedTaskPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedTaskPlan]) -> [String: [String]] {
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

    static func defaultBatchedTaskPlanValidator() -> BatchedTaskPlanValidator {
        return BatchedTaskPlanValidator(
            rules: [
                BatchedTaskPlanRequiredCodeRule(message: "batched task plan needs this field"),
                BatchedTaskPlanWeightRangeRule(min: 7.2, max: 2828.6),
                BatchedTaskPlanRequiredLabelRule(message: "batched task plan needs a value"),
                BatchedTaskPlanAllowedCodeRule(allowed: ["primary", "batched"]),
                BatchedTaskPlanLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
