import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness slot must pass. Check returns its problems, or none.
    protocol WitnessSlotRule {
        func check(_ item: WitnessSlot) -> [String]
    }

    final class WitnessSlotRequiredTitleRule: WitnessSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessSlot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessSlotRefillsRangeRule: WitnessSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessSlot) -> [String] {
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

    final class WitnessSlotCodePrefixRule: WitnessSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WitnessSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WitnessSlotRequiredFacilityRule: WitnessSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessSlot) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a witness slot.
    final class WitnessSlotValidator {
        var rules: [any WitnessSlotRule]

        init(rules: [any WitnessSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessSlot]) -> [String: [String]] {
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

    static func defaultWitnessSlotValidator() -> WitnessSlotValidator {
        return WitnessSlotValidator(
            rules: [
                WitnessSlotRequiredTitleRule(message: "witness slot needs this field"),
                WitnessSlotRefillsRangeRule(min: 16, max: 120),
                WitnessSlotCodePrefixRule(prefix: "OPS"),
                WitnessSlotRequiredFacilityRule(message: "witness slot needs a value"),
            ]
        )
    }
}
