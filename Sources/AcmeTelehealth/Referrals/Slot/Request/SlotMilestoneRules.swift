import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot milestone must pass. Check returns its problems, or none.
    protocol SlotMilestoneRule {
        func check(_ item: SlotMilestone) -> [String]
    }

    final class SlotMilestoneRequiredNameRule: SlotMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotMilestone) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotMilestoneMinimumRangeRule: SlotMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotMilestone) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SlotMilestoneSequenceRangeRule: SlotMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotMilestone) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SlotMilestoneNameLengthRule: SlotMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotMilestone) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot milestone.
    final class SlotMilestoneValidator {
        var rules: [any SlotMilestoneRule]

        init(rules: [any SlotMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotMilestone) -> [String] {
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

        func requireValid(_ item: SlotMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotMilestone]) -> [String: [String]] {
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

    static func defaultSlotMilestoneValidator() -> SlotMilestoneValidator {
        return SlotMilestoneValidator(
            rules: [
                SlotMilestoneRequiredNameRule(message: "slot milestone needs an entry"),
                SlotMilestoneMinimumRangeRule(min: 4.8, max: 2097.5),
                SlotMilestoneSequenceRangeRule(min: 32, max: 255),
                SlotMilestoneNameLengthRule(maxLength: 86400),
            ]
        )
    }
}
