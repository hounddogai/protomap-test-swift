import AcmePlatform
import Foundation

extension Labs {
    /// A rule a weighted specimen slot must pass. Check returns its problems, or none.
    protocol WeightedSpecimenSlotRule {
        func check(_ item: WeightedSpecimenSlot) -> [String]
    }

    final class WeightedSpecimenSlotRequiredNameRule: WeightedSpecimenSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSpecimenSlot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedSpecimenSlotMinimumRangeRule: WeightedSpecimenSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedSpecimenSlot) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedSpecimenSlotRequiredCodeRule: WeightedSpecimenSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSpecimenSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted specimen slot.
    final class WeightedSpecimenSlotValidator {
        var rules: [any WeightedSpecimenSlotRule]

        init(rules: [any WeightedSpecimenSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedSpecimenSlot) -> [String] {
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

        func requireValid(_ item: WeightedSpecimenSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedSpecimenSlot]) -> [String: [String]] {
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

    static func defaultWeightedSpecimenSlotValidator() -> WeightedSpecimenSlotValidator {
        return WeightedSpecimenSlotValidator(
            rules: [
                WeightedSpecimenSlotRequiredNameRule(message: "weighted specimen slot needs this field"),
                WeightedSpecimenSlotMinimumRangeRule(min: 7.3, max: 734.5),
                WeightedSpecimenSlotRequiredCodeRule(message: "weighted specimen slot needs this field"),
            ]
        )
    }
}
