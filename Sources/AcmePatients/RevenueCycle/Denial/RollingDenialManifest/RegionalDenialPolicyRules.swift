import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a regional denial policy must pass. Check returns its problems, or none.
    protocol RegionalDenialPolicyRule {
        func check(_ item: RegionalDenialPolicy) -> [String]
    }

    final class RegionalDenialPolicyCodePrefixRule: RegionalDenialPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalDenialPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalDenialPolicyRequiredTitleRule: RegionalDenialPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalDenialPolicy) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalDenialPolicyRequiredCodeRule: RegionalDenialPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalDenialPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalDenialPolicyRequiredDiagnosisCodeRule: RegionalDenialPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalDenialPolicy) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional denial policy.
    final class RegionalDenialPolicyValidator {
        var rules: [any RegionalDenialPolicyRule]

        init(rules: [any RegionalDenialPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalDenialPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalDenialPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalDenialPolicy]) -> [String: [String]] {
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

    static func defaultRegionalDenialPolicyValidator() -> RegionalDenialPolicyValidator {
        return RegionalDenialPolicyValidator(
            rules: [
                RegionalDenialPolicyCodePrefixRule(prefix: "REF"),
                RegionalDenialPolicyRequiredTitleRule(message: "regional denial policy needs an entry"),
                RegionalDenialPolicyRequiredCodeRule(message: "regional denial policy needs this field"),
                RegionalDenialPolicyRequiredDiagnosisCodeRule(message: "regional denial policy needs an entry"),
            ]
        )
    }
}
