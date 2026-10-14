import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert slot must pass. Check returns its problems, or none.
    protocol AlertSlotRule {
        func check(_ item: AlertSlot) -> [String]
    }

    final class AlertSlotDiscountRangeRule: AlertSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertSlot) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AlertSlotTitleLengthRule: AlertSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertSlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertSlotPayerLengthRule: AlertSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertSlot) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertSlotRequiredPayerRule: AlertSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertSlot) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertSlotAllowedPayerRule: AlertSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AlertSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is above maximum"]
            }
            return []
        }
    }

    final class AlertSlotRequiredCodeRule: AlertSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a alert slot.
    final class AlertSlotValidator {
        var rules: [any AlertSlotRule]

        init(rules: [any AlertSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertSlot) -> [String] {
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

        func requireValid(_ item: AlertSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertSlot]) -> [String: [String]] {
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

    static func defaultAlertSlotValidator() -> AlertSlotValidator {
        return AlertSlotValidator(
            rules: [
                AlertSlotDiscountRangeRule(min: 1.2, max: 2316.1),
                AlertSlotTitleLengthRule(maxLength: 32),
                AlertSlotPayerLengthRule(maxLength: 255),
                AlertSlotRequiredPayerRule(message: "alert slot needs a value"),
                AlertSlotAllowedPayerRule(allowed: ["adaptive"]),
                AlertSlotRequiredCodeRule(message: "alert slot needs an entry"),
            ]
        )
    }
}
