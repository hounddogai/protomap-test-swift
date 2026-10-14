import AcmePlatform
import Foundation

extension Consent {
    /// A rule a seasonal proxy group must pass. Check returns its problems, or none.
    protocol SeasonalProxyGroupRule {
        func check(_ item: SeasonalProxyGroup) -> [String]
    }

    final class SeasonalProxyGroupWeightRangeRule: SeasonalProxyGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalProxyGroup) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalProxyGroupCodePrefixRule: SeasonalProxyGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalProxyGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalProxyGroupCodeLengthRule: SeasonalProxyGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalProxyGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalProxyGroupRequiredTitleRule: SeasonalProxyGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalProxyGroup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalProxyGroupRequiredSummaryRule: SeasonalProxyGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalProxyGroup) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal proxy group.
    final class SeasonalProxyGroupValidator {
        var rules: [any SeasonalProxyGroupRule]

        init(rules: [any SeasonalProxyGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalProxyGroup) -> [String] {
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

        func requireValid(_ item: SeasonalProxyGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalProxyGroup]) -> [String: [String]] {
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

    static func defaultSeasonalProxyGroupValidator() -> SeasonalProxyGroupValidator {
        return SeasonalProxyGroupValidator(
            rules: [
                SeasonalProxyGroupWeightRangeRule(min: 4.6, max: 2020.6),
                SeasonalProxyGroupCodePrefixRule(prefix: "OPS"),
                SeasonalProxyGroupCodeLengthRule(maxLength: 80),
                SeasonalProxyGroupRequiredTitleRule(message: "seasonal proxy group needs this field"),
                SeasonalProxyGroupRequiredSummaryRule(message: "seasonal proxy group needs an entry"),
            ]
        )
    }
}
