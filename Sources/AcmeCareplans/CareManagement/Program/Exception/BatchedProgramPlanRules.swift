import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched program plan must pass. Check returns its problems, or none.
    protocol BatchedProgramPlanRule {
        func check(_ item: BatchedProgramPlan) -> [String]
    }

    final class BatchedProgramPlanCodeLengthRule: BatchedProgramPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedProgramPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedProgramPlanRefillsRangeRule: BatchedProgramPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedProgramPlan) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedProgramPlanArchivedGuardRule: BatchedProgramPlanRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: BatchedProgramPlan) -> [String] {
            if item.archived && (item.weight > limit) {
                return ["weight \(item.weight) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class BatchedProgramPlanRetriesRangeRule: BatchedProgramPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedProgramPlan) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched program plan.
    final class BatchedProgramPlanValidator {
        var rules: [any BatchedProgramPlanRule]

        init(rules: [any BatchedProgramPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedProgramPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedProgramPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedProgramPlan]) -> [String: [String]] {
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

    static func defaultBatchedProgramPlanValidator() -> BatchedProgramPlanValidator {
        return BatchedProgramPlanValidator(
            rules: [
                BatchedProgramPlanCodeLengthRule(maxLength: 1000),
                BatchedProgramPlanRefillsRangeRule(min: 16, max: 3600),
                BatchedProgramPlanArchivedGuardRule(limit: 8.4),
                BatchedProgramPlanRetriesRangeRule(min: 32, max: 86400),
            ]
        )
    }
}
