import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a pending rounding plan must pass. Check returns its problems, or none.
    protocol PendingRoundingPlanRule {
        func check(_ item: PendingRoundingPlan) -> [String]
    }

    final class PendingRoundingPlanPinnedGuardRule: PendingRoundingPlanRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PendingRoundingPlan) -> [String] {
            if item.pinned && (item.graceDays > limit) {
                return ["grace days \(item.graceDays) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class PendingRoundingPlanThresholdRangeRule: PendingRoundingPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRoundingPlan) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingRoundingPlanUnitLengthRule: PendingRoundingPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingRoundingPlan) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingRoundingPlanTitleLengthRule: PendingRoundingPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingRoundingPlan) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingRoundingPlanRequiredTitleRule: PendingRoundingPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRoundingPlan) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRoundingPlanCodePrefixRule: PendingRoundingPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingRoundingPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending rounding plan.
    final class PendingRoundingPlanValidator {
        var rules: [any PendingRoundingPlanRule]

        init(rules: [any PendingRoundingPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingRoundingPlan) -> [String] {
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

        func requireValid(_ item: PendingRoundingPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingRoundingPlan]) -> [String: [String]] {
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

    static func defaultPendingRoundingPlanValidator() -> PendingRoundingPlanValidator {
        return PendingRoundingPlanValidator(
            rules: [
                PendingRoundingPlanPinnedGuardRule(limit: 3600),
                PendingRoundingPlanThresholdRangeRule(min: 6.5, max: 157.4),
                PendingRoundingPlanUnitLengthRule(maxLength: 16),
                PendingRoundingPlanTitleLengthRule(maxLength: 1000),
                PendingRoundingPlanRequiredTitleRule(message: "pending rounding plan needs a value"),
                PendingRoundingPlanCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
