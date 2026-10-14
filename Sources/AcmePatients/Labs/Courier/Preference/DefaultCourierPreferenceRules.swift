import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default courier preference must pass. Check returns its problems, or none.
    protocol DefaultCourierPreferenceRule {
        func check(_ item: DefaultCourierPreference) -> [String]
    }

    final class DefaultCourierPreferenceTimezoneLengthRule: DefaultCourierPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCourierPreference) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCourierPreferenceSequenceRangeRule: DefaultCourierPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCourierPreference) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultCourierPreferenceRequiredNameRule: DefaultCourierPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCourierPreference) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCourierPreferenceAllowedSummaryRule: DefaultCourierPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultCourierPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is unknown"]
            }
            return []
        }
    }

    final class DefaultCourierPreferenceNameLengthRule: DefaultCourierPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCourierPreference) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default courier preference.
    final class DefaultCourierPreferenceValidator {
        var rules: [any DefaultCourierPreferenceRule]

        init(rules: [any DefaultCourierPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCourierPreference) -> [String] {
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

        func requireValid(_ item: DefaultCourierPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCourierPreference]) -> [String: [String]] {
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

    static func defaultDefaultCourierPreferenceValidator() -> DefaultCourierPreferenceValidator {
        return DefaultCourierPreferenceValidator(
            rules: [
                DefaultCourierPreferenceTimezoneLengthRule(maxLength: 80),
                DefaultCourierPreferenceSequenceRangeRule(min: 80, max: 3600),
                DefaultCourierPreferenceRequiredNameRule(message: "default courier preference needs an entry"),
                DefaultCourierPreferenceAllowedSummaryRule(allowed: []),
                DefaultCourierPreferenceNameLengthRule(maxLength: 80),
            ]
        )
    }
}
