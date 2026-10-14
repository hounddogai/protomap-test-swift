import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a adaptive read milestone must pass. Check returns its problems, or none.
    protocol AdaptiveReadMilestoneRule {
        func check(_ item: AdaptiveReadMilestone) -> [String]
    }

    final class AdaptiveReadMilestoneRequiredCodeRule: AdaptiveReadMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveReadMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveReadMilestoneAllowedCodeRule: AdaptiveReadMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveReadMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class AdaptiveReadMilestoneCostRangeRule: AdaptiveReadMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveReadMilestone) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a adaptive read milestone.
    final class AdaptiveReadMilestoneValidator {
        var rules: [any AdaptiveReadMilestoneRule]

        init(rules: [any AdaptiveReadMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveReadMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveReadMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveReadMilestone]) -> [String: [String]] {
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

    static func defaultAdaptiveReadMilestoneValidator() -> AdaptiveReadMilestoneValidator {
        return AdaptiveReadMilestoneValidator(
            rules: [
                AdaptiveReadMilestoneRequiredCodeRule(message: "adaptive read milestone needs an entry"),
                AdaptiveReadMilestoneAllowedCodeRule(allowed: ["fallback", "weighted", "global"]),
                AdaptiveReadMilestoneCostRangeRule(min: 4.7, max: 2301.3),
            ]
        )
    }
}
