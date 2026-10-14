import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default courier metric must pass. Check returns its problems, or none.
    protocol DefaultCourierMetricRule {
        func check(_ item: DefaultCourierMetric) -> [String]
    }

    final class DefaultCourierMetricRequiredCodeRule: DefaultCourierMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCourierMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCourierMetricPriorityRangeRule: DefaultCourierMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCourierMetric) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultCourierMetricFloorValueRangeRule: DefaultCourierMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCourierMetric) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a default courier metric.
    final class DefaultCourierMetricValidator {
        var rules: [any DefaultCourierMetricRule]

        init(rules: [any DefaultCourierMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCourierMetric) -> [String] {
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

        func requireValid(_ item: DefaultCourierMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCourierMetric]) -> [String: [String]] {
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

    static func defaultDefaultCourierMetricValidator() -> DefaultCourierMetricValidator {
        return DefaultCourierMetricValidator(
            rules: [
                DefaultCourierMetricRequiredCodeRule(message: "default courier metric needs a value"),
                DefaultCourierMetricPriorityRangeRule(min: 80, max: 3600),
                DefaultCourierMetricFloorValueRangeRule(min: 3.6, max: 3480.7),
            ]
        )
    }
}
