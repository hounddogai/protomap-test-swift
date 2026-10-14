import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a legacy order set metric must pass. Check returns its problems, or none.
    protocol LegacyOrderSetMetricRule {
        func check(_ item: LegacyOrderSetMetric) -> [String]
    }

    final class LegacyOrderSetMetricRequiredNameRule: LegacyOrderSetMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyOrderSetMetric) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyOrderSetMetricAllowedNameRule: LegacyOrderSetMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyOrderSetMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is not allowed"]
            }
            return []
        }
    }

    final class LegacyOrderSetMetricStartsAtRangeRule: LegacyOrderSetMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyOrderSetMetric) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyOrderSetMetricCodePrefixRule: LegacyOrderSetMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyOrderSetMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyOrderSetMetricCodeLengthRule: LegacyOrderSetMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyOrderSetMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyOrderSetMetricNameLengthRule: LegacyOrderSetMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyOrderSetMetric) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy order set metric.
    final class LegacyOrderSetMetricValidator {
        var rules: [any LegacyOrderSetMetricRule]

        init(rules: [any LegacyOrderSetMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyOrderSetMetric) -> [String] {
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

        func requireValid(_ item: LegacyOrderSetMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyOrderSetMetric]) -> [String: [String]] {
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

    static func defaultLegacyOrderSetMetricValidator() -> LegacyOrderSetMetricValidator {
        return LegacyOrderSetMetricValidator(
            rules: [
                LegacyOrderSetMetricRequiredNameRule(message: "legacy order set metric needs an entry"),
                LegacyOrderSetMetricAllowedNameRule(allowed: ["global", "strict", "adaptive"]),
                LegacyOrderSetMetricStartsAtRangeRule(min: 64, max: 1000),
                LegacyOrderSetMetricCodePrefixRule(prefix: "ACM"),
                LegacyOrderSetMetricCodeLengthRule(maxLength: 16),
                LegacyOrderSetMetricNameLengthRule(maxLength: 64),
            ]
        )
    }
}
