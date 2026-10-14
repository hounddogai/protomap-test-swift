import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a fallback goal claim must pass. Check returns its problems, or none.
    protocol FallbackGoalClaimRule {
        func check(_ item: FallbackGoalClaim) -> [String]
    }

    final class FallbackGoalClaimAllowedOwnerIDRule: FallbackGoalClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackGoalClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is unknown"]
            }
            return []
        }
    }

    final class FallbackGoalClaimRequiredOwnerIDRule: FallbackGoalClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackGoalClaim) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackGoalClaimRequiredTitleRule: FallbackGoalClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackGoalClaim) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackGoalClaimAttemptsRangeRule: FallbackGoalClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackGoalClaim) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackGoalClaimRequiredCodeRule: FallbackGoalClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackGoalClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback goal claim.
    final class FallbackGoalClaimValidator {
        var rules: [any FallbackGoalClaimRule]

        init(rules: [any FallbackGoalClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackGoalClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackGoalClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackGoalClaim]) -> [String: [String]] {
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

    static func defaultFallbackGoalClaimValidator() -> FallbackGoalClaimValidator {
        return FallbackGoalClaimValidator(
            rules: [
                FallbackGoalClaimAllowedOwnerIDRule(allowed: ["default", "scheduled", "rolling"]),
                FallbackGoalClaimRequiredOwnerIDRule(message: "fallback goal claim needs this field"),
                FallbackGoalClaimRequiredTitleRule(message: "fallback goal claim needs an entry"),
                FallbackGoalClaimAttemptsRangeRule(min: 64, max: 120),
                FallbackGoalClaimRequiredCodeRule(message: "fallback goal claim needs an entry"),
            ]
        )
    }
}
