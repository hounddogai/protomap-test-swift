import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial metric must pass. Check returns its problems, or none.
    protocol DenialMetricRule {
        func check(_ item: DenialMetric) -> [String]
    }

    final class DenialMetricRequiredNameRule: DenialMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialMetric) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialMetricCodePrefixRule: DenialMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DenialMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DenialMetricActiveGuardRule: DenialMetricRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DenialMetric) -> [String] {
            if item.active && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class DenialMetricThresholdRangeRule: DenialMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialMetric) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DenialMetricNameLengthRule: DenialMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialMetric) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a denial metric.
    final class DenialMetricValidator {
        var rules: [any DenialMetricRule]

        init(rules: [any DenialMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DenialMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialMetric]) -> [String: [String]] {
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

    static func defaultDenialMetricValidator() -> DenialMetricValidator {
        return DenialMetricValidator(
            rules: [
                DenialMetricRequiredNameRule(message: "denial metric needs an entry"),
                DenialMetricCodePrefixRule(prefix: "ACM"),
                DenialMetricActiveGuardRule(limit: 3600),
                DenialMetricThresholdRangeRule(min: 3.7, max: 4990.7),
                DenialMetricNameLengthRule(maxLength: 80),
            ]
        )
    }
}
