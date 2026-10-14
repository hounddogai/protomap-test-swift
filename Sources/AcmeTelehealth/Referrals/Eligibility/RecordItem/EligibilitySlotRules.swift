import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility slot must pass. Check returns its problems, or none.
    protocol EligibilitySlotRule {
        func check(_ item: EligibilitySlot) -> [String]
    }

    final class EligibilitySlotRequiredNameRule: EligibilitySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilitySlot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilitySlotRequiredCodeRule: EligibilitySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilitySlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilitySlotEndsAtRangeRule: EligibilitySlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilitySlot) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a eligibility slot.
    final class EligibilitySlotValidator {
        var rules: [any EligibilitySlotRule]

        init(rules: [any EligibilitySlotRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilitySlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: EligibilitySlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilitySlot]) -> [String: [String]] {
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

    static func defaultEligibilitySlotValidator() -> EligibilitySlotValidator {
        return EligibilitySlotValidator(
            rules: [
                EligibilitySlotRequiredNameRule(message: "eligibility slot needs a value"),
                EligibilitySlotRequiredCodeRule(message: "eligibility slot needs this field"),
                EligibilitySlotEndsAtRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
