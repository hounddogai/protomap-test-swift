import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range metric must pass. Check returns its problems, or none.
    protocol ReferenceRangeMetricRule {
        func check(_ item: ReferenceRangeMetric) -> [String]
    }

    final class ReferenceRangeMetricQuantityRangeRule: ReferenceRangeMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeMetric) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferenceRangeMetricCodeLengthRule: ReferenceRangeMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeMetricRequiredCodeRule: ReferenceRangeMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a reference range metric.
    final class ReferenceRangeMetricValidator {
        var rules: [any ReferenceRangeMetricRule]

        init(rules: [any ReferenceRangeMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeMetric]) -> [String: [String]] {
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

    static func defaultReferenceRangeMetricValidator() -> ReferenceRangeMetricValidator {
        return ReferenceRangeMetricValidator(
            rules: [
                ReferenceRangeMetricQuantityRangeRule(min: 16, max: 255),
                ReferenceRangeMetricCodeLengthRule(maxLength: 86400),
                ReferenceRangeMetricRequiredCodeRule(message: "reference range metric needs this field"),
            ]
        )
    }
}
