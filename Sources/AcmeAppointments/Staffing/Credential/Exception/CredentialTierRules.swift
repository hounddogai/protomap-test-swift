import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential tier must pass. Check returns its problems, or none.
    protocol CredentialTierRule {
        func check(_ item: CredentialTier) -> [String]
    }

    final class CredentialTierRetriesRangeRule: CredentialTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialTier) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CredentialTierCodeLengthRule: CredentialTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialTierRequiredCodeRule: CredentialTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialTierCodePrefixRule: CredentialTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CredentialTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CredentialTierRequiredNameRule: CredentialTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialTier) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a credential tier.
    final class CredentialTierValidator {
        var rules: [any CredentialTierRule]

        init(rules: [any CredentialTierRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialTier]) -> [String: [String]] {
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

    static func defaultCredentialTierValidator() -> CredentialTierValidator {
        return CredentialTierValidator(
            rules: [
                CredentialTierRetriesRangeRule(min: 64, max: 86400),
                CredentialTierCodeLengthRule(maxLength: 255),
                CredentialTierRequiredCodeRule(message: "credential tier needs a value"),
                CredentialTierCodePrefixRule(prefix: "Q"),
                CredentialTierRequiredNameRule(message: "credential tier needs a value"),
            ]
        )
    }
}
