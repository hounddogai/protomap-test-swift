import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier metric must pass. Check returns its problems, or none.
    protocol CourierMetricRule {
        func check(_ item: CourierMetric) -> [String]
    }

    final class CourierMetricCreatedAtRangeRule: CourierMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierMetric) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CourierMetricLabelLengthRule: CourierMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierMetric) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierMetricArchivedGuardRule: CourierMetricRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CourierMetric) -> [String] {
            if item.archived && (item.sequence > limit) {
                return ["sequence \(item.sequence) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a courier metric.
    final class CourierMetricValidator {
        var rules: [any CourierMetricRule]

        init(rules: [any CourierMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierMetric]) -> [String: [String]] {
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

    static func defaultCourierMetricValidator() -> CourierMetricValidator {
        return CourierMetricValidator(
            rules: [
                CourierMetricCreatedAtRangeRule(min: 32, max: 64),
                CourierMetricLabelLengthRule(maxLength: 3600),
                CourierMetricArchivedGuardRule(limit: 1000),
            ]
        )
    }
}
