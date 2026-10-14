import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan slot must pass. Check returns its problems, or none.
    protocol DischargePlanSlotRule {
        func check(_ item: DischargePlanSlot) -> [String]
    }

    final class DischargePlanSlotAllowedCurrencyRule: DischargePlanSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DischargePlanSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is blocked"]
            }
            return []
        }
    }

    final class DischargePlanSlotCeilingRangeRule: DischargePlanSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanSlot) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DischargePlanSlotRequiredCodeRule: DischargePlanSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanSlotRequiredCurrencyRule: DischargePlanSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanSlot) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanSlotChecksumLengthRule: DischargePlanSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanSlot) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan slot.
    final class DischargePlanSlotValidator {
        var rules: [any DischargePlanSlotRule]

        init(rules: [any DischargePlanSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanSlot) -> [String] {
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

        func requireValid(_ item: DischargePlanSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanSlot]) -> [String: [String]] {
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

    static func defaultDischargePlanSlotValidator() -> DischargePlanSlotValidator {
        return DischargePlanSlotValidator(
            rules: [
                DischargePlanSlotAllowedCurrencyRule(allowed: ["strict"]),
                DischargePlanSlotCeilingRangeRule(min: 1.0, max: 3232.1),
                DischargePlanSlotRequiredCodeRule(message: "discharge plan slot needs a value"),
                DischargePlanSlotRequiredCurrencyRule(message: "discharge plan slot needs this field"),
                DischargePlanSlotChecksumLengthRule(maxLength: 86400),
            ]
        )
    }
}
