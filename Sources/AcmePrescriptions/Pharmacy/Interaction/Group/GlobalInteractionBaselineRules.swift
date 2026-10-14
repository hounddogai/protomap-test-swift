import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global interaction baseline must pass. Check returns its problems, or none.
    protocol GlobalInteractionBaselineRule {
        func check(_ item: GlobalInteractionBaseline) -> [String]
    }

    final class GlobalInteractionBaselineCodePrefixRule: GlobalInteractionBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalInteractionBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalInteractionBaselineRequiredTimezoneRule: GlobalInteractionBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalInteractionBaseline) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalInteractionBaselineAllowedCodeRule: GlobalInteractionBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalInteractionBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class GlobalInteractionBaselineTimezoneLengthRule: GlobalInteractionBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalInteractionBaseline) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalInteractionBaselineBudgetRangeRule: GlobalInteractionBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalInteractionBaseline) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a global interaction baseline.
    final class GlobalInteractionBaselineValidator {
        var rules: [any GlobalInteractionBaselineRule]

        init(rules: [any GlobalInteractionBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalInteractionBaseline) -> [String] {
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

        func requireValid(_ item: GlobalInteractionBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalInteractionBaseline]) -> [String: [String]] {
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

    static func defaultGlobalInteractionBaselineValidator() -> GlobalInteractionBaselineValidator {
        return GlobalInteractionBaselineValidator(
            rules: [
                GlobalInteractionBaselineCodePrefixRule(prefix: "X"),
                GlobalInteractionBaselineRequiredTimezoneRule(message: "global interaction baseline needs a value"),
                GlobalInteractionBaselineAllowedCodeRule(allowed: ["regional"]),
                GlobalInteractionBaselineTimezoneLengthRule(maxLength: 32),
                GlobalInteractionBaselineBudgetRangeRule(min: 3.2, max: 594.4),
            ]
        )
    }
}
