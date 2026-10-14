import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer milestone must pass. Check returns its problems, or none.
    protocol TransferMilestoneRule {
        func check(_ item: TransferMilestone) -> [String]
    }

    final class TransferMilestoneEndsAtRangeRule: TransferMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferMilestone) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TransferMilestoneActiveGuardRule: TransferMilestoneRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: TransferMilestone) -> [String] {
            if item.active && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class TransferMilestoneRequiredLabelRule: TransferMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferMilestone) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a transfer milestone.
    final class TransferMilestoneValidator {
        var rules: [any TransferMilestoneRule]

        init(rules: [any TransferMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferMilestone) -> [String] {
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

        func requireValid(_ item: TransferMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferMilestone]) -> [String: [String]] {
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

    static func defaultTransferMilestoneValidator() -> TransferMilestoneValidator {
        return TransferMilestoneValidator(
            rules: [
                TransferMilestoneEndsAtRangeRule(min: 80, max: 120),
                TransferMilestoneActiveGuardRule(limit: 7.1),
                TransferMilestoneRequiredLabelRule(message: "transfer milestone needs this field"),
            ]
        )
    }
}
