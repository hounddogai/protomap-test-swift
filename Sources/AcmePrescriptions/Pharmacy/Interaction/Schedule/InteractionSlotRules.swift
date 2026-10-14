import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction slot must pass. Check returns its problems, or none.
    protocol InteractionSlotRule {
        func check(_ item: InteractionSlot) -> [String]
    }

    final class InteractionSlotRequiredEncounterIDRule: InteractionSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionSlot) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionSlotRequiredCodeRule: InteractionSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionSlotDiscountRangeRule: InteractionSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionSlot) -> [String] {
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

    final class InteractionSlotCodeLengthRule: InteractionSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionSlotEncounterIDLengthRule: InteractionSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionSlot) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction slot.
    final class InteractionSlotValidator {
        var rules: [any InteractionSlotRule]

        init(rules: [any InteractionSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionSlot) -> [String] {
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

        func requireValid(_ item: InteractionSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionSlot]) -> [String: [String]] {
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

    static func defaultInteractionSlotValidator() -> InteractionSlotValidator {
        return InteractionSlotValidator(
            rules: [
                InteractionSlotRequiredEncounterIDRule(message: "interaction slot needs an entry"),
                InteractionSlotRequiredCodeRule(message: "interaction slot needs a value"),
                InteractionSlotDiscountRangeRule(min: 7.7, max: 1685.3),
                InteractionSlotCodeLengthRule(maxLength: 64),
                InteractionSlotEncounterIDLengthRule(maxLength: 1000),
            ]
        )
    }
}
