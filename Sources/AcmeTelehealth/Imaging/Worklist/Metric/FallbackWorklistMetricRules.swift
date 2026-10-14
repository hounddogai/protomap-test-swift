import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback worklist metric must pass. Check returns its problems, or none.
    protocol FallbackWorklistMetricRule {
        func check(_ item: FallbackWorklistMetric) -> [String]
    }

    final class FallbackWorklistMetricRequiredSourceRule: FallbackWorklistMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackWorklistMetric) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackWorklistMetricRequiredCodeRule: FallbackWorklistMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackWorklistMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackWorklistMetricRequiredLabelRule: FallbackWorklistMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackWorklistMetric) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackWorklistMetricRevisionRangeRule: FallbackWorklistMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackWorklistMetric) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback worklist metric.
    final class FallbackWorklistMetricValidator {
        var rules: [any FallbackWorklistMetricRule]

        init(rules: [any FallbackWorklistMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackWorklistMetric) -> [String] {
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

        func requireValid(_ item: FallbackWorklistMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackWorklistMetric]) -> [String: [String]] {
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

    static func defaultFallbackWorklistMetricValidator() -> FallbackWorklistMetricValidator {
        return FallbackWorklistMetricValidator(
            rules: [
                FallbackWorklistMetricRequiredSourceRule(message: "fallback worklist metric needs a value"),
                FallbackWorklistMetricRequiredCodeRule(message: "fallback worklist metric needs this field"),
                FallbackWorklistMetricRequiredLabelRule(message: "fallback worklist metric needs an entry"),
                FallbackWorklistMetricRevisionRangeRule(min: 64, max: 80),
            ]
        )
    }
}
