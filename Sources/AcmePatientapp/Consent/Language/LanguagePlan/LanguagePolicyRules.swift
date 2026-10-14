import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language policy must pass. Check returns its problems, or none.
    protocol LanguagePolicyRule {
        func check(_ item: LanguagePolicy) -> [String]
    }

    final class LanguagePolicyAttemptsRangeRule: LanguagePolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguagePolicy) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LanguagePolicyCodeLengthRule: LanguagePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguagePolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguagePolicyTitleLengthRule: LanguagePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguagePolicy) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a language policy.
    final class LanguagePolicyValidator {
        var rules: [any LanguagePolicyRule]

        init(rules: [any LanguagePolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguagePolicy) -> [String] {
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

        func requireValid(_ item: LanguagePolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguagePolicy]) -> [String: [String]] {
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

    static func defaultLanguagePolicyValidator() -> LanguagePolicyValidator {
        return LanguagePolicyValidator(
            rules: [
                LanguagePolicyAttemptsRangeRule(min: 255, max: 1000),
                LanguagePolicyCodeLengthRule(maxLength: 120),
                LanguagePolicyTitleLengthRule(maxLength: 16),
            ]
        )
    }
}
