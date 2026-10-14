import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered closure milestone must pass. Check returns its problems, or none.
    protocol TieredClosureMilestoneRule {
        func check(_ item: TieredClosureMilestone) -> [String]
    }

    final class TieredClosureMilestoneOwnerIDLengthRule: TieredClosureMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredClosureMilestone) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredClosureMilestoneRefillsRangeRule: TieredClosureMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredClosureMilestone) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredClosureMilestoneUnitLengthRule: TieredClosureMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredClosureMilestone) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredClosureMilestoneCapacityRangeRule: TieredClosureMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredClosureMilestone) -> [String] {
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

    final class TieredClosureMilestoneRequiredCodeRule: TieredClosureMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClosureMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredClosureMilestoneRequiredOwnerIDRule: TieredClosureMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClosureMilestone) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered closure milestone.
    final class TieredClosureMilestoneValidator {
        var rules: [any TieredClosureMilestoneRule]

        init(rules: [any TieredClosureMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredClosureMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredClosureMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredClosureMilestone]) -> [String: [String]] {
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

    static func defaultTieredClosureMilestoneValidator() -> TieredClosureMilestoneValidator {
        return TieredClosureMilestoneValidator(
            rules: [
                TieredClosureMilestoneOwnerIDLengthRule(maxLength: 16),
                TieredClosureMilestoneRefillsRangeRule(min: 255, max: 86400),
                TieredClosureMilestoneUnitLengthRule(maxLength: 32),
                TieredClosureMilestoneCapacityRangeRule(min: 16, max: 255),
                TieredClosureMilestoneRequiredCodeRule(message: "tiered closure milestone needs this field"),
                TieredClosureMilestoneRequiredOwnerIDRule(message: "tiered closure milestone needs a value"),
            ]
        )
    }
}
