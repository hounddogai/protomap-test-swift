import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a weighted goal entry must pass. Check returns its problems, or none.
    protocol WeightedGoalEntryRule {
        func check(_ item: WeightedGoalEntry) -> [String]
    }

    final class WeightedGoalEntryRetriesRangeRule: WeightedGoalEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedGoalEntry) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedGoalEntryWardLengthRule: WeightedGoalEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedGoalEntry) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedGoalEntryRequiredOwnerIDRule: WeightedGoalEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedGoalEntry) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedGoalEntryOwnerIDLengthRule: WeightedGoalEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedGoalEntry) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedGoalEntryLimitRangeRule: WeightedGoalEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedGoalEntry) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedGoalEntryNameLengthRule: WeightedGoalEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedGoalEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted goal entry.
    final class WeightedGoalEntryValidator {
        var rules: [any WeightedGoalEntryRule]

        init(rules: [any WeightedGoalEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedGoalEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedGoalEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedGoalEntry]) -> [String: [String]] {
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

    static func defaultWeightedGoalEntryValidator() -> WeightedGoalEntryValidator {
        return WeightedGoalEntryValidator(
            rules: [
                WeightedGoalEntryRetriesRangeRule(min: 120, max: 1000),
                WeightedGoalEntryWardLengthRule(maxLength: 16),
                WeightedGoalEntryRequiredOwnerIDRule(message: "weighted goal entry needs this field"),
                WeightedGoalEntryOwnerIDLengthRule(maxLength: 86400),
                WeightedGoalEntryLimitRangeRule(min: 32, max: 64),
                WeightedGoalEntryNameLengthRule(maxLength: 3600),
            ]
        )
    }
}
