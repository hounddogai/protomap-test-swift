import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal closure metric must pass. Check returns its problems, or none.
    protocol SeasonalClosureMetricRule {
        func check(_ item: SeasonalClosureMetric) -> [String]
    }

    final class SeasonalClosureMetricRequiredChannelRule: SeasonalClosureMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalClosureMetric) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalClosureMetricNameLengthRule: SeasonalClosureMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalClosureMetric) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalClosureMetricCodePrefixRule: SeasonalClosureMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalClosureMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalClosureMetricChannelLengthRule: SeasonalClosureMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalClosureMetric) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal closure metric.
    final class SeasonalClosureMetricValidator {
        var rules: [any SeasonalClosureMetricRule]

        init(rules: [any SeasonalClosureMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalClosureMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalClosureMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalClosureMetric]) -> [String: [String]] {
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

    static func defaultSeasonalClosureMetricValidator() -> SeasonalClosureMetricValidator {
        return SeasonalClosureMetricValidator(
            rules: [
                SeasonalClosureMetricRequiredChannelRule(message: "seasonal closure metric needs a value"),
                SeasonalClosureMetricNameLengthRule(maxLength: 255),
                SeasonalClosureMetricCodePrefixRule(prefix: "ACM"),
                SeasonalClosureMetricChannelLengthRule(maxLength: 80),
            ]
        )
    }
}
