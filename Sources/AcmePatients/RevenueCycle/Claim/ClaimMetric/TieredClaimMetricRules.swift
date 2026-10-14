import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered claim metric must pass. Check returns its problems, or none.
    protocol TieredClaimMetricRule {
        func check(_ item: TieredClaimMetric) -> [String]
    }

    final class TieredClaimMetricRequiredTitleRule: TieredClaimMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClaimMetric) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredClaimMetricPriorityRangeRule: TieredClaimMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredClaimMetric) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredClaimMetricCodePrefixRule: TieredClaimMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredClaimMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredClaimMetricRequiredCodeRule: TieredClaimMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClaimMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredClaimMetricRegionLengthRule: TieredClaimMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredClaimMetric) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredClaimMetricCreatedAtRangeRule: TieredClaimMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredClaimMetric) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered claim metric.
    final class TieredClaimMetricValidator {
        var rules: [any TieredClaimMetricRule]

        init(rules: [any TieredClaimMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredClaimMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredClaimMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredClaimMetric]) -> [String: [String]] {
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

    static func defaultTieredClaimMetricValidator() -> TieredClaimMetricValidator {
        return TieredClaimMetricValidator(
            rules: [
                TieredClaimMetricRequiredTitleRule(message: "tiered claim metric needs a value"),
                TieredClaimMetricPriorityRangeRule(min: 80, max: 80),
                TieredClaimMetricCodePrefixRule(prefix: "X"),
                TieredClaimMetricRequiredCodeRule(message: "tiered claim metric needs this field"),
                TieredClaimMetricRegionLengthRule(maxLength: 86400),
                TieredClaimMetricCreatedAtRangeRule(min: 80, max: 120),
            ]
        )
    }
}
