import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist exception must pass. Check returns its problems, or none.
    protocol WorklistExceptionRule {
        func check(_ item: WorklistException) -> [String]
    }

    final class WorklistExceptionVisibleGuardRule: WorklistExceptionRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: WorklistException) -> [String] {
            if item.visible && (item.attempts > limit) {
                return ["attempts \(item.attempts) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class WorklistExceptionLimitRangeRule: WorklistExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistException) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WorklistExceptionRateRangeRule: WorklistExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistException) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a worklist exception.
    final class WorklistExceptionValidator {
        var rules: [any WorklistExceptionRule]

        init(rules: [any WorklistExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistException]) -> [String: [String]] {
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

    static func defaultWorklistExceptionValidator() -> WorklistExceptionValidator {
        return WorklistExceptionValidator(
            rules: [
                WorklistExceptionVisibleGuardRule(limit: 1000),
                WorklistExceptionLimitRangeRule(min: 1000, max: 3600),
                WorklistExceptionRateRangeRule(min: 4.6, max: 4556.3),
            ]
        )
    }
}
