import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim rule must pass. Check returns its problems, or none.
    protocol ClaimRuleRule {
        func check(_ item: ClaimRule) -> [String]
    }

    final class ClaimRuleAllowedLocaleRule: ClaimRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClaimRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is missing"]
            }
            return []
        }
    }

    final class ClaimRuleStartsAtRangeRule: ClaimRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimRule) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ClaimRuleCodePrefixRule: ClaimRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClaimRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim rule.
    final class ClaimRuleValidator {
        var rules: [any ClaimRuleRule]

        init(rules: [any ClaimRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimRule) -> [String] {
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

        func requireValid(_ item: ClaimRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimRule]) -> [String: [String]] {
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

    static func defaultClaimRuleValidator() -> ClaimRuleValidator {
        return ClaimRuleValidator(
            rules: [
                ClaimRuleAllowedLocaleRule(allowed: ["batched", "batched", "seasonal"]),
                ClaimRuleStartsAtRangeRule(min: 16, max: 1000),
                ClaimRuleCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
