import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge metric must pass. Check returns its problems, or none.
    protocol ChargeMetricRule {
        func check(_ item: ChargeMetric) -> [String]
    }

    final class ChargeMetricCodePrefixRule: ChargeMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ChargeMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ChargeMetricRequiredDescriptionRule: ChargeMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeMetric) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeMetricAllowedTitleRule: ChargeMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ChargeMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is out of range"]
            }
            return []
        }
    }

    final class ChargeMetricTitleLengthRule: ChargeMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeMetric) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeMetricUpdatedAtRangeRule: ChargeMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeMetric) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a charge metric.
    final class ChargeMetricValidator {
        var rules: [any ChargeMetricRule]

        init(rules: [any ChargeMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeMetric) -> [String] {
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

        func requireValid(_ item: ChargeMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeMetric]) -> [String: [String]] {
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

    static func defaultChargeMetricValidator() -> ChargeMetricValidator {
        return ChargeMetricValidator(
            rules: [
                ChargeMetricCodePrefixRule(prefix: "X"),
                ChargeMetricRequiredDescriptionRule(message: "charge metric needs this field"),
                ChargeMetricAllowedTitleRule(allowed: ["lenient", "manual", "regional"]),
                ChargeMetricTitleLengthRule(maxLength: 32),
                ChargeMetricUpdatedAtRangeRule(min: 1000, max: 86400),
            ]
        )
    }
}
