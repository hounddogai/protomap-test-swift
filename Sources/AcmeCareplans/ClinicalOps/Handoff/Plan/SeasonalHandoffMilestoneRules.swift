import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a seasonal handoff milestone must pass. Check returns its problems, or none.
    protocol SeasonalHandoffMilestoneRule {
        func check(_ item: SeasonalHandoffMilestone) -> [String]
    }

    final class SeasonalHandoffMilestoneCodePrefixRule: SeasonalHandoffMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalHandoffMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalHandoffMilestoneAllowedCodeRule: SeasonalHandoffMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalHandoffMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class SeasonalHandoffMilestoneScoreRangeRule: SeasonalHandoffMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalHandoffMilestone) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a seasonal handoff milestone.
    final class SeasonalHandoffMilestoneValidator {
        var rules: [any SeasonalHandoffMilestoneRule]

        init(rules: [any SeasonalHandoffMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalHandoffMilestone) -> [String] {
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

        func requireValid(_ item: SeasonalHandoffMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalHandoffMilestone]) -> [String: [String]] {
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

    static func defaultSeasonalHandoffMilestoneValidator() -> SeasonalHandoffMilestoneValidator {
        return SeasonalHandoffMilestoneValidator(
            rules: [
                SeasonalHandoffMilestoneCodePrefixRule(prefix: "ACM"),
                SeasonalHandoffMilestoneAllowedCodeRule(allowed: ["pending", "tiered", "fallback"]),
                SeasonalHandoffMilestoneScoreRangeRule(min: 5.0, max: 2648.2),
            ]
        )
    }
}
