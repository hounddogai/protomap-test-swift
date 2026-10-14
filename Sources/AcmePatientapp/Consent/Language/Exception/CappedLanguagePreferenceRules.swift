import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped language preference must pass. Check returns its problems, or none.
    protocol CappedLanguagePreferenceRule {
        func check(_ item: CappedLanguagePreference) -> [String]
    }

    final class CappedLanguagePreferenceLabelLengthRule: CappedLanguagePreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedLanguagePreference) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedLanguagePreferenceRequiredCodeRule: CappedLanguagePreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedLanguagePreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedLanguagePreferenceGraceDaysRangeRule: CappedLanguagePreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedLanguagePreference) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a capped language preference.
    final class CappedLanguagePreferenceValidator {
        var rules: [any CappedLanguagePreferenceRule]

        init(rules: [any CappedLanguagePreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedLanguagePreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedLanguagePreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedLanguagePreference]) -> [String: [String]] {
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

    static func defaultCappedLanguagePreferenceValidator() -> CappedLanguagePreferenceValidator {
        return CappedLanguagePreferenceValidator(
            rules: [
                CappedLanguagePreferenceLabelLengthRule(maxLength: 16),
                CappedLanguagePreferenceRequiredCodeRule(message: "capped language preference needs a value"),
                CappedLanguagePreferenceGraceDaysRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
