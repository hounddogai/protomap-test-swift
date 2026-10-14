import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement preference must pass. Check returns its problems, or none.
    protocol StatementPreferenceRule {
        func check(_ item: StatementPreference) -> [String]
    }

    final class StatementPreferenceAllowedCodeRule: StatementPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StatementPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class StatementPreferenceCodePrefixRule: StatementPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StatementPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StatementPreferenceThresholdRangeRule: StatementPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementPreference) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StatementPreferenceRequiredCodeRule: StatementPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementPreferenceRequiredNameRule: StatementPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementPreference) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a statement preference.
    final class StatementPreferenceValidator {
        var rules: [any StatementPreferenceRule]

        init(rules: [any StatementPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementPreference) -> [String] {
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

        func requireValid(_ item: StatementPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementPreference]) -> [String: [String]] {
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

    static func defaultStatementPreferenceValidator() -> StatementPreferenceValidator {
        return StatementPreferenceValidator(
            rules: [
                StatementPreferenceAllowedCodeRule(allowed: ["fallback", "adaptive"]),
                StatementPreferenceCodePrefixRule(prefix: "OPS"),
                StatementPreferenceThresholdRangeRule(min: 2.1, max: 136.1),
                StatementPreferenceRequiredCodeRule(message: "statement preference needs a value"),
                StatementPreferenceRequiredNameRule(message: "statement preference needs a value"),
            ]
        )
    }
}
