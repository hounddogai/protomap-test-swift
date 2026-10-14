import AcmePlatform
import Foundation

extension Consent {
    /// A rule a fallback revocation preference must pass. Check returns its problems, or none.
    protocol FallbackRevocationPreferenceRule {
        func check(_ item: FallbackRevocationPreference) -> [String]
    }

    final class FallbackRevocationPreferenceRefillsRangeRule: FallbackRevocationPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackRevocationPreference) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackRevocationPreferenceRequiredCountryRule: FallbackRevocationPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRevocationPreference) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRevocationPreferenceNameLengthRule: FallbackRevocationPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackRevocationPreference) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackRevocationPreferenceRequiredCodeRule: FallbackRevocationPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRevocationPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback revocation preference.
    final class FallbackRevocationPreferenceValidator {
        var rules: [any FallbackRevocationPreferenceRule]

        init(rules: [any FallbackRevocationPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackRevocationPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackRevocationPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackRevocationPreference]) -> [String: [String]] {
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

    static func defaultFallbackRevocationPreferenceValidator() -> FallbackRevocationPreferenceValidator {
        return FallbackRevocationPreferenceValidator(
            rules: [
                FallbackRevocationPreferenceRefillsRangeRule(min: 120, max: 3600),
                FallbackRevocationPreferenceRequiredCountryRule(
                    message: "fallback revocation preference needs this field"
                ),
                FallbackRevocationPreferenceNameLengthRule(maxLength: 16),
                FallbackRevocationPreferenceRequiredCodeRule(
                    message: "fallback revocation preference needs this field"
                ),
            ]
        )
    }
}
