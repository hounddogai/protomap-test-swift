import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rolling task policy must pass. Check returns its problems, or none.
    protocol RollingTaskPolicyRule {
        func check(_ item: RollingTaskPolicy) -> [String]
    }

    final class RollingTaskPolicyTitleLengthRule: RollingTaskPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingTaskPolicy) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingTaskPolicyRequiredCategoryRule: RollingTaskPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingTaskPolicy) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingTaskPolicyCodePrefixRule: RollingTaskPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingTaskPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingTaskPolicyRequiredLabelRule: RollingTaskPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingTaskPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingTaskPolicyCategoryLengthRule: RollingTaskPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingTaskPolicy) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingTaskPolicyAllowedCodeRule: RollingTaskPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingTaskPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling task policy.
    final class RollingTaskPolicyValidator {
        var rules: [any RollingTaskPolicyRule]

        init(rules: [any RollingTaskPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingTaskPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingTaskPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingTaskPolicy]) -> [String: [String]] {
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

    static func defaultRollingTaskPolicyValidator() -> RollingTaskPolicyValidator {
        return RollingTaskPolicyValidator(
            rules: [
                RollingTaskPolicyTitleLengthRule(maxLength: 120),
                RollingTaskPolicyRequiredCategoryRule(message: "rolling task policy needs an entry"),
                RollingTaskPolicyCodePrefixRule(prefix: "Q"),
                RollingTaskPolicyRequiredLabelRule(message: "rolling task policy needs this field"),
                RollingTaskPolicyCategoryLengthRule(maxLength: 64),
                RollingTaskPolicyAllowedCodeRule(allowed: ["regional"]),
            ]
        )
    }
}
