import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range preference must pass. Check returns its problems, or none.
    protocol ReferenceRangePreferenceRule {
        func check(_ item: ReferenceRangePreference) -> [String]
    }

    final class ReferenceRangePreferenceRequiredTitleRule: ReferenceRangePreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangePreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangePreferenceRequiredLocaleRule: ReferenceRangePreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangePreference) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangePreferenceCodeLengthRule: ReferenceRangePreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangePreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangePreferenceTitleLengthRule: ReferenceRangePreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangePreference) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangePreferenceScoreRangeRule: ReferenceRangePreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangePreference) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferenceRangePreferenceLocaleLengthRule: ReferenceRangePreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangePreference) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range preference.
    final class ReferenceRangePreferenceValidator {
        var rules: [any ReferenceRangePreferenceRule]

        init(rules: [any ReferenceRangePreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangePreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangePreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangePreference]) -> [String: [String]] {
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

    static func defaultReferenceRangePreferenceValidator() -> ReferenceRangePreferenceValidator {
        return ReferenceRangePreferenceValidator(
            rules: [
                ReferenceRangePreferenceRequiredTitleRule(message: "reference range preference needs this field"),
                ReferenceRangePreferenceRequiredLocaleRule(message: "reference range preference needs a value"),
                ReferenceRangePreferenceCodeLengthRule(maxLength: 86400),
                ReferenceRangePreferenceTitleLengthRule(maxLength: 1000),
                ReferenceRangePreferenceScoreRangeRule(min: 4.3, max: 643.8),
                ReferenceRangePreferenceLocaleLengthRule(maxLength: 16),
            ]
        )
    }
}
