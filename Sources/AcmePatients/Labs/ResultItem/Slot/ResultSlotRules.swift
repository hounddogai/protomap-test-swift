import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result slot must pass. Check returns its problems, or none.
    protocol ResultSlotRule {
        func check(_ item: ResultSlot) -> [String]
    }

    final class ResultSlotRequiredDescriptionRule: ResultSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultSlot) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultSlotRequiredCodeRule: ResultSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultSlotRequiredLabelRule: ResultSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultSlot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultSlotCapacityRangeRule: ResultSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultSlot) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a result slot.
    final class ResultSlotValidator {
        var rules: [any ResultSlotRule]

        init(rules: [any ResultSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultSlot) -> [String] {
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

        func requireValid(_ item: ResultSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultSlot]) -> [String: [String]] {
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

    static func defaultResultSlotValidator() -> ResultSlotValidator {
        return ResultSlotValidator(
            rules: [
                ResultSlotRequiredDescriptionRule(message: "result slot needs an entry"),
                ResultSlotRequiredCodeRule(message: "result slot needs this field"),
                ResultSlotRequiredLabelRule(message: "result slot needs this field"),
                ResultSlotCapacityRangeRule(min: 80, max: 3600),
            ]
        )
    }
}
