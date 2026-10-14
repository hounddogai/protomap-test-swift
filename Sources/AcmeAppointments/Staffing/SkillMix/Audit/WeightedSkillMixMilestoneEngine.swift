import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the weighted skill mix milestone calculation.
    protocol WeightedSkillMixMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedSkillMixMilestone, value: Double) -> Double
    }

    final class NameWeightedSkillMixMilestoneAdjuster: WeightedSkillMixMilestoneAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WeightedSkillMixMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumWeightedSkillMixMilestoneAdjuster: WeightedSkillMixMilestoneAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedSkillMixMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingWeightedSkillMixMilestoneAdjuster: WeightedSkillMixMilestoneAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedSkillMixMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapWeightedSkillMixMilestoneAdjuster: WeightedSkillMixMilestoneAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedSkillMixMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredWeightedSkillMixMilestoneAdjuster: WeightedSkillMixMilestoneAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedSkillMixMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the weighted skill mix milestone steps in order and keeps a trace of each.
    final class WeightedSkillMixMilestoneEngine {
        var steps: [any WeightedSkillMixMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedSkillMixMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedSkillMixMilestone) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedSkillMixMilestoneAdjuster = steps[index]
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

        func evaluateAll(_ items: [WeightedSkillMixMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedSkillMixMilestoneEngine() -> WeightedSkillMixMilestoneEngine {
        return WeightedSkillMixMilestoneEngine(
            steps: [
                NameWeightedSkillMixMilestoneAdjuster(factors: ["west": 1.17, "east": 0.86]),
                MinimumWeightedSkillMixMilestoneAdjuster(minimum: 45.5),
                RoundingWeightedSkillMixMilestoneAdjuster(step: 0.1),
                CapWeightedSkillMixMilestoneAdjuster(cap: 43268.0),
                TieredWeightedSkillMixMilestoneAdjuster(bounds: [135.0, 6732.0], rates: [1.13, 0.84]),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 65014.7
        )
    }
}
