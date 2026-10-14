import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix plan calculation.
    protocol SkillMixPlanModifier {
        func describe() -> String
        func adjust(_ item: SkillMixPlan, value: Double) -> Double
    }

    final class TieredSkillMixPlanAdjuster: SkillMixPlanModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SkillMixPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentSkillMixPlanAdjuster: SkillMixPlanModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SkillMixPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSkillMixPlanAdjuster: SkillMixPlanModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SkillMixPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSkillMixPlanAdjuster: SkillMixPlanModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SkillMixPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the skill mix plan steps in order and keeps a trace of each.
    final class SkillMixPlanEngine {
        var steps: [any SkillMixPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SkillMixPlan) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SkillMixPlanModifier = steps[index]
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

        func evaluateAll(_ items: [SkillMixPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSkillMixPlanEngine() -> SkillMixPlanEngine {
        return SkillMixPlanEngine(
            steps: [
                TieredSkillMixPlanAdjuster(bounds: [2411.0, 3456.0, 7001.0], rates: [0.87, 1.05, 0.97]),
                PercentSkillMixPlanAdjuster(percent: -23.3),
                CapSkillMixPlanAdjuster(cap: 13068.0),
                RoundingSkillMixPlanAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 41222.5
        )
    }
}
