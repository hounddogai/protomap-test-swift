import AcmePlatform
import Foundation

extension Consent {
    /// A rule a legacy language policy must pass. Check returns its problems, or none.
    protocol LegacyLanguagePolicyRule {
        func check(_ item: LegacyLanguagePolicy) -> [String]
    }

    final class LegacyLanguagePolicyRateRangeRule: LegacyLanguagePolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyLanguagePolicy) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyLanguagePolicyRequiredTitleRule: LegacyLanguagePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyLanguagePolicy) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyLanguagePolicyTitleLengthRule: LegacyLanguagePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyLanguagePolicy) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyLanguagePolicyCodeLengthRule: LegacyLanguagePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyLanguagePolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyLanguagePolicyDurationMinutesRangeRule: LegacyLanguagePolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyLanguagePolicy) -> [String] {
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

    /// Runs every rule of a legacy language policy.
    final class LegacyLanguagePolicyValidator {
        var rules: [any LegacyLanguagePolicyRule]

        init(rules: [any LegacyLanguagePolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyLanguagePolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyLanguagePolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyLanguagePolicy]) -> [String: [String]] {
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

    static func defaultLegacyLanguagePolicyValidator() -> LegacyLanguagePolicyValidator {
        return LegacyLanguagePolicyValidator(
            rules: [
                LegacyLanguagePolicyRateRangeRule(min: 2.6, max: 3737.8),
                LegacyLanguagePolicyRequiredTitleRule(message: "legacy language policy needs a value"),
                LegacyLanguagePolicyTitleLengthRule(maxLength: 80),
                LegacyLanguagePolicyCodeLengthRule(maxLength: 16),
                LegacyLanguagePolicyDurationMinutesRangeRule(min: 32, max: 1000),
            ]
        )
    }
}
