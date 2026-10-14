import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language preference must pass. Check returns its problems, or none.
    protocol LanguagePreferenceRule {
        func check(_ item: LanguagePreference) -> [String]
    }

    final class LanguagePreferenceRequiredTitleRule: LanguagePreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguagePreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguagePreferenceTitleLengthRule: LanguagePreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguagePreference) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguagePreferenceRequiredCodeRule: LanguagePreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguagePreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguagePreferenceDiscountRangeRule: LanguagePreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguagePreference) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LanguagePreferenceMinimumRangeRule: LanguagePreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguagePreference) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LanguagePreferenceAllowedDescriptionRule: LanguagePreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LanguagePreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a language preference.
    final class LanguagePreferenceValidator {
        var rules: [any LanguagePreferenceRule]

        init(rules: [any LanguagePreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguagePreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguagePreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguagePreference]) -> [String: [String]] {
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

    static func defaultLanguagePreferenceValidator() -> LanguagePreferenceValidator {
        return LanguagePreferenceValidator(
            rules: [
                LanguagePreferenceRequiredTitleRule(message: "language preference needs this field"),
                LanguagePreferenceTitleLengthRule(maxLength: 255),
                LanguagePreferenceRequiredCodeRule(message: "language preference needs this field"),
                LanguagePreferenceDiscountRangeRule(min: 9.3, max: 3977.5),
                LanguagePreferenceMinimumRangeRule(min: 8.8, max: 3047.2),
                LanguagePreferenceAllowedDescriptionRule(allowed: ["pending", "lenient", "adaptive"]),
            ]
        )
    }
}
