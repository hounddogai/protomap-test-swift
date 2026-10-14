import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen slot must pass. Check returns its problems, or none.
    protocol SpecimenSlotRule {
        func check(_ item: SpecimenSlot) -> [String]
    }

    final class SpecimenSlotLimitRangeRule: SpecimenSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenSlot) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SpecimenSlotMaximumRangeRule: SpecimenSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenSlot) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SpecimenSlotLabelLengthRule: SpecimenSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenSlot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen slot.
    final class SpecimenSlotValidator {
        var rules: [any SpecimenSlotRule]

        init(rules: [any SpecimenSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SpecimenSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenSlot]) -> [String: [String]] {
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

    static func defaultSpecimenSlotValidator() -> SpecimenSlotValidator {
        return SpecimenSlotValidator(
            rules: [
                SpecimenSlotLimitRangeRule(min: 16, max: 80),
                SpecimenSlotMaximumRangeRule(min: 7.1, max: 2993.1),
                SpecimenSlotLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
