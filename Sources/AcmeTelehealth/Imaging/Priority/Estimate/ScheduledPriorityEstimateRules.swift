import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a scheduled priority estimate must pass. Check returns its problems, or none.
    protocol ScheduledPriorityEstimateRule {
        func check(_ item: ScheduledPriorityEstimate) -> [String]
    }

    final class ScheduledPriorityEstimateWeightRangeRule: ScheduledPriorityEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledPriorityEstimate) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledPriorityEstimateAllowedDiagnosisCodeRule: ScheduledPriorityEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledPriorityEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is stale"]
            }
            return []
        }
    }

    final class ScheduledPriorityEstimateRequiredTitleRule: ScheduledPriorityEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledPriorityEstimate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledPriorityEstimateRequiredCodeRule: ScheduledPriorityEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledPriorityEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled priority estimate.
    final class ScheduledPriorityEstimateValidator {
        var rules: [any ScheduledPriorityEstimateRule]

        init(rules: [any ScheduledPriorityEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledPriorityEstimate) -> [String] {
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

        func requireValid(_ item: ScheduledPriorityEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledPriorityEstimate]) -> [String: [String]] {
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

    static func defaultScheduledPriorityEstimateValidator() -> ScheduledPriorityEstimateValidator {
        return ScheduledPriorityEstimateValidator(
            rules: [
                ScheduledPriorityEstimateWeightRangeRule(min: 6.3, max: 4803.8),
                ScheduledPriorityEstimateAllowedDiagnosisCodeRule(allowed: ["legacy", "batched", "batched"]),
                ScheduledPriorityEstimateRequiredTitleRule(message: "scheduled priority estimate needs an entry"),
                ScheduledPriorityEstimateRequiredCodeRule(message: "scheduled priority estimate needs this field"),
            ]
        )
    }
}
