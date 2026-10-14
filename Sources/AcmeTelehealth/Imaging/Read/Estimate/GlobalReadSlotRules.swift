import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global read slot must pass. Check returns its problems, or none.
    protocol GlobalReadSlotRule {
        func check(_ item: GlobalReadSlot) -> [String]
    }

    final class GlobalReadSlotRequiredCodeRule: GlobalReadSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalReadSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalReadSlotNameLengthRule: GlobalReadSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalReadSlot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalReadSlotDiscountRangeRule: GlobalReadSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalReadSlot) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalReadSlotCeilingRangeRule: GlobalReadSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalReadSlot) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global read slot.
    final class GlobalReadSlotValidator {
        var rules: [any GlobalReadSlotRule]

        init(rules: [any GlobalReadSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalReadSlot) -> [String] {
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

        func requireValid(_ item: GlobalReadSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalReadSlot]) -> [String: [String]] {
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

    static func defaultGlobalReadSlotValidator() -> GlobalReadSlotValidator {
        return GlobalReadSlotValidator(
            rules: [
                GlobalReadSlotRequiredCodeRule(message: "global read slot needs an entry"),
                GlobalReadSlotNameLengthRule(maxLength: 120),
                GlobalReadSlotDiscountRangeRule(min: 3.4, max: 2558.7),
                GlobalReadSlotCeilingRangeRule(min: 3.7, max: 4154.9),
            ]
        )
    }
}
