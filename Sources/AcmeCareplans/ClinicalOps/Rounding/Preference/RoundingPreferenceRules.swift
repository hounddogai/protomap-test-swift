import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding preference must pass. Check returns its problems, or none.
    protocol RoundingPreferenceRule {
        func check(_ item: RoundingPreference) -> [String]
    }

    final class RoundingPreferenceTimezoneLengthRule: RoundingPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingPreference) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingPreferenceCodeLengthRule: RoundingPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingPreferenceCodePrefixRule: RoundingPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RoundingPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RoundingPreferenceLabelLengthRule: RoundingPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingPreference) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding preference.
    final class RoundingPreferenceValidator {
        var rules: [any RoundingPreferenceRule]

        init(rules: [any RoundingPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingPreference]) -> [String: [String]] {
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

    static func defaultRoundingPreferenceValidator() -> RoundingPreferenceValidator {
        return RoundingPreferenceValidator(
            rules: [
                RoundingPreferenceTimezoneLengthRule(maxLength: 120),
                RoundingPreferenceCodeLengthRule(maxLength: 255),
                RoundingPreferenceCodePrefixRule(prefix: "X"),
                RoundingPreferenceLabelLengthRule(maxLength: 64),
            ]
        )
    }
}
