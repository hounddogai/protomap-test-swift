import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending authorization preference must pass. Check returns its problems, or none.
    protocol PendingAuthorizationPreferenceRule {
        func check(_ item: PendingAuthorizationPreference) -> [String]
    }

    final class PendingAuthorizationPreferenceCodePrefixRule: PendingAuthorizationPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingAuthorizationPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingAuthorizationPreferenceSpecialtyLengthRule: PendingAuthorizationPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingAuthorizationPreference) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingAuthorizationPreferenceMinimumRangeRule: PendingAuthorizationPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingAuthorizationPreference) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingAuthorizationPreferenceRequiredSpecialtyRule: PendingAuthorizationPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingAuthorizationPreference) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending authorization preference.
    final class PendingAuthorizationPreferenceValidator {
        var rules: [any PendingAuthorizationPreferenceRule]

        init(rules: [any PendingAuthorizationPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingAuthorizationPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingAuthorizationPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingAuthorizationPreference]) -> [String: [String]] {
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

    static func defaultPendingAuthorizationPreferenceValidator() -> PendingAuthorizationPreferenceValidator {
        return PendingAuthorizationPreferenceValidator(
            rules: [
                PendingAuthorizationPreferenceCodePrefixRule(prefix: "REF"),
                PendingAuthorizationPreferenceSpecialtyLengthRule(maxLength: 16),
                PendingAuthorizationPreferenceMinimumRangeRule(min: 4.4, max: 1601.0),
                PendingAuthorizationPreferenceRequiredSpecialtyRule(
                    message: "pending authorization preference needs an entry"
                ),
            ]
        )
    }
}
