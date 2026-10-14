import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure preference must pass. Check returns its problems, or none.
    protocol ClosurePreferenceRule {
        func check(_ item: ClosurePreference) -> [String]
    }

    final class ClosurePreferenceAllowedDiagnosisCodeRule: ClosurePreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClosurePreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is blocked"]
            }
            return []
        }
    }

    final class ClosurePreferencePayerLengthRule: ClosurePreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosurePreference) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosurePreferenceRequiredTitleRule: ClosurePreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosurePreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a closure preference.
    final class ClosurePreferenceValidator {
        var rules: [any ClosurePreferenceRule]

        init(rules: [any ClosurePreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosurePreference) -> [String] {
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

        func requireValid(_ item: ClosurePreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosurePreference]) -> [String: [String]] {
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

    static func defaultClosurePreferenceValidator() -> ClosurePreferenceValidator {
        return ClosurePreferenceValidator(
            rules: [
                ClosurePreferenceAllowedDiagnosisCodeRule(allowed: ["seasonal"]),
                ClosurePreferencePayerLengthRule(maxLength: 3600),
                ClosurePreferenceRequiredTitleRule(message: "closure preference needs an entry"),
            ]
        )
    }
}
