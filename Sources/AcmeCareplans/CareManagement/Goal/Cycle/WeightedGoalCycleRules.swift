import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a weighted goal cycle must pass. Check returns its problems, or none.
    protocol WeightedGoalCycleRule {
        func check(_ item: WeightedGoalCycle) -> [String]
    }

    final class WeightedGoalCycleRequiredFacilityRule: WeightedGoalCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedGoalCycle) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedGoalCycleFloorValueRangeRule: WeightedGoalCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedGoalCycle) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedGoalCycleAllergyLengthRule: WeightedGoalCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedGoalCycle) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedGoalCycleCodePrefixRule: WeightedGoalCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedGoalCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedGoalCycleTitleLengthRule: WeightedGoalCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedGoalCycle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedGoalCycleExpiresAtRangeRule: WeightedGoalCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedGoalCycle) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted goal cycle.
    final class WeightedGoalCycleValidator {
        var rules: [any WeightedGoalCycleRule]

        init(rules: [any WeightedGoalCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedGoalCycle) -> [String] {
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

        func requireValid(_ item: WeightedGoalCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedGoalCycle]) -> [String: [String]] {
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

    static func defaultWeightedGoalCycleValidator() -> WeightedGoalCycleValidator {
        return WeightedGoalCycleValidator(
            rules: [
                WeightedGoalCycleRequiredFacilityRule(message: "weighted goal cycle needs this field"),
                WeightedGoalCycleFloorValueRangeRule(min: 1.2, max: 3668.3),
                WeightedGoalCycleAllergyLengthRule(maxLength: 86400),
                WeightedGoalCycleCodePrefixRule(prefix: "ACM"),
                WeightedGoalCycleTitleLengthRule(maxLength: 16),
                WeightedGoalCycleExpiresAtRangeRule(min: 80, max: 80),
            ]
        )
    }
}
