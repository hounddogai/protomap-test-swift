import AcmePlatform
import Foundation

extension Consent {
    /// A rule a seasonal consent form slot must pass. Check returns its problems, or none.
    protocol SeasonalConsentFormSlotRule {
        func check(_ item: SeasonalConsentFormSlot) -> [String]
    }

    final class SeasonalConsentFormSlotCodeLengthRule: SeasonalConsentFormSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalConsentFormSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalConsentFormSlotCurrencyLengthRule: SeasonalConsentFormSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalConsentFormSlot) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalConsentFormSlotVisibleGuardRule: SeasonalConsentFormSlotRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: SeasonalConsentFormSlot) -> [String] {
            if item.visible && (item.maximum > limit) {
                return ["maximum \(item.maximum) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class SeasonalConsentFormSlotMaximumRangeRule: SeasonalConsentFormSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalConsentFormSlot) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalConsentFormSlotRequiredCurrencyRule: SeasonalConsentFormSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalConsentFormSlot) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalConsentFormSlotContactEmailLengthRule: SeasonalConsentFormSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalConsentFormSlot) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal consent form slot.
    final class SeasonalConsentFormSlotValidator {
        var rules: [any SeasonalConsentFormSlotRule]

        init(rules: [any SeasonalConsentFormSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalConsentFormSlot) -> [String] {
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

        func requireValid(_ item: SeasonalConsentFormSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalConsentFormSlot]) -> [String: [String]] {
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

    static func defaultSeasonalConsentFormSlotValidator() -> SeasonalConsentFormSlotValidator {
        return SeasonalConsentFormSlotValidator(
            rules: [
                SeasonalConsentFormSlotCodeLengthRule(maxLength: 1000),
                SeasonalConsentFormSlotCurrencyLengthRule(maxLength: 120),
                SeasonalConsentFormSlotVisibleGuardRule(limit: 2.1),
                SeasonalConsentFormSlotMaximumRangeRule(min: 4.9, max: 3674.1),
                SeasonalConsentFormSlotRequiredCurrencyRule(message: "seasonal consent form slot needs this field"),
                SeasonalConsentFormSlotContactEmailLengthRule(maxLength: 255),
            ]
        )
    }
}
