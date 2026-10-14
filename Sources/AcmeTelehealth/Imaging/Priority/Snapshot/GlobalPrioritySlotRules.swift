import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global priority slot must pass. Check returns its problems, or none.
    protocol GlobalPrioritySlotRule {
        func check(_ item: GlobalPrioritySlot) -> [String]
    }

    final class GlobalPrioritySlotCodeLengthRule: GlobalPrioritySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalPrioritySlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalPrioritySlotRequiredSummaryRule: GlobalPrioritySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalPrioritySlot) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalPrioritySlotPriorityRangeRule: GlobalPrioritySlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalPrioritySlot) -> [String] {
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

    final class GlobalPrioritySlotLabelLengthRule: GlobalPrioritySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalPrioritySlot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalPrioritySlotSummaryLengthRule: GlobalPrioritySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalPrioritySlot) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global priority slot.
    final class GlobalPrioritySlotValidator {
        var rules: [any GlobalPrioritySlotRule]

        init(rules: [any GlobalPrioritySlotRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalPrioritySlot) -> [String] {
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

        func requireValid(_ item: GlobalPrioritySlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalPrioritySlot]) -> [String: [String]] {
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

    static func defaultGlobalPrioritySlotValidator() -> GlobalPrioritySlotValidator {
        return GlobalPrioritySlotValidator(
            rules: [
                GlobalPrioritySlotCodeLengthRule(maxLength: 64),
                GlobalPrioritySlotRequiredSummaryRule(message: "global priority slot needs an entry"),
                GlobalPrioritySlotPriorityRangeRule(min: 64, max: 86400),
                GlobalPrioritySlotLabelLengthRule(maxLength: 32),
                GlobalPrioritySlotSummaryLengthRule(maxLength: 3600),
            ]
        )
    }
}
