import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled witness milestone must pass. Check returns its problems, or none.
    protocol ScheduledWitnessMilestoneRule {
        func check(_ item: ScheduledWitnessMilestone) -> [String]
    }

    final class ScheduledWitnessMilestoneCodeLengthRule: ScheduledWitnessMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledWitnessMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledWitnessMilestoneSpecialtyLengthRule: ScheduledWitnessMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledWitnessMilestone) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledWitnessMilestoneRequiredUnitRule: ScheduledWitnessMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledWitnessMilestone) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledWitnessMilestoneUnitLengthRule: ScheduledWitnessMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledWitnessMilestone) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledWitnessMilestoneVersionRangeRule: ScheduledWitnessMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledWitnessMilestone) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled witness milestone.
    final class ScheduledWitnessMilestoneValidator {
        var rules: [any ScheduledWitnessMilestoneRule]

        init(rules: [any ScheduledWitnessMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledWitnessMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledWitnessMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledWitnessMilestone]) -> [String: [String]] {
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

    static func defaultScheduledWitnessMilestoneValidator() -> ScheduledWitnessMilestoneValidator {
        return ScheduledWitnessMilestoneValidator(
            rules: [
                ScheduledWitnessMilestoneCodeLengthRule(maxLength: 16),
                ScheduledWitnessMilestoneSpecialtyLengthRule(maxLength: 120),
                ScheduledWitnessMilestoneRequiredUnitRule(message: "scheduled witness milestone needs an entry"),
                ScheduledWitnessMilestoneUnitLengthRule(maxLength: 255),
                ScheduledWitnessMilestoneVersionRangeRule(min: 32, max: 64),
            ]
        )
    }
}
