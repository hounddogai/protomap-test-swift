import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form preference must pass. Check returns its problems, or none.
    protocol ConsentFormPreferenceRule {
        func check(_ item: ConsentFormPreference) -> [String]
    }

    final class ConsentFormPreferenceSpecialtyLengthRule: ConsentFormPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormPreference) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormPreferenceDescriptionLengthRule: ConsentFormPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormPreference) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormPreferenceLimitRangeRule: ConsentFormPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormPreference) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ConsentFormPreferenceAllowedCodeRule: ConsentFormPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ConsentFormPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class ConsentFormPreferenceRateRangeRule: ConsentFormPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormPreference) -> [String] {
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

    final class ConsentFormPreferenceRequiredSpecialtyRule: ConsentFormPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormPreference) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a consent form preference.
    final class ConsentFormPreferenceValidator {
        var rules: [any ConsentFormPreferenceRule]

        init(rules: [any ConsentFormPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormPreference]) -> [String: [String]] {
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

    static func defaultConsentFormPreferenceValidator() -> ConsentFormPreferenceValidator {
        return ConsentFormPreferenceValidator(
            rules: [
                ConsentFormPreferenceSpecialtyLengthRule(maxLength: 32),
                ConsentFormPreferenceDescriptionLengthRule(maxLength: 80),
                ConsentFormPreferenceLimitRangeRule(min: 16, max: 86400),
                ConsentFormPreferenceAllowedCodeRule(allowed: ["batched", "adaptive", "lenient"]),
                ConsentFormPreferenceRateRangeRule(min: 8.0, max: 2213.3),
                ConsentFormPreferenceRequiredSpecialtyRule(message: "consent form preference needs an entry"),
            ]
        )
    }
}
