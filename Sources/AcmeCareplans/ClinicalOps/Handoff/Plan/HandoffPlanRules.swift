import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff plan must pass. Check returns its problems, or none.
    protocol HandoffPlanRule {
        func check(_ item: HandoffPlan) -> [String]
    }

    final class HandoffPlanPinnedGuardRule: HandoffPlanRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: HandoffPlan) -> [String] {
            if item.pinned && (item.batchSize > limit) {
                return ["batch size \(item.batchSize) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class HandoffPlanCapacityRangeRule: HandoffPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffPlan) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class HandoffPlanRequiredSegmentRule: HandoffPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffPlan) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffPlanAllowedNameRule: HandoffPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: HandoffPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is out of range"]
            }
            return []
        }
    }

    final class HandoffPlanRequiredCodeRule: HandoffPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffPlanCodeLengthRule: HandoffPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a handoff plan.
    final class HandoffPlanValidator {
        var rules: [any HandoffPlanRule]

        init(rules: [any HandoffPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffPlan) -> [String] {
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

        func requireValid(_ item: HandoffPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffPlan]) -> [String: [String]] {
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

    static func defaultHandoffPlanValidator() -> HandoffPlanValidator {
        return HandoffPlanValidator(
            rules: [
                HandoffPlanPinnedGuardRule(limit: 16),
                HandoffPlanCapacityRangeRule(min: 64, max: 120),
                HandoffPlanRequiredSegmentRule(message: "handoff plan needs this field"),
                HandoffPlanAllowedNameRule(allowed: ["regional", "global", "pending"]),
                HandoffPlanRequiredCodeRule(message: "handoff plan needs an entry"),
                HandoffPlanCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
