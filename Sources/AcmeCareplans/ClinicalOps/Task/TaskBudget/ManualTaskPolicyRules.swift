import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a manual task policy must pass. Check returns its problems, or none.
    protocol ManualTaskPolicyRule {
        func check(_ item: ManualTaskPolicy) -> [String]
    }

    final class ManualTaskPolicyCodePrefixRule: ManualTaskPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualTaskPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualTaskPolicyRequiredCodeRule: ManualTaskPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualTaskPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualTaskPolicyLabelLengthRule: ManualTaskPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualTaskPolicy) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual task policy.
    final class ManualTaskPolicyValidator {
        var rules: [any ManualTaskPolicyRule]

        init(rules: [any ManualTaskPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualTaskPolicy) -> [String] {
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

        func requireValid(_ item: ManualTaskPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualTaskPolicy]) -> [String: [String]] {
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

    static func defaultManualTaskPolicyValidator() -> ManualTaskPolicyValidator {
        return ManualTaskPolicyValidator(
            rules: [
                ManualTaskPolicyCodePrefixRule(prefix: "ACM"),
                ManualTaskPolicyRequiredCodeRule(message: "manual task policy needs this field"),
                ManualTaskPolicyLabelLengthRule(maxLength: 86400),
            ]
        )
    }
}
