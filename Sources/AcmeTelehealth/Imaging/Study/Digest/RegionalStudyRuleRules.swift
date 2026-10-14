import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a regional study rule must pass. Check returns its problems, or none.
    protocol RegionalStudyRuleRule {
        func check(_ item: RegionalStudyRule) -> [String]
    }

    final class RegionalStudyRuleAttemptsRangeRule: RegionalStudyRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalStudyRule) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalStudyRuleCodePrefixRule: RegionalStudyRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalStudyRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalStudyRuleApprovedGuardRule: RegionalStudyRuleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RegionalStudyRule) -> [String] {
            if item.approved && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class RegionalStudyRuleMarginRangeRule: RegionalStudyRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalStudyRule) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a regional study rule.
    final class RegionalStudyRuleValidator {
        var rules: [any RegionalStudyRuleRule]

        init(rules: [any RegionalStudyRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalStudyRule) -> [String] {
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

        func requireValid(_ item: RegionalStudyRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalStudyRule]) -> [String: [String]] {
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

    static func defaultRegionalStudyRuleValidator() -> RegionalStudyRuleValidator {
        return RegionalStudyRuleValidator(
            rules: [
                RegionalStudyRuleAttemptsRangeRule(min: 64, max: 86400),
                RegionalStudyRuleCodePrefixRule(prefix: "REF"),
                RegionalStudyRuleApprovedGuardRule(limit: 120),
                RegionalStudyRuleMarginRangeRule(min: 7.1, max: 1993.5),
            ]
        )
    }
}
