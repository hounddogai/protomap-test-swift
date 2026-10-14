import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a scheduled inventory slot must pass. Check returns its problems, or none.
    protocol ScheduledInventorySlotRule {
        func check(_ item: ScheduledInventorySlot) -> [String]
    }

    final class ScheduledInventorySlotAcuityRangeRule: ScheduledInventorySlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledInventorySlot) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledInventorySlotExpiresAtRangeRule: ScheduledInventorySlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledInventorySlot) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledInventorySlotRequiredCodeRule: ScheduledInventorySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledInventorySlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledInventorySlotCodeLengthRule: ScheduledInventorySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledInventorySlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledInventorySlotMinimumRangeRule: ScheduledInventorySlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledInventorySlot) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a scheduled inventory slot.
    final class ScheduledInventorySlotValidator {
        var rules: [any ScheduledInventorySlotRule]

        init(rules: [any ScheduledInventorySlotRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledInventorySlot) -> [String] {
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

        func requireValid(_ item: ScheduledInventorySlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledInventorySlot]) -> [String: [String]] {
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

    static func defaultScheduledInventorySlotValidator() -> ScheduledInventorySlotValidator {
        return ScheduledInventorySlotValidator(
            rules: [
                ScheduledInventorySlotAcuityRangeRule(min: 16, max: 86400),
                ScheduledInventorySlotExpiresAtRangeRule(min: 80, max: 120),
                ScheduledInventorySlotRequiredCodeRule(message: "scheduled inventory slot needs this field"),
                ScheduledInventorySlotCodeLengthRule(maxLength: 16),
                ScheduledInventorySlotMinimumRangeRule(min: 5.6, max: 946.3),
            ]
        )
    }
}
