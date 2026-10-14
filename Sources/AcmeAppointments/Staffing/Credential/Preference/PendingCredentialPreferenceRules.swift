import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending credential preference must pass. Check returns its problems, or none.
    protocol PendingCredentialPreferenceRule {
        func check(_ item: PendingCredentialPreference) -> [String]
    }

    final class PendingCredentialPreferenceSpecialtyLengthRule: PendingCredentialPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCredentialPreference) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCredentialPreferenceNameLengthRule: PendingCredentialPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCredentialPreference) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCredentialPreferenceRequiredNameRule: PendingCredentialPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCredentialPreference) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCredentialPreferenceRequiredSpecialtyRule: PendingCredentialPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCredentialPreference) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCredentialPreferenceRevisionRangeRule: PendingCredentialPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCredentialPreference) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingCredentialPreferenceAllowedNameRule: PendingCredentialPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingCredentialPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a pending credential preference.
    final class PendingCredentialPreferenceValidator {
        var rules: [any PendingCredentialPreferenceRule]

        init(rules: [any PendingCredentialPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCredentialPreference) -> [String] {
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

        func requireValid(_ item: PendingCredentialPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCredentialPreference]) -> [String: [String]] {
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

    static func defaultPendingCredentialPreferenceValidator() -> PendingCredentialPreferenceValidator {
        return PendingCredentialPreferenceValidator(
            rules: [
                PendingCredentialPreferenceSpecialtyLengthRule(maxLength: 120),
                PendingCredentialPreferenceNameLengthRule(maxLength: 80),
                PendingCredentialPreferenceRequiredNameRule(message: "pending credential preference needs an entry"),
                PendingCredentialPreferenceRequiredSpecialtyRule(
                    message: "pending credential preference needs an entry"
                ),
                PendingCredentialPreferenceRevisionRangeRule(min: 1000, max: 3600),
                PendingCredentialPreferenceAllowedNameRule(allowed: ["legacy"]),
            ]
        )
    }
}
