import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a global closure claim must pass. Check returns its problems, or none.
    protocol GlobalClosureClaimRule {
        func check(_ item: GlobalClosureClaim) -> [String]
    }

    final class GlobalClosureClaimCodePrefixRule: GlobalClosureClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalClosureClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalClosureClaimAllowedEncounterIDRule: GlobalClosureClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalClosureClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is too long"]
            }
            return []
        }
    }

    final class GlobalClosureClaimEndsAtRangeRule: GlobalClosureClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalClosureClaim) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a global closure claim.
    final class GlobalClosureClaimValidator {
        var rules: [any GlobalClosureClaimRule]

        init(rules: [any GlobalClosureClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalClosureClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalClosureClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalClosureClaim]) -> [String: [String]] {
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

    static func defaultGlobalClosureClaimValidator() -> GlobalClosureClaimValidator {
        return GlobalClosureClaimValidator(
            rules: [
                GlobalClosureClaimCodePrefixRule(prefix: "X"),
                GlobalClosureClaimAllowedEncounterIDRule(allowed: ["strict", "global"]),
                GlobalClosureClaimEndsAtRangeRule(min: 64, max: 1000),
            ]
        )
    }
}
