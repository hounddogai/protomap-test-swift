import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan item must pass. Check returns its problems, or none.
    protocol DischargePlanItemRule {
        func check(_ item: DischargePlanItem) -> [String]
    }

    final class DischargePlanItemRequiredCodeRule: DischargePlanItemRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanItem) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanItemAttemptsRangeRule: DischargePlanItemRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanItem) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DischargePlanItemPriorityRangeRule: DischargePlanItemRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanItem) -> [String] {
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

    final class DischargePlanItemNotesLengthRule: DischargePlanItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanItem) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanItemRequiredNotesRule: DischargePlanItemRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanItem) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanItemStartsAtRangeRule: DischargePlanItemRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanItem) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan item.
    final class DischargePlanItemValidator {
        var rules: [any DischargePlanItemRule]

        init(rules: [any DischargePlanItemRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanItem) -> [String] {
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

        func requireValid(_ item: DischargePlanItem) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanItem]) -> [String: [String]] {
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

    static func defaultDischargePlanItemValidator() -> DischargePlanItemValidator {
        return DischargePlanItemValidator(
            rules: [
                DischargePlanItemRequiredCodeRule(message: "discharge plan item needs this field"),
                DischargePlanItemAttemptsRangeRule(min: 3600, max: 86400),
                DischargePlanItemPriorityRangeRule(min: 1000, max: 86400),
                DischargePlanItemNotesLengthRule(maxLength: 120),
                DischargePlanItemRequiredNotesRule(message: "discharge plan item needs a value"),
                DischargePlanItemStartsAtRangeRule(min: 32, max: 32),
            ]
        )
    }
}
