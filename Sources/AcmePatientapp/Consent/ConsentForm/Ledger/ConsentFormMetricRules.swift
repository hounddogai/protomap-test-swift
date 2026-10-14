import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form metric must pass. Check returns its problems, or none.
    protocol ConsentFormMetricRule {
        func check(_ item: ConsentFormMetric) -> [String]
    }

    final class ConsentFormMetricRequiredNameRule: ConsentFormMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormMetric) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormMetricRatioRangeRule: ConsentFormMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormMetric) -> [String] {
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

    final class ConsentFormMetricVisibleGuardRule: ConsentFormMetricRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ConsentFormMetric) -> [String] {
            if item.visible && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class ConsentFormMetricSummaryLengthRule: ConsentFormMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormMetric) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a consent form metric.
    final class ConsentFormMetricValidator {
        var rules: [any ConsentFormMetricRule]

        init(rules: [any ConsentFormMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormMetric) -> [String] {
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

        func requireValid(_ item: ConsentFormMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormMetric]) -> [String: [String]] {
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

    static func defaultConsentFormMetricValidator() -> ConsentFormMetricValidator {
        return ConsentFormMetricValidator(
            rules: [
                ConsentFormMetricRequiredNameRule(message: "consent form metric needs a value"),
                ConsentFormMetricRatioRangeRule(min: 2.9, max: 3264.7),
                ConsentFormMetricVisibleGuardRule(limit: 120),
                ConsentFormMetricSummaryLengthRule(maxLength: 64),
            ]
        )
    }
}
