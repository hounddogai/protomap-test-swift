import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a default cleaning preference must pass. Check returns its problems, or none.
    protocol DefaultCleaningPreferenceRule {
        func check(_ item: DefaultCleaningPreference) -> [String]
    }

    final class DefaultCleaningPreferenceRequiredTitleRule: DefaultCleaningPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCleaningPreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCleaningPreferenceDurationMinutesRangeRule: DefaultCleaningPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCleaningPreference) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultCleaningPreferenceDiagnosisCodeLengthRule: DefaultCleaningPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCleaningPreference) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default cleaning preference.
    final class DefaultCleaningPreferenceValidator {
        var rules: [any DefaultCleaningPreferenceRule]

        init(rules: [any DefaultCleaningPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCleaningPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultCleaningPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCleaningPreference]) -> [String: [String]] {
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

    static func defaultDefaultCleaningPreferenceValidator() -> DefaultCleaningPreferenceValidator {
        return DefaultCleaningPreferenceValidator(
            rules: [
                DefaultCleaningPreferenceRequiredTitleRule(message: "default cleaning preference needs this field"),
                DefaultCleaningPreferenceDurationMinutesRangeRule(min: 255, max: 3600),
                DefaultCleaningPreferenceDiagnosisCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
