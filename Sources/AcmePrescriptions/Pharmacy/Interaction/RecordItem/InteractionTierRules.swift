import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction tier must pass. Check returns its problems, or none.
    protocol InteractionTierRule {
        func check(_ item: InteractionTier) -> [String]
    }

    final class InteractionTierRefillsRangeRule: InteractionTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionTier) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InteractionTierMarginRangeRule: InteractionTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionTier) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InteractionTierAcuityRangeRule: InteractionTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionTier) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InteractionTierRequiredTimezoneRule: InteractionTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionTier) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionTierTimezoneLengthRule: InteractionTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionTier) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionTierRequiredNotesRule: InteractionTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionTier) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a interaction tier.
    final class InteractionTierValidator {
        var rules: [any InteractionTierRule]

        init(rules: [any InteractionTierRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionTier) -> [String] {
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

        func requireValid(_ item: InteractionTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionTier]) -> [String: [String]] {
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

    static func defaultInteractionTierValidator() -> InteractionTierValidator {
        return InteractionTierValidator(
            rules: [
                InteractionTierRefillsRangeRule(min: 64, max: 3600),
                InteractionTierMarginRangeRule(min: 7.8, max: 3425.9),
                InteractionTierAcuityRangeRule(min: 80, max: 1000),
                InteractionTierRequiredTimezoneRule(message: "interaction tier needs this field"),
                InteractionTierTimezoneLengthRule(maxLength: 120),
                InteractionTierRequiredNotesRule(message: "interaction tier needs this field"),
            ]
        )
    }
}
