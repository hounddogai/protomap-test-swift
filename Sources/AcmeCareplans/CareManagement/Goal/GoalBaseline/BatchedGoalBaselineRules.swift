import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched goal baseline must pass. Check returns its problems, or none.
    protocol BatchedGoalBaselineRule {
        func check(_ item: BatchedGoalBaseline) -> [String]
    }

    final class BatchedGoalBaselineAllowedTitleRule: BatchedGoalBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedGoalBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is stale"]
            }
            return []
        }
    }

    final class BatchedGoalBaselineCodeLengthRule: BatchedGoalBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedGoalBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedGoalBaselineRatioRangeRule: BatchedGoalBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedGoalBaseline) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched goal baseline.
    final class BatchedGoalBaselineValidator {
        var rules: [any BatchedGoalBaselineRule]

        init(rules: [any BatchedGoalBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedGoalBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedGoalBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedGoalBaseline]) -> [String: [String]] {
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

    static func defaultBatchedGoalBaselineValidator() -> BatchedGoalBaselineValidator {
        return BatchedGoalBaselineValidator(
            rules: [
                BatchedGoalBaselineAllowedTitleRule(allowed: []),
                BatchedGoalBaselineCodeLengthRule(maxLength: 16),
                BatchedGoalBaselineRatioRangeRule(min: 9.4, max: 3634.1),
            ]
        )
    }
}
