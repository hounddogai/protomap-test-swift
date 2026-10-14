import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist policy must pass. Check returns its problems, or none.
    protocol WorklistPolicyRule {
        func check(_ item: WorklistPolicy) -> [String]
    }

    final class WorklistPolicyRequiredBedRule: WorklistPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistPolicy) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistPolicyRequiredCodeRule: WorklistPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistPolicyNameLengthRule: WorklistPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistPolicy) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistPolicyAllowedTimezoneRule: WorklistPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WorklistPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is above maximum"]
            }
            return []
        }
    }

    final class WorklistPolicyCodeLengthRule: WorklistPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist policy.
    final class WorklistPolicyValidator {
        var rules: [any WorklistPolicyRule]

        init(rules: [any WorklistPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistPolicy]) -> [String: [String]] {
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

    static func defaultWorklistPolicyValidator() -> WorklistPolicyValidator {
        return WorklistPolicyValidator(
            rules: [
                WorklistPolicyRequiredBedRule(message: "worklist policy needs an entry"),
                WorklistPolicyRequiredCodeRule(message: "worklist policy needs an entry"),
                WorklistPolicyNameLengthRule(maxLength: 32),
                WorklistPolicyAllowedTimezoneRule(allowed: ["primary", "global", "batched"]),
                WorklistPolicyCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
