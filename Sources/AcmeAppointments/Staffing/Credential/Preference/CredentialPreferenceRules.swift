import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential preference must pass. Check returns its problems, or none.
    protocol CredentialPreferenceRule {
        func check(_ item: CredentialPreference) -> [String]
    }

    final class CredentialPreferenceAmountRangeRule: CredentialPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialPreference) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CredentialPreferenceNameLengthRule: CredentialPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialPreference) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialPreferenceRequiredSegmentRule: CredentialPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialPreference) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialPreferenceCodeLengthRule: CredentialPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialPreferenceRequiredCodeRule: CredentialPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a credential preference.
    final class CredentialPreferenceValidator {
        var rules: [any CredentialPreferenceRule]

        init(rules: [any CredentialPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialPreference]) -> [String: [String]] {
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

    static func defaultCredentialPreferenceValidator() -> CredentialPreferenceValidator {
        return CredentialPreferenceValidator(
            rules: [
                CredentialPreferenceAmountRangeRule(min: 1.0, max: 3971.9),
                CredentialPreferenceNameLengthRule(maxLength: 1000),
                CredentialPreferenceRequiredSegmentRule(message: "credential preference needs this field"),
                CredentialPreferenceCodeLengthRule(maxLength: 16),
                CredentialPreferenceRequiredCodeRule(message: "credential preference needs this field"),
            ]
        )
    }
}
