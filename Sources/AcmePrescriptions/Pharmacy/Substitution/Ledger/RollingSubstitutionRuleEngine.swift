import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the rolling substitution rule calculation.
    protocol RollingSubstitutionRuleFactor {
        func describe() -> String
        func adjust(_ item: RollingSubstitutionRule, value: Double) -> Double
    }

    final class MinimumRollingSubstitutionRuleAdjuster: RollingSubstitutionRuleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingSubstitutionRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingRollingSubstitutionRuleAdjuster: RollingSubstitutionRuleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingSubstitutionRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RollingSubstitutionRuleGraceDaysOffsetAdjuster: RollingSubstitutionRuleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: RollingSubstitutionRule, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    /// Runs the rolling substitution rule steps in order and keeps a trace of each.
    final class RollingSubstitutionRuleEngine {
        var steps: [any RollingSubstitutionRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingSubstitutionRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingSubstitutionRule) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingSubstitutionRuleFactor = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [RollingSubstitutionRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingSubstitutionRuleEngine() -> RollingSubstitutionRuleEngine {
        return RollingSubstitutionRuleEngine(
            steps: [
                MinimumRollingSubstitutionRuleAdjuster(minimum: 31.0),
                RoundingRollingSubstitutionRuleAdjuster(step: 5.0),
                RollingSubstitutionRuleGraceDaysOffsetAdjuster(weight: 0.92),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 47449.7
        )
    }
}
