import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual claim milestone must pass. Check returns its problems, or none.
    protocol ManualClaimMilestoneRule {
        func check(_ item: ManualClaimMilestone) -> [String]
    }

    final class ManualClaimMilestoneRequiredCodeRule: ManualClaimMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualClaimMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualClaimMilestoneNameLengthRule: ManualClaimMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualClaimMilestone) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualClaimMilestoneActiveGuardRule: ManualClaimMilestoneRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ManualClaimMilestone) -> [String] {
            if item.active && (item.windowDays > limit) {
                return ["window days \(item.windowDays) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class ManualClaimMilestoneWindowDaysRangeRule: ManualClaimMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualClaimMilestone) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualClaimMilestoneCodeLengthRule: ManualClaimMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualClaimMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual claim milestone.
    final class ManualClaimMilestoneValidator {
        var rules: [any ManualClaimMilestoneRule]

        init(rules: [any ManualClaimMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualClaimMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualClaimMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualClaimMilestone]) -> [String: [String]] {
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

    static func defaultManualClaimMilestoneValidator() -> ManualClaimMilestoneValidator {
        return ManualClaimMilestoneValidator(
            rules: [
                ManualClaimMilestoneRequiredCodeRule(message: "manual claim milestone needs this field"),
                ManualClaimMilestoneNameLengthRule(maxLength: 255),
                ManualClaimMilestoneActiveGuardRule(limit: 32),
                ManualClaimMilestoneWindowDaysRangeRule(min: 120, max: 86400),
                ManualClaimMilestoneCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
