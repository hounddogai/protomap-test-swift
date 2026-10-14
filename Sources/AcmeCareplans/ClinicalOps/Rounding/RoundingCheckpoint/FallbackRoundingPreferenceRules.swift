import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback rounding preference must pass. Check returns its problems, or none.
    protocol FallbackRoundingPreferenceRule {
        func check(_ item: FallbackRoundingPreference) -> [String]
    }

    final class FallbackRoundingPreferenceRequiredCodeRule: FallbackRoundingPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRoundingPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRoundingPreferenceRequiredSpecialtyRule: FallbackRoundingPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRoundingPreference) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRoundingPreferenceSpecialtyLengthRule: FallbackRoundingPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackRoundingPreference) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackRoundingPreferenceAllowedSpecialtyRule: FallbackRoundingPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackRoundingPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback rounding preference.
    final class FallbackRoundingPreferenceValidator {
        var rules: [any FallbackRoundingPreferenceRule]

        init(rules: [any FallbackRoundingPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackRoundingPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackRoundingPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackRoundingPreference]) -> [String: [String]] {
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

    static func defaultFallbackRoundingPreferenceValidator() -> FallbackRoundingPreferenceValidator {
        return FallbackRoundingPreferenceValidator(
            rules: [
                FallbackRoundingPreferenceRequiredCodeRule(message: "fallback rounding preference needs a value"),
                FallbackRoundingPreferenceRequiredSpecialtyRule(
                    message: "fallback rounding preference needs an entry"
                ),
                FallbackRoundingPreferenceSpecialtyLengthRule(maxLength: 32),
                FallbackRoundingPreferenceAllowedSpecialtyRule(allowed: []),
            ]
        )
    }
}
