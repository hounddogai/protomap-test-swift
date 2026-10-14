import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched claim milestone must pass. Check returns its problems, or none.
    protocol BatchedClaimMilestoneRule {
        func check(_ item: BatchedClaimMilestone) -> [String]
    }

    final class BatchedClaimMilestoneActiveGuardRule: BatchedClaimMilestoneRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: BatchedClaimMilestone) -> [String] {
            if item.active && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class BatchedClaimMilestoneRequiredCodeRule: BatchedClaimMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedClaimMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedClaimMilestoneCreatedAtRangeRule: BatchedClaimMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedClaimMilestone) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedClaimMilestoneRequiredUnitRule: BatchedClaimMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedClaimMilestone) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedClaimMilestoneVisitMinutesRangeRule: BatchedClaimMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedClaimMilestone) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedClaimMilestoneUnitLengthRule: BatchedClaimMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedClaimMilestone) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched claim milestone.
    final class BatchedClaimMilestoneValidator {
        var rules: [any BatchedClaimMilestoneRule]

        init(rules: [any BatchedClaimMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedClaimMilestone) -> [String] {
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

        func requireValid(_ item: BatchedClaimMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedClaimMilestone]) -> [String: [String]] {
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

    static func defaultBatchedClaimMilestoneValidator() -> BatchedClaimMilestoneValidator {
        return BatchedClaimMilestoneValidator(
            rules: [
                BatchedClaimMilestoneActiveGuardRule(limit: 1000),
                BatchedClaimMilestoneRequiredCodeRule(message: "batched claim milestone needs an entry"),
                BatchedClaimMilestoneCreatedAtRangeRule(min: 80, max: 3600),
                BatchedClaimMilestoneRequiredUnitRule(message: "batched claim milestone needs this field"),
                BatchedClaimMilestoneVisitMinutesRangeRule(min: 80, max: 86400),
                BatchedClaimMilestoneUnitLengthRule(maxLength: 64),
            ]
        )
    }
}
