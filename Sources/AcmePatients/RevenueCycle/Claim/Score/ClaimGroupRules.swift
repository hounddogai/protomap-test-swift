import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim group must pass. Check returns its problems, or none.
    protocol ClaimGroupRule {
        func check(_ item: ClaimGroup) -> [String]
    }

    final class ClaimGroupCodeLengthRule: ClaimGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimGroupNameLengthRule: ClaimGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimGroup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimGroupDurationMinutesRangeRule: ClaimGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimGroup) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClaimGroupRequiredCodeRule: ClaimGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimGroupPriorityRangeRule: ClaimGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimGroup) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a claim group.
    final class ClaimGroupValidator {
        var rules: [any ClaimGroupRule]

        init(rules: [any ClaimGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClaimGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimGroup]) -> [String: [String]] {
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

    static func defaultClaimGroupValidator() -> ClaimGroupValidator {
        return ClaimGroupValidator(
            rules: [
                ClaimGroupCodeLengthRule(maxLength: 32),
                ClaimGroupNameLengthRule(maxLength: 1000),
                ClaimGroupDurationMinutesRangeRule(min: 1000, max: 1000),
                ClaimGroupRequiredCodeRule(message: "claim group needs a value"),
                ClaimGroupPriorityRangeRule(min: 64, max: 3600),
            ]
        )
    }
}
