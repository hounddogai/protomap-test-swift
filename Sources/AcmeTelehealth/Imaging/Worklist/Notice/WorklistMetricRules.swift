import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist metric must pass. Check returns its problems, or none.
    protocol WorklistMetricRule {
        func check(_ item: WorklistMetric) -> [String]
    }

    final class WorklistMetricCodeLengthRule: WorklistMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistMetricRequiredNameRule: WorklistMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistMetric) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistMetricDurationMinutesRangeRule: WorklistMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistMetric) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WorklistMetricCopayRangeRule: WorklistMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistMetric) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WorklistMetricUpdatedAtRangeRule: WorklistMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistMetric) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WorklistMetricAllowedNameRule: WorklistMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WorklistMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist metric.
    final class WorklistMetricValidator {
        var rules: [any WorklistMetricRule]

        init(rules: [any WorklistMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistMetric]) -> [String: [String]] {
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

    static func defaultWorklistMetricValidator() -> WorklistMetricValidator {
        return WorklistMetricValidator(
            rules: [
                WorklistMetricCodeLengthRule(maxLength: 32),
                WorklistMetricRequiredNameRule(message: "worklist metric needs an entry"),
                WorklistMetricDurationMinutesRangeRule(min: 1000, max: 1000),
                WorklistMetricCopayRangeRule(min: 6.9, max: 868.9),
                WorklistMetricUpdatedAtRangeRule(min: 16, max: 255),
                WorklistMetricAllowedNameRule(allowed: []),
            ]
        )
    }
}
