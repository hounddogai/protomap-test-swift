import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted follow up slot must pass. Check returns its problems, or none.
    protocol WeightedFollowUpSlotRule {
        func check(_ item: WeightedFollowUpSlot) -> [String]
    }

    final class WeightedFollowUpSlotCodePrefixRule: WeightedFollowUpSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedFollowUpSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedFollowUpSlotAllowedCodeRule: WeightedFollowUpSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedFollowUpSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class WeightedFollowUpSlotLabelLengthRule: WeightedFollowUpSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedFollowUpSlot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedFollowUpSlotDiscountRangeRule: WeightedFollowUpSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedFollowUpSlot) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedFollowUpSlotRequiredCodeRule: WeightedFollowUpSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFollowUpSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedFollowUpSlotCopayRangeRule: WeightedFollowUpSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedFollowUpSlot) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a weighted follow up slot.
    final class WeightedFollowUpSlotValidator {
        var rules: [any WeightedFollowUpSlotRule]

        init(rules: [any WeightedFollowUpSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedFollowUpSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedFollowUpSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedFollowUpSlot]) -> [String: [String]] {
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

    static func defaultWeightedFollowUpSlotValidator() -> WeightedFollowUpSlotValidator {
        return WeightedFollowUpSlotValidator(
            rules: [
                WeightedFollowUpSlotCodePrefixRule(prefix: "X"),
                WeightedFollowUpSlotAllowedCodeRule(allowed: ["manual", "primary"]),
                WeightedFollowUpSlotLabelLengthRule(maxLength: 64),
                WeightedFollowUpSlotDiscountRangeRule(min: 4.3, max: 2797.1),
                WeightedFollowUpSlotRequiredCodeRule(message: "weighted follow up slot needs an entry"),
                WeightedFollowUpSlotCopayRangeRule(min: 6.8, max: 130.1),
            ]
        )
    }
}
