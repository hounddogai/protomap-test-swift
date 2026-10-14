import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment preference must pass. Check returns its problems, or none.
    protocol AssessmentPreferenceRule {
        func check(_ item: AssessmentPreference) -> [String]
    }

    final class AssessmentPreferencePayerLengthRule: AssessmentPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentPreference) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentPreferenceRequiredPayerRule: AssessmentPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentPreference) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentPreferenceRequiredTitleRule: AssessmentPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentPreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentPreferenceCodePrefixRule: AssessmentPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AssessmentPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AssessmentPreferenceRequiredChannelRule: AssessmentPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentPreference) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a assessment preference.
    final class AssessmentPreferenceValidator {
        var rules: [any AssessmentPreferenceRule]

        init(rules: [any AssessmentPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentPreference) -> [String] {
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

        func requireValid(_ item: AssessmentPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentPreference]) -> [String: [String]] {
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

    static func defaultAssessmentPreferenceValidator() -> AssessmentPreferenceValidator {
        return AssessmentPreferenceValidator(
            rules: [
                AssessmentPreferencePayerLengthRule(maxLength: 80),
                AssessmentPreferenceRequiredPayerRule(message: "assessment preference needs an entry"),
                AssessmentPreferenceRequiredTitleRule(message: "assessment preference needs a value"),
                AssessmentPreferenceCodePrefixRule(prefix: "X"),
                AssessmentPreferenceRequiredChannelRule(message: "assessment preference needs an entry"),
            ]
        )
    }
}
