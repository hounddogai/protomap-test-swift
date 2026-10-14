import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a tiered skill mix metric must pass. Check returns its problems, or none.
    protocol TieredSkillMixMetricRule {
        func check(_ item: TieredSkillMixMetric) -> [String]
    }

    final class TieredSkillMixMetricLabelLengthRule: TieredSkillMixMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredSkillMixMetric) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredSkillMixMetricRequiredLabelRule: TieredSkillMixMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredSkillMixMetric) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredSkillMixMetricAttemptsRangeRule: TieredSkillMixMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredSkillMixMetric) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredSkillMixMetricCodePrefixRule: TieredSkillMixMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredSkillMixMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredSkillMixMetricCodeLengthRule: TieredSkillMixMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredSkillMixMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered skill mix metric.
    final class TieredSkillMixMetricValidator {
        var rules: [any TieredSkillMixMetricRule]

        init(rules: [any TieredSkillMixMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredSkillMixMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredSkillMixMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredSkillMixMetric]) -> [String: [String]] {
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

    static func defaultTieredSkillMixMetricValidator() -> TieredSkillMixMetricValidator {
        return TieredSkillMixMetricValidator(
            rules: [
                TieredSkillMixMetricLabelLengthRule(maxLength: 86400),
                TieredSkillMixMetricRequiredLabelRule(message: "tiered skill mix metric needs this field"),
                TieredSkillMixMetricAttemptsRangeRule(min: 120, max: 86400),
                TieredSkillMixMetricCodePrefixRule(prefix: "ACM"),
                TieredSkillMixMetricCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
