import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a regional inventory policy must pass. Check returns its problems, or none.
    protocol RegionalInventoryPolicyRule {
        func check(_ item: RegionalInventoryPolicy) -> [String]
    }

    final class RegionalInventoryPolicyAllowedCodeRule: RegionalInventoryPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalInventoryPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class RegionalInventoryPolicyRequiredProcedureCodeRule: RegionalInventoryPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalInventoryPolicy) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalInventoryPolicyRequiredCodeRule: RegionalInventoryPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalInventoryPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional inventory policy.
    final class RegionalInventoryPolicyValidator {
        var rules: [any RegionalInventoryPolicyRule]

        init(rules: [any RegionalInventoryPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalInventoryPolicy) -> [String] {
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

        func requireValid(_ item: RegionalInventoryPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalInventoryPolicy]) -> [String: [String]] {
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

    static func defaultRegionalInventoryPolicyValidator() -> RegionalInventoryPolicyValidator {
        return RegionalInventoryPolicyValidator(
            rules: [
                RegionalInventoryPolicyAllowedCodeRule(allowed: ["adaptive"]),
                RegionalInventoryPolicyRequiredProcedureCodeRule(
                    message: "regional inventory policy needs this field"
                ),
                RegionalInventoryPolicyRequiredCodeRule(message: "regional inventory policy needs a value"),
            ]
        )
    }
}
