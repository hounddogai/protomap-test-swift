import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense slot must pass. Check returns its problems, or none.
    protocol DispenseSlotRule {
        func check(_ item: DispenseSlot) -> [String]
    }

    final class DispenseSlotRequiredCodeRule: DispenseSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseSlotCeilingRangeRule: DispenseSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseSlot) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DispenseSlotRequiredNameRule: DispenseSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseSlot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a dispense slot.
    final class DispenseSlotValidator {
        var rules: [any DispenseSlotRule]

        init(rules: [any DispenseSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseSlot]) -> [String: [String]] {
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

    static func defaultDispenseSlotValidator() -> DispenseSlotValidator {
        return DispenseSlotValidator(
            rules: [
                DispenseSlotRequiredCodeRule(message: "dispense slot needs an entry"),
                DispenseSlotCeilingRangeRule(min: 1.9, max: 187.0),
                DispenseSlotRequiredNameRule(message: "dispense slot needs a value"),
            ]
        )
    }
}
