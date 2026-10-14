import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential milestone must pass. Check returns its problems, or none.
    protocol CredentialMilestoneRule {
        func check(_ item: CredentialMilestone) -> [String]
    }

    final class CredentialMilestoneRequiredCodeRule: CredentialMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialMilestoneRequiredSourceRule: CredentialMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialMilestone) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialMilestoneCodeLengthRule: CredentialMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialMilestoneCodePrefixRule: CredentialMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CredentialMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CredentialMilestoneCeilingRangeRule: CredentialMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialMilestone) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CredentialMilestoneRequiredPhoneRule: CredentialMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialMilestone) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a credential milestone.
    final class CredentialMilestoneValidator {
        var rules: [any CredentialMilestoneRule]

        init(rules: [any CredentialMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialMilestone]) -> [String: [String]] {
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

    static func defaultCredentialMilestoneValidator() -> CredentialMilestoneValidator {
        return CredentialMilestoneValidator(
            rules: [
                CredentialMilestoneRequiredCodeRule(message: "credential milestone needs this field"),
                CredentialMilestoneRequiredSourceRule(message: "credential milestone needs this field"),
                CredentialMilestoneCodeLengthRule(maxLength: 64),
                CredentialMilestoneCodePrefixRule(prefix: "ACM"),
                CredentialMilestoneCeilingRangeRule(min: 3.3, max: 937.0),
                CredentialMilestoneRequiredPhoneRule(message: "credential milestone needs an entry"),
            ]
        )
    }
}
