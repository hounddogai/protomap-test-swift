import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a fallback outreach rule must pass. Check returns its problems, or none.
    protocol FallbackOutreachRuleRule {
        func check(_ item: FallbackOutreachRule) -> [String]
    }

    final class FallbackOutreachRuleExpiresAtRangeRule: FallbackOutreachRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackOutreachRule) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackOutreachRuleArchivedGuardRule: FallbackOutreachRuleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: FallbackOutreachRule) -> [String] {
            if item.archived && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class FallbackOutreachRuleRateRangeRule: FallbackOutreachRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackOutreachRule) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a fallback outreach rule.
    final class FallbackOutreachRuleValidator {
        var rules: [any FallbackOutreachRuleRule]

        init(rules: [any FallbackOutreachRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackOutreachRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackOutreachRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackOutreachRule]) -> [String: [String]] {
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

    static func defaultFallbackOutreachRuleValidator() -> FallbackOutreachRuleValidator {
        return FallbackOutreachRuleValidator(
            rules: [
                FallbackOutreachRuleExpiresAtRangeRule(min: 80, max: 1000),
                FallbackOutreachRuleArchivedGuardRule(limit: 64),
                FallbackOutreachRuleRateRangeRule(min: 6.8, max: 3806.8),
            ]
        )
    }
}
