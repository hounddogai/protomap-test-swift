import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted eligibility slot must pass. Check returns its problems, or none.
    protocol WeightedEligibilitySlotRule {
        func check(_ item: WeightedEligibilitySlot) -> [String]
    }

    final class WeightedEligibilitySlotRequiredLabelRule: WeightedEligibilitySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedEligibilitySlot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedEligibilitySlotCodeLengthRule: WeightedEligibilitySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedEligibilitySlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedEligibilitySlotRequiredCodeRule: WeightedEligibilitySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedEligibilitySlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted eligibility slot.
    final class WeightedEligibilitySlotValidator {
        var rules: [any WeightedEligibilitySlotRule]

        init(rules: [any WeightedEligibilitySlotRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedEligibilitySlot) -> [String] {
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

        func requireValid(_ item: WeightedEligibilitySlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedEligibilitySlot]) -> [String: [String]] {
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

    static func defaultWeightedEligibilitySlotValidator() -> WeightedEligibilitySlotValidator {
        return WeightedEligibilitySlotValidator(
            rules: [
                WeightedEligibilitySlotRequiredLabelRule(message: "weighted eligibility slot needs an entry"),
                WeightedEligibilitySlotCodeLengthRule(maxLength: 16),
                WeightedEligibilitySlotRequiredCodeRule(message: "weighted eligibility slot needs this field"),
            ]
        )
    }
}
