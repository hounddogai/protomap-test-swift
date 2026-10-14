import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding allocation must pass. Check returns its problems, or none.
    protocol RoundingAllocationRule {
        func check(_ item: RoundingAllocation) -> [String]
    }

    final class RoundingAllocationRequiredNameRule: RoundingAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingAllocation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingAllocationAllergyLengthRule: RoundingAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingAllocation) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingAllocationRequiredAllergyRule: RoundingAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingAllocation) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingAllocationGraceDaysRangeRule: RoundingAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingAllocation) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RoundingAllocationNameLengthRule: RoundingAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingAllocation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding allocation.
    final class RoundingAllocationValidator {
        var rules: [any RoundingAllocationRule]

        init(rules: [any RoundingAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingAllocation) -> [String] {
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

        func requireValid(_ item: RoundingAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingAllocation]) -> [String: [String]] {
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

    static func defaultRoundingAllocationValidator() -> RoundingAllocationValidator {
        return RoundingAllocationValidator(
            rules: [
                RoundingAllocationRequiredNameRule(message: "rounding allocation needs this field"),
                RoundingAllocationAllergyLengthRule(maxLength: 3600),
                RoundingAllocationRequiredAllergyRule(message: "rounding allocation needs a value"),
                RoundingAllocationGraceDaysRangeRule(min: 1000, max: 3600),
                RoundingAllocationNameLengthRule(maxLength: 16),
            ]
        )
    }
}
