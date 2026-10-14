import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient risk score preference must pass. Check returns its problems, or none.
    protocol LenientRiskScorePreferenceRule {
        func check(_ item: LenientRiskScorePreference) -> [String]
    }

    final class LenientRiskScorePreferenceCodeLengthRule: LenientRiskScorePreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientRiskScorePreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientRiskScorePreferenceVersionRangeRule: LenientRiskScorePreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRiskScorePreference) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientRiskScorePreferenceRequiredNotesRule: LenientRiskScorePreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientRiskScorePreference) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient risk score preference.
    final class LenientRiskScorePreferenceValidator {
        var rules: [any LenientRiskScorePreferenceRule]

        init(rules: [any LenientRiskScorePreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientRiskScorePreference) -> [String] {
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

        func requireValid(_ item: LenientRiskScorePreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientRiskScorePreference]) -> [String: [String]] {
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

    static func defaultLenientRiskScorePreferenceValidator() -> LenientRiskScorePreferenceValidator {
        return LenientRiskScorePreferenceValidator(
            rules: [
                LenientRiskScorePreferenceCodeLengthRule(maxLength: 16),
                LenientRiskScorePreferenceVersionRangeRule(min: 3600, max: 86400),
                LenientRiskScorePreferenceRequiredNotesRule(message: "lenient risk score preference needs an entry"),
            ]
        )
    }
}
