import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a default interaction milestone must pass. Check returns its problems, or none.
    protocol DefaultInteractionMilestoneRule {
        func check(_ item: DefaultInteractionMilestone) -> [String]
    }

    final class DefaultInteractionMilestoneRequiredSegmentRule: DefaultInteractionMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultInteractionMilestone) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultInteractionMilestoneBatchSizeRangeRule: DefaultInteractionMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultInteractionMilestone) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultInteractionMilestoneRequiredLabelRule: DefaultInteractionMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultInteractionMilestone) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default interaction milestone.
    final class DefaultInteractionMilestoneValidator {
        var rules: [any DefaultInteractionMilestoneRule]

        init(rules: [any DefaultInteractionMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultInteractionMilestone) -> [String] {
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

        func requireValid(_ item: DefaultInteractionMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultInteractionMilestone]) -> [String: [String]] {
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

    static func defaultDefaultInteractionMilestoneValidator() -> DefaultInteractionMilestoneValidator {
        return DefaultInteractionMilestoneValidator(
            rules: [
                DefaultInteractionMilestoneRequiredSegmentRule(
                    message: "default interaction milestone needs this field"
                ),
                DefaultInteractionMilestoneBatchSizeRangeRule(min: 64, max: 1000),
                DefaultInteractionMilestoneRequiredLabelRule(
                    message: "default interaction milestone needs this field"
                ),
            ]
        )
    }
}
