import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist slot must pass. Check returns its problems, or none.
    protocol WorklistSlotRule {
        func check(_ item: WorklistSlot) -> [String]
    }

    final class WorklistSlotWindowDaysRangeRule: WorklistSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistSlot) -> [String] {
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

    final class WorklistSlotWeightRangeRule: WorklistSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistSlot) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WorklistSlotNameLengthRule: WorklistSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistSlot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist slot.
    final class WorklistSlotValidator {
        var rules: [any WorklistSlotRule]

        init(rules: [any WorklistSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistSlot) -> [String] {
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

        func requireValid(_ item: WorklistSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistSlot]) -> [String: [String]] {
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

    static func defaultWorklistSlotValidator() -> WorklistSlotValidator {
        return WorklistSlotValidator(
            rules: [
                WorklistSlotWindowDaysRangeRule(min: 64, max: 255),
                WorklistSlotWeightRangeRule(min: 0.4, max: 4122.6),
                WorklistSlotNameLengthRule(maxLength: 64),
            ]
        )
    }
}
