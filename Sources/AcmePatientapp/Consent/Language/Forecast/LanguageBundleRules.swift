import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language bundle must pass. Check returns its problems, or none.
    protocol LanguageBundleRule {
        func check(_ item: LanguageBundle) -> [String]
    }

    final class LanguageBundleAttemptsRangeRule: LanguageBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageBundle) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LanguageBundleCodeLengthRule: LanguageBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageBundleCodePrefixRule: LanguageBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LanguageBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a language bundle.
    final class LanguageBundleValidator {
        var rules: [any LanguageBundleRule]

        init(rules: [any LanguageBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageBundle) -> [String] {
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

        func requireValid(_ item: LanguageBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageBundle]) -> [String: [String]] {
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

    static func defaultLanguageBundleValidator() -> LanguageBundleValidator {
        return LanguageBundleValidator(
            rules: [
                LanguageBundleAttemptsRangeRule(min: 120, max: 1000),
                LanguageBundleCodeLengthRule(maxLength: 86400),
                LanguageBundleCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
