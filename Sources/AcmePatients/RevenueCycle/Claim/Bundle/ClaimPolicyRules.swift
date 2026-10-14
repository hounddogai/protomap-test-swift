import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim policy must pass. Check returns its problems, or none.
    protocol ClaimPolicyRule {
        func check(_ item: ClaimPolicy) -> [String]
    }

    final class ClaimPolicyRequiredCodeRule: ClaimPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimPolicyRevisionRangeRule: ClaimPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimPolicy) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClaimPolicyCodePrefixRule: ClaimPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClaimPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ClaimPolicyRequiredNameRule: ClaimPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimPolicy) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a claim policy.
    final class ClaimPolicyValidator {
        var rules: [any ClaimPolicyRule]

        init(rules: [any ClaimPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClaimPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimPolicy]) -> [String: [String]] {
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

    static func defaultClaimPolicyValidator() -> ClaimPolicyValidator {
        return ClaimPolicyValidator(
            rules: [
                ClaimPolicyRequiredCodeRule(message: "claim policy needs a value"),
                ClaimPolicyRevisionRangeRule(min: 255, max: 255),
                ClaimPolicyCodePrefixRule(prefix: "REF"),
                ClaimPolicyRequiredNameRule(message: "claim policy needs this field"),
            ]
        )
    }
}
