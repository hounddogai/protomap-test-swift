import AcmePlatform
import Foundation

extension Labs {
    /// A rule a weighted specimen cycle must pass. Check returns its problems, or none.
    protocol WeightedSpecimenCycleRule {
        func check(_ item: WeightedSpecimenCycle) -> [String]
    }

    final class WeightedSpecimenCycleWardLengthRule: WeightedSpecimenCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedSpecimenCycle) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedSpecimenCycleThresholdRangeRule: WeightedSpecimenCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedSpecimenCycle) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedSpecimenCycleRequiredCodeRule: WeightedSpecimenCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSpecimenCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedSpecimenCycleAllowedNameRule: WeightedSpecimenCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedSpecimenCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is missing"]
            }
            return []
        }
    }

    final class WeightedSpecimenCycleRateRangeRule: WeightedSpecimenCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedSpecimenCycle) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted specimen cycle.
    final class WeightedSpecimenCycleValidator {
        var rules: [any WeightedSpecimenCycleRule]

        init(rules: [any WeightedSpecimenCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedSpecimenCycle) -> [String] {
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

        func requireValid(_ item: WeightedSpecimenCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedSpecimenCycle]) -> [String: [String]] {
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

    static func defaultWeightedSpecimenCycleValidator() -> WeightedSpecimenCycleValidator {
        return WeightedSpecimenCycleValidator(
            rules: [
                WeightedSpecimenCycleWardLengthRule(maxLength: 80),
                WeightedSpecimenCycleThresholdRangeRule(min: 1.0, max: 3809.2),
                WeightedSpecimenCycleRequiredCodeRule(message: "weighted specimen cycle needs this field"),
                WeightedSpecimenCycleAllowedNameRule(allowed: ["adaptive", "adaptive"]),
                WeightedSpecimenCycleRateRangeRule(min: 9.8, max: 288.8),
            ]
        )
    }
}
