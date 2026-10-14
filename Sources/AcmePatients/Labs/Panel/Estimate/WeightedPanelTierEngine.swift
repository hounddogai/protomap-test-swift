import AcmePlatform
import Foundation

extension Labs {
    /// One step of the weighted panel tier calculation.
    protocol WeightedPanelTierStep {
        func describe() -> String
        func adjust(_ item: WeightedPanelTier, value: Double) -> Double
    }

    final class RegionWeightedPanelTierAdjuster: WeightedPanelTierStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: WeightedPanelTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapWeightedPanelTierAdjuster: WeightedPanelTierStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedPanelTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumWeightedPanelTierAdjuster: WeightedPanelTierStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedPanelTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the weighted panel tier steps in order and keeps a trace of each.
    final class WeightedPanelTierEngine {
        var steps: [any WeightedPanelTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedPanelTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedPanelTier) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedPanelTierStep = steps[index]
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

        func evaluateAll(_ items: [WeightedPanelTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedPanelTierEngine() -> WeightedPanelTierEngine {
        return WeightedPanelTierEngine(
            steps: [
                RegionWeightedPanelTierAdjuster(factors: ["north": 1.2, "online": 1.06, "west": 1.15]),
                CapWeightedPanelTierAdjuster(cap: 49299.0),
                MinimumWeightedPanelTierAdjuster(minimum: 44.5),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 2107.1
        )
    }
}
