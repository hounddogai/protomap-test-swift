import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered follow up metric must pass. Check returns its problems, or none.
    protocol TieredFollowUpMetricRule {
        func check(_ item: TieredFollowUpMetric) -> [String]
    }

    final class TieredFollowUpMetricUnitLengthRule: TieredFollowUpMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredFollowUpMetric) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredFollowUpMetricCeilingRangeRule: TieredFollowUpMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredFollowUpMetric) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredFollowUpMetricAllowedLabelRule: TieredFollowUpMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredFollowUpMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is expired"]
            }
            return []
        }
    }

    final class TieredFollowUpMetricRequiredCodeRule: TieredFollowUpMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredFollowUpMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered follow up metric.
    final class TieredFollowUpMetricValidator {
        var rules: [any TieredFollowUpMetricRule]

        init(rules: [any TieredFollowUpMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredFollowUpMetric) -> [String] {
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

        func requireValid(_ item: TieredFollowUpMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredFollowUpMetric]) -> [String: [String]] {
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

    static func defaultTieredFollowUpMetricValidator() -> TieredFollowUpMetricValidator {
        return TieredFollowUpMetricValidator(
            rules: [
                TieredFollowUpMetricUnitLengthRule(maxLength: 64),
                TieredFollowUpMetricCeilingRangeRule(min: 8.1, max: 2245.7),
                TieredFollowUpMetricAllowedLabelRule(allowed: ["strict"]),
                TieredFollowUpMetricRequiredCodeRule(message: "tiered follow up metric needs an entry"),
            ]
        )
    }
}
