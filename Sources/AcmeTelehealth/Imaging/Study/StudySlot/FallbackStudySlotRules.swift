import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback study slot must pass. Check returns its problems, or none.
    protocol FallbackStudySlotRule {
        func check(_ item: FallbackStudySlot) -> [String]
    }

    final class FallbackStudySlotActiveGuardRule: FallbackStudySlotRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: FallbackStudySlot) -> [String] {
            if item.active && (item.budget > limit) {
                return ["budget \(item.budget) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class FallbackStudySlotAllowedTitleRule: FallbackStudySlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackStudySlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is blocked"]
            }
            return []
        }
    }

    final class FallbackStudySlotCostRangeRule: FallbackStudySlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackStudySlot) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackStudySlotRequiredCountryRule: FallbackStudySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackStudySlot) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackStudySlotCodeLengthRule: FallbackStudySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackStudySlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackStudySlotCurrencyLengthRule: FallbackStudySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackStudySlot) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback study slot.
    final class FallbackStudySlotValidator {
        var rules: [any FallbackStudySlotRule]

        init(rules: [any FallbackStudySlotRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackStudySlot) -> [String] {
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

        func requireValid(_ item: FallbackStudySlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackStudySlot]) -> [String: [String]] {
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

    static func defaultFallbackStudySlotValidator() -> FallbackStudySlotValidator {
        return FallbackStudySlotValidator(
            rules: [
                FallbackStudySlotActiveGuardRule(limit: 0.6),
                FallbackStudySlotAllowedTitleRule(allowed: ["rolling", "manual"]),
                FallbackStudySlotCostRangeRule(min: 5.0, max: 1247.4),
                FallbackStudySlotRequiredCountryRule(message: "fallback study slot needs this field"),
                FallbackStudySlotCodeLengthRule(maxLength: 16),
                FallbackStudySlotCurrencyLengthRule(maxLength: 255),
            ]
        )
    }
}
