import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a batched interaction milestone must pass. Check returns its problems, or none.
    protocol BatchedInteractionMilestoneRule {
        func check(_ item: BatchedInteractionMilestone) -> [String]
    }

    final class BatchedInteractionMilestoneAllowedUnitRule: BatchedInteractionMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedInteractionMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is expired"]
            }
            return []
        }
    }

    final class BatchedInteractionMilestoneUnitLengthRule: BatchedInteractionMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedInteractionMilestone) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedInteractionMilestoneRequiredCodeRule: BatchedInteractionMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedInteractionMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedInteractionMilestoneRequiredUnitRule: BatchedInteractionMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedInteractionMilestone) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched interaction milestone.
    final class BatchedInteractionMilestoneValidator {
        var rules: [any BatchedInteractionMilestoneRule]

        init(rules: [any BatchedInteractionMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedInteractionMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedInteractionMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedInteractionMilestone]) -> [String: [String]] {
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

    static func defaultBatchedInteractionMilestoneValidator() -> BatchedInteractionMilestoneValidator {
        return BatchedInteractionMilestoneValidator(
            rules: [
                BatchedInteractionMilestoneAllowedUnitRule(allowed: ["scheduled", "strict"]),
                BatchedInteractionMilestoneUnitLengthRule(maxLength: 3600),
                BatchedInteractionMilestoneRequiredCodeRule(message: "batched interaction milestone needs a value"),
                BatchedInteractionMilestoneRequiredUnitRule(message: "batched interaction milestone needs an entry"),
            ]
        )
    }
}
