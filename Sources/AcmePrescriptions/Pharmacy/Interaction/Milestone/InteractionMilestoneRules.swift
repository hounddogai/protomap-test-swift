import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction milestone must pass. Check returns its problems, or none.
    protocol InteractionMilestoneRule {
        func check(_ item: InteractionMilestone) -> [String]
    }

    final class InteractionMilestoneDurationMinutesRangeRule: InteractionMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionMilestone) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InteractionMilestoneCodePrefixRule: InteractionMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InteractionMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InteractionMilestoneCreatedAtRangeRule: InteractionMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionMilestone) -> [String] {
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

    final class InteractionMilestoneRequiredNameRule: InteractionMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionMilestone) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a interaction milestone.
    final class InteractionMilestoneValidator {
        var rules: [any InteractionMilestoneRule]

        init(rules: [any InteractionMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionMilestone) -> [String] {
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

        func requireValid(_ item: InteractionMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionMilestone]) -> [String: [String]] {
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

    static func defaultInteractionMilestoneValidator() -> InteractionMilestoneValidator {
        return InteractionMilestoneValidator(
            rules: [
                InteractionMilestoneDurationMinutesRangeRule(min: 16, max: 80),
                InteractionMilestoneCodePrefixRule(prefix: "X"),
                InteractionMilestoneCreatedAtRangeRule(min: 80, max: 86400),
                InteractionMilestoneRequiredNameRule(message: "interaction milestone needs a value"),
            ]
        )
    }
}
