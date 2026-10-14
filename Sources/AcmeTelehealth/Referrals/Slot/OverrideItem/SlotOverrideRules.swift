import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot override must pass. Check returns its problems, or none.
    protocol SlotOverrideRule {
        func check(_ item: SlotOverride) -> [String]
    }

    final class SlotOverrideRequiredTitleRule: SlotOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotOverride) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotOverrideRequiredCodeRule: SlotOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotOverrideCopayRangeRule: SlotOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotOverride) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot override.
    final class SlotOverrideValidator {
        var rules: [any SlotOverrideRule]

        init(rules: [any SlotOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotOverride]) -> [String: [String]] {
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

    static func defaultSlotOverrideValidator() -> SlotOverrideValidator {
        return SlotOverrideValidator(
            rules: [
                SlotOverrideRequiredTitleRule(message: "slot override needs this field"),
                SlotOverrideRequiredCodeRule(message: "slot override needs a value"),
                SlotOverrideCopayRangeRule(min: 8.4, max: 567.0),
            ]
        )
    }
}
