import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a capped goal group must pass. Check returns its problems, or none.
    protocol CappedGoalGroupRule {
        func check(_ item: CappedGoalGroup) -> [String]
    }

    final class CappedGoalGroupQuantityRangeRule: CappedGoalGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedGoalGroup) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedGoalGroupRequiredCodeRule: CappedGoalGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedGoalGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedGoalGroupCodeLengthRule: CappedGoalGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedGoalGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedGoalGroupRequiredChannelRule: CappedGoalGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedGoalGroup) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedGoalGroupRequiredLabelRule: CappedGoalGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedGoalGroup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped goal group.
    final class CappedGoalGroupValidator {
        var rules: [any CappedGoalGroupRule]

        init(rules: [any CappedGoalGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedGoalGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedGoalGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedGoalGroup]) -> [String: [String]] {
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

    static func defaultCappedGoalGroupValidator() -> CappedGoalGroupValidator {
        return CappedGoalGroupValidator(
            rules: [
                CappedGoalGroupQuantityRangeRule(min: 255, max: 1000),
                CappedGoalGroupRequiredCodeRule(message: "capped goal group needs a value"),
                CappedGoalGroupCodeLengthRule(maxLength: 64),
                CappedGoalGroupRequiredChannelRule(message: "capped goal group needs this field"),
                CappedGoalGroupRequiredLabelRule(message: "capped goal group needs an entry"),
            ]
        )
    }
}
