import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling result policy must pass. Check returns its problems, or none.
    protocol RollingResultPolicyRule {
        func check(_ item: RollingResultPolicy) -> [String]
    }

    final class RollingResultPolicyAllergyLengthRule: RollingResultPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingResultPolicy) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingResultPolicyArchivedGuardRule: RollingResultPolicyRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RollingResultPolicy) -> [String] {
            if item.archived && (item.graceDays > limit) {
                return ["grace days \(item.graceDays) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class RollingResultPolicyRequiredExternalRefRule: RollingResultPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingResultPolicy) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingResultPolicyCodePrefixRule: RollingResultPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingResultPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling result policy.
    final class RollingResultPolicyValidator {
        var rules: [any RollingResultPolicyRule]

        init(rules: [any RollingResultPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingResultPolicy) -> [String] {
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

        func requireValid(_ item: RollingResultPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingResultPolicy]) -> [String: [String]] {
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

    static func defaultRollingResultPolicyValidator() -> RollingResultPolicyValidator {
        return RollingResultPolicyValidator(
            rules: [
                RollingResultPolicyAllergyLengthRule(maxLength: 1000),
                RollingResultPolicyArchivedGuardRule(limit: 64),
                RollingResultPolicyRequiredExternalRefRule(message: "rolling result policy needs a value"),
                RollingResultPolicyCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
