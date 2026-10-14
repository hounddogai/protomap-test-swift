import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback handoff metric must pass. Check returns its problems, or none.
    protocol FallbackHandoffMetricRule {
        func check(_ item: FallbackHandoffMetric) -> [String]
    }

    final class FallbackHandoffMetricRefillsRangeRule: FallbackHandoffMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackHandoffMetric) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackHandoffMetricRequiredPhoneRule: FallbackHandoffMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackHandoffMetric) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackHandoffMetricDosageMgRangeRule: FallbackHandoffMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackHandoffMetric) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback handoff metric.
    final class FallbackHandoffMetricValidator {
        var rules: [any FallbackHandoffMetricRule]

        init(rules: [any FallbackHandoffMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackHandoffMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackHandoffMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackHandoffMetric]) -> [String: [String]] {
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

    static func defaultFallbackHandoffMetricValidator() -> FallbackHandoffMetricValidator {
        return FallbackHandoffMetricValidator(
            rules: [
                FallbackHandoffMetricRefillsRangeRule(min: 64, max: 255),
                FallbackHandoffMetricRequiredPhoneRule(message: "fallback handoff metric needs this field"),
                FallbackHandoffMetricDosageMgRangeRule(min: 2.4, max: 3685.5),
            ]
        )
    }
}
