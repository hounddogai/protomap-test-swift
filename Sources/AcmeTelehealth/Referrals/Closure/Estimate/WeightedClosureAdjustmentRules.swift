import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted closure adjustment must pass. Check returns its problems, or none.
    protocol WeightedClosureAdjustmentRule {
        func check(_ item: WeightedClosureAdjustment) -> [String]
    }

    final class WeightedClosureAdjustmentNameLengthRule: WeightedClosureAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedClosureAdjustment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedClosureAdjustmentFloorValueRangeRule: WeightedClosureAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedClosureAdjustment) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedClosureAdjustmentRequiredNameRule: WeightedClosureAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedClosureAdjustment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted closure adjustment.
    final class WeightedClosureAdjustmentValidator {
        var rules: [any WeightedClosureAdjustmentRule]

        init(rules: [any WeightedClosureAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedClosureAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedClosureAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedClosureAdjustment]) -> [String: [String]] {
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

    static func defaultWeightedClosureAdjustmentValidator() -> WeightedClosureAdjustmentValidator {
        return WeightedClosureAdjustmentValidator(
            rules: [
                WeightedClosureAdjustmentNameLengthRule(maxLength: 120),
                WeightedClosureAdjustmentFloorValueRangeRule(min: 8.4, max: 4827.6),
                WeightedClosureAdjustmentRequiredNameRule(message: "weighted closure adjustment needs an entry"),
            ]
        )
    }
}
