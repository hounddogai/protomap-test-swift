import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation preference must pass. Check returns its problems, or none.
    protocol RevocationPreferenceRule {
        func check(_ item: RevocationPreference) -> [String]
    }

    final class RevocationPreferenceRequiredCodeRule: RevocationPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationPreferenceRequiredTitleRule: RevocationPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationPreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationPreferenceCopayRangeRule: RevocationPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationPreference) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation preference.
    final class RevocationPreferenceValidator {
        var rules: [any RevocationPreferenceRule]

        init(rules: [any RevocationPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationPreference) -> [String] {
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

        func requireValid(_ item: RevocationPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationPreference]) -> [String: [String]] {
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

    static func defaultRevocationPreferenceValidator() -> RevocationPreferenceValidator {
        return RevocationPreferenceValidator(
            rules: [
                RevocationPreferenceRequiredCodeRule(message: "revocation preference needs a value"),
                RevocationPreferenceRequiredTitleRule(message: "revocation preference needs an entry"),
                RevocationPreferenceCopayRangeRule(min: 3.3, max: 3250.4),
            ]
        )
    }
}
