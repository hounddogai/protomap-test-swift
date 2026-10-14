import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a regional charge slot must pass. Check returns its problems, or none.
    protocol RegionalChargeSlotRule {
        func check(_ item: RegionalChargeSlot) -> [String]
    }

    final class RegionalChargeSlotCodeLengthRule: RegionalChargeSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalChargeSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalChargeSlotExpiresAtRangeRule: RegionalChargeSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalChargeSlot) -> [String] {
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

    final class RegionalChargeSlotRequiredLocaleRule: RegionalChargeSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalChargeSlot) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalChargeSlotCeilingRangeRule: RegionalChargeSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalChargeSlot) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalChargeSlotRequiredCodeRule: RegionalChargeSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalChargeSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalChargeSlotRequiredLabelRule: RegionalChargeSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalChargeSlot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional charge slot.
    final class RegionalChargeSlotValidator {
        var rules: [any RegionalChargeSlotRule]

        init(rules: [any RegionalChargeSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalChargeSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalChargeSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalChargeSlot]) -> [String: [String]] {
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

    static func defaultRegionalChargeSlotValidator() -> RegionalChargeSlotValidator {
        return RegionalChargeSlotValidator(
            rules: [
                RegionalChargeSlotCodeLengthRule(maxLength: 1000),
                RegionalChargeSlotExpiresAtRangeRule(min: 32, max: 255),
                RegionalChargeSlotRequiredLocaleRule(message: "regional charge slot needs this field"),
                RegionalChargeSlotCeilingRangeRule(min: 2.1, max: 2702.8),
                RegionalChargeSlotRequiredCodeRule(message: "regional charge slot needs this field"),
                RegionalChargeSlotRequiredLabelRule(message: "regional charge slot needs an entry"),
            ]
        )
    }
}
